import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/document_category.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../domain/vault_exception.dart';
import '../datasources/vault_remote_datasource.dart';
import '../models/vault_document_model.dart';
import '../services/vault_storage_service.dart';

/// The single place that touches [supabase.PostgrestException] and
/// [supabase.StorageException] and resolves "who is the current user" —
/// every other layer only ever sees [VaultException] with an
/// already-friendly message, and repository callers never pass a UID (see
/// the domain interface's doc comment for why).
///
/// Two Supabase products, deliberately: document metadata lives in
/// PostgreSQL ([_remoteDataSource]), the underlying files live in Storage
/// ([_storageService]) -- both raise their own exception type on failure.
/// [_run] and [_watchAndMap] below both have to translate errors from
/// either one.
class VaultRepositoryImpl implements VaultRepository {
  const VaultRepositoryImpl(this._remoteDataSource, this._storageService, this._supabaseClient);

  final VaultRemoteDataSource _remoteDataSource;
  final VaultStorageService _storageService;
  final supabase.SupabaseClient _supabaseClient;

  String get _uid {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const VaultException('You must be signed in to do this.');
    }
    return user.id;
  }

  @override
  Future<VaultDocument> uploadDocument({
    required String title,
    required DocumentCategory category,
    required String fileType,
    required Uint8List fileBytes,
  }) {
    return _run(() async {
      // TEMPORARY DEV LOGGING -- diagnosing why uploads never reach
      // Supabase. Remove once resolved.
      debugPrint('[UPLOAD] Repository entered');
      final uid = _uid;
      final documentId = _remoteDataSource.newDocumentId();

      final UploadedFile uploaded;
      try {
        debugPrint('[UPLOAD] Uploading to Storage...');
        uploaded = await _storageService.uploadFile(
          uid: uid,
          documentId: documentId,
          fileType: fileType,
          fileBytes: fileBytes,
        );
        debugPrint('[UPLOAD] Storage upload success');
      } catch (error, stackTrace) {
        debugPrint('[UPLOAD ERROR]');
        debugPrint('$error');
        debugPrint('$stackTrace');
        rethrow;
      }

      final now = DateTime.now();
      final model = VaultDocumentModel(
        documentId: documentId,
        ownerUid: uid,
        title: title,
        category: category,
        fileType: fileType,
        fileUrl: uploaded.downloadUrl,
        storagePath: uploaded.storagePath,
        fileSize: fileBytes.length,
        createdAt: now,
        updatedAt: now,
      );

      try {
        debugPrint('[UPLOAD] Inserting PostgreSQL row...');
        await _remoteDataSource.createDocument(
          uid: uid,
          documentId: documentId,
          data: model.toMap(),
        );
        debugPrint('[UPLOAD] Insert success');
      } catch (error, stackTrace) {
        debugPrint('[UPLOAD ERROR]');
        debugPrint('$error');
        debugPrint('$stackTrace');
        // Metadata write failed after the file upload succeeded -- clean up
        // the now-orphaned file rather than leaving it dangling. Awaited,
        // best-effort: swallow a cleanup failure so it doesn't mask the
        // original error below.
        try {
          await _storageService.deleteFile(uploaded.storagePath);
        } catch (_) {
          // Ignored -- see comment above.
        }
        rethrow;
      }

      return model;
    });
  }

  @override
  Stream<List<VaultDocument>> watchAllDocuments() {
    return _watchAndMap(_remoteDataSource.watchDocuments(_uid));
  }

  @override
  Stream<List<VaultDocument>> watchDocumentsByCategory(DocumentCategory category) {
    return _watchAndMap(
      _remoteDataSource.watchDocumentsByCategory(uid: _uid, category: category.name),
    );
  }

  /// Maps rows to domain documents *and* translates stream errors --
  /// `.map()` alone only transforms data events; an error from PostgREST
  /// itself (e.g. a Row Level Security rejection), or one thrown by
  /// [_mapRows] on malformed data, would otherwise pass through unchanged as
  /// a raw [supabase.PostgrestException] or [TypeError]. Shared by both
  /// watch methods so the translation lives in exactly one place.
  Stream<List<VaultDocument>> _watchAndMap(Stream<List<Map<String, dynamic>>> rows) {
    return rows.map((r) {
      // TEMPORARY DEV LOGGING -- diagnosing search/filter/realtime bugs.
      // Remove once resolved.
      debugPrint('[REALTIME] data event -- ${r.length} rows at ${DateTime.now()}');
      return _mapRows(r);
    }).handleError((Object error, StackTrace stackTrace) {
      debugPrint('[REALTIME ERROR] raw error before translation:');
      debugPrint('$error');
      debugPrint('$stackTrace');
      if (error is supabase.RealtimeSubscribeException) {
        // Not fatal: this reports that the live-push side of the
        // subscription failed to attach (e.g. a dropped handshake) --
        // verified from supabase_flutter's source that the underlying
        // stream is NOT closed when this happens, only when the one-shot
        // PostgREST fetch itself fails. The stream keeps working and the
        // next data event (from that same one-shot fetch, or a later
        // reconnect) carries the real, current list. Surfacing this as a
        // fatal VaultException would replace good, current data with an
        // error screen for a condition the stream already recovers from on
        // its own -- so it's logged above and otherwise ignored here.
        return;
      }
      if (error is VaultException) throw error;
      if (error is supabase.PostgrestException) {
        throw VaultException(mapVaultPostgrestError(error.code));
      }
      throw const VaultException(AppStrings.genericErrorMessage);
    });
  }

  @override
  Future<List<VaultDocument>> searchDocuments(String query) {
    return _run(() async {
      debugPrint('[SEARCH] repository.searchDocuments("$query") entered');
      // Postgres full-text search wasn't wired up as part of this
      // migration, so this keeps filtering client-side -- unchanged from
      // the Firestore-era behavior.
      final rows = await _remoteDataSource.fetchDocuments(_uid);
      debugPrint('[SEARCH] fetched ${rows.length} rows to filter client-side');
      final all = _mapRows(rows);
      final lowerQuery = query.trim().toLowerCase();
      if (lowerQuery.isEmpty) return all;
      final results = all
          .where(
            (doc) =>
                doc.title.toLowerCase().contains(lowerQuery) ||
                doc.category.label.toLowerCase().contains(lowerQuery),
          )
          .toList();
      debugPrint('[SEARCH] query "$query" matched ${results.length} of ${all.length} documents');
      return results;
    });
  }

  @override
  Future<VaultDocument> renameDocument({required String documentId, required String newTitle}) {
    return _run(() async {
      final uid = _uid;
      await _remoteDataSource.updateDocument(
        uid: uid,
        documentId: documentId,
        data: {'title': newTitle, 'updated_at': DateTime.now().toIso8601String()},
      );
      final row = await _remoteDataSource.getDocument(uid: uid, documentId: documentId);
      if (row == null) {
        throw const VaultException('Document not found.');
      }
      return VaultDocumentModel.fromMap(row);
    });
  }

  @override
  Future<void> deleteDocument(String documentId) {
    return _run(() async {
      final uid = _uid;
      final row = await _remoteDataSource.getDocument(uid: uid, documentId: documentId);
      final storagePath = row?['storage_path'] as String?;

      // Delete the file before the metadata record: if one half fails, an
      // orphaned Storage file (invisible, just wasted space) is a smaller
      // problem than a database record whose file has vanished (a document
      // the user can see but can never open).
      if (storagePath != null) {
        await _storageService.deleteFile(storagePath);
      }
      await _remoteDataSource.deleteDocument(uid: uid, documentId: documentId);
    });
  }

  @override
  Future<VaultDocument?> getDocumentById(String documentId) {
    return _run(() async {
      final row = await _remoteDataSource.getDocument(uid: _uid, documentId: documentId);
      if (row == null) return null;
      final document = VaultDocumentModel.fromMap(row);
      // The stored `file_url` is short-lived and likely already stale by
      // the time this document is actually opened -- this is the one place
      // a document's file is about to be used (Document Details' preview),
      // so it's the one place that needs a URL guaranteed to still work.
      final freshUrl = await _storageService.getSignedUrl(document.storagePath);
      return document.copyWith(fileUrl: freshUrl);
    });
  }

  List<VaultDocument> _mapRows(List<Map<String, dynamic>> rows) {
    return rows.map(VaultDocumentModel.fromMap).toList();
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on VaultException {
      rethrow;
    } on supabase.PostgrestException catch (e) {
      throw VaultException(mapVaultPostgrestError(e.code));
    } on supabase.StorageException catch (e) {
      // Reachable from `uploadDocument`/`deleteDocument`, both of which call
      // through to `_storageService`.
      throw VaultException(mapVaultStorageError(e.statusCode));
    } catch (_) {
      throw const VaultException(AppStrings.genericErrorMessage);
    }
  }
}

