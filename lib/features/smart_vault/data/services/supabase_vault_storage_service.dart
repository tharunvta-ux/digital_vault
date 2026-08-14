import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'vault_storage_service.dart';

/// Supabase Storage-backed implementation of [VaultStorageService],
/// replacing `FirebaseVaultStorageService`. Uses the private `vault-files`
/// bucket -- access is enforced by Storage RLS policies scoped to
/// `auth.uid()` (see the migration report), not by the URL being secret.
class SupabaseVaultStorageService implements VaultStorageService {
  const SupabaseVaultStorageService(this._client);

  final SupabaseClient _client;

  static const String _bucket = 'vault-files';

  /// How long a signed download URL stays valid. The bucket itself is
  /// private and policy-gated, so this isn't the access-control boundary --
  /// it bounds how long a URL keeps working *after* it's been handed to a
  /// widget that's about to fetch it, nothing more. Kept short (well within
  /// the 5-15 minute range) precisely because [getSignedUrl] is called
  /// fresh every time a file is actually about to be opened -- the app
  /// never depends on a URL surviving longer than one preview load, so
  /// there's no reason for it to.
  static const int _signedUrlExpirySeconds = 60 * 10; // 10 minutes

  @override
  Future<UploadedFile> uploadFile({
    required String uid,
    required String documentId,
    required String fileType,
    required Uint8List fileBytes,
  }) async {
    // Per-user path: nobody can construct another user's path without
    // knowing their UID, and it maps directly onto the Storage RLS
    // policies (`(storage.foldername(name))[2] = auth.uid()::text`).
    final path = 'users/$uid/vault/$documentId.$fileType';
    // TEMPORARY DEV LOGGING -- diagnosing why uploads never reach Supabase.
    // Remove once resolved.
    debugPrint('[UPLOAD] Datasource entered -- bucket: $_bucket, path: $path');
    await _client.storage.from(_bucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(contentType: _contentTypeFor(fileType)),
        );
    // This URL is only ever used immediately after upload (to populate the
    // new document's in-memory state before the first re-fetch) -- every
    // later read regenerates its own via `getSignedUrl`, so this one is
    // never relied on once it's stale.
    final downloadUrl = await getSignedUrl(path);
    return UploadedFile(downloadUrl: downloadUrl, storagePath: path);
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    try {
      await _client.storage.from(_bucket).remove([storagePath]);
    } on StorageException catch (e) {
      // No-op if the file is already gone, so a retried delete never fails
      // on that alone -- same contract this method had for Firebase
      // Storage's `object-not-found`.
      if (e.statusCode != '404') rethrow;
    }
  }

  @override
  Future<String> getSignedUrl(String storagePath) {
    return _client.storage.from(_bucket).createSignedUrl(storagePath, _signedUrlExpirySeconds);
  }

  String? _contentTypeFor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }
}
