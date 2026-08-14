import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'vault_remote_datasource.dart';

/// Supabase/PostgREST-backed implementation of [VaultRemoteDataSource],
/// replacing `FirestoreVaultRemoteDataSource`. Deals only in raw rows and
/// PostgREST filters; mapping to/from the domain entity still happens one
/// layer up, in the repository.
class SupabaseVaultRemoteDataSource implements VaultRemoteDataSource {
  const SupabaseVaultRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _table = 'vault_documents';

  @override
  String newDocumentId() => _uuidV4();

  @override
  Future<void> createDocument({
    required String uid,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    // TEMPORARY DEV LOGGING -- diagnosing why uploads never reach Supabase.
    // Remove once resolved.
    debugPrint('[UPLOAD] Postgres insert payload: $data');
    await _client.from(_table).insert(data);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchDocuments(String uid) {
    // TEMPORARY DEV LOGGING -- diagnosing search/filter/realtime bugs.
    // Remove once resolved.
    debugPrint('[REALTIME] watchDocuments($uid) -- creating new .stream() subscription at ${DateTime.now()}');
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('owner_uid', uid)
        .order('updated_at', ascending: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchDocumentsByCategory({
    required String uid,
    required String category,
  }) {
    // `.stream()` supports exactly one `.eq()` filter (verified directly
    // against supabase_flutter's source -- SupabaseStreamFilterBuilder's
    // docstring: "Only one filter can be applied to `.stream()`"). owner_uid
    // is the one enforced by the query itself (RLS enforces it too, but
    // scoping the realtime subscription avoids streaming every other
    // category's changes to a client that's about to discard them).
    // Category is filtered client-side on top -- same approach already used
    // for search, and the same live-update semantics `watchDocuments` has.
    debugPrint('[FILTER] watchDocumentsByCategory($uid, $category) called');
    return watchDocuments(uid).map((rows) {
      final filtered = rows.where((row) => row['category'] == category).toList();
      debugPrint('[FILTER] category=$category -- ${rows.length} rows in, ${filtered.length} after filter');
      return filtered;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDocuments(String uid) {
    debugPrint('[SEARCH] fetchDocuments($uid) -- one-shot select, no Realtime channel');
    return _client.from(_table).select().eq('owner_uid', uid).order('updated_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>?> getDocument({
    required String uid,
    required String documentId,
  }) async {
    return _client.from(_table).select().eq('id', documentId).eq('owner_uid', uid).maybeSingle();
  }

  @override
  Future<void> updateDocument({
    required String uid,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from(_table).update(data).eq('id', documentId).eq('owner_uid', uid);
  }

  @override
  Future<void> deleteDocument({required String uid, required String documentId}) async {
    await _client.from(_table).delete().eq('id', documentId).eq('owner_uid', uid);
  }

  /// RFC 4122 §4.4 UUID v4 over `Random.secure()`. `supabase_flutter`
  /// (v2.16.0, checked) ships no UUID helper, and this avoids adding a new
  /// pub dependency for something 8 lines can do -- generated client-side,
  /// same as Firestore's `.doc().id` was, so the same ID is known before
  /// either the Storage upload or the database insert happens.
  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10xx
    String hex(int start, int end) =>
        bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