/// Pure mapping from a Postgres/PostgREST error code to a user-friendly
/// message. Kept as a top-level function (rather than a private method) so
/// it's directly unit-testable with a plain string, matching the same
/// pattern used for Firebase Auth error mapping in the authentication
/// feature.
///
/// `42501` is Postgres' SQLSTATE for `insufficient_privilege` -- what a Row
/// Level Security rejection surfaces as. `PGRST116` is PostgREST's own code
/// for "expected exactly one row, got zero or more than one" (not currently
/// reachable via this repository, which uses `.maybeSingle()` rather than
/// `.single()`, but mapped defensively in case that ever changes).
String mapVaultPostgrestError(String? code) {
  switch (code) {
    case '42501':
      return 'You do not have permission to do that.';
    case 'PGRST116':
      return 'The document could not be found.';
    default:
      return AppStrings.genericErrorMessage;
  }
}

/// Pure mapping from a Supabase Storage error's HTTP-style `statusCode`
/// (e.g. `'404'`) to a user-friendly message -- unlike Firebase Storage's
/// string codes (`'object-not-found'` etc.), [supabase.StorageException]
/// carries an HTTP status instead, per the storage_client source.
String mapVaultStorageError(String? statusCode) {
  switch (statusCode) {
    case '401':
      return 'You must be signed in to do this.';
    case '403':
      return 'You do not have permission to do that.';
    case '404':
      return 'The document could not be found.';
    default:
      return AppStrings.genericErrorMessage;
  }
}
