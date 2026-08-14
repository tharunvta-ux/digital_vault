import 'dart:typed_data';

/// Result of a successful upload — both the download URL and the exact
/// storage path actually written to, returned together so a caller can
/// never end up recording a path that doesn't match where the bytes
/// actually landed.
class UploadedFile {
  const UploadedFile({required this.downloadUrl, required this.storagePath});

  final String downloadUrl;
  final String storagePath;
}

/// Thin wrapper contract over the file-storage backend (Supabase Storage).
/// Deals only in bytes/paths/URLs; knows nothing about the vault document
/// entity or how document metadata is stored.
abstract class VaultStorageService {
  /// Uploads [fileBytes] to a path scoped to [uid], named after
  /// [documentId] and [fileType]. Returns the resulting download URL and
  /// the exact path used.
  Future<UploadedFile> uploadFile({
    required String uid,
    required String documentId,
    required String fileType,
    required Uint8List fileBytes,
  });

  /// Deletes the file at [storagePath]. A no-op (not an error) if the file
  /// is already gone, so a retried delete never fails on that alone.
  Future<void> deleteFile(String storagePath);

  /// A fresh, short-lived download URL for [storagePath]. Called whenever a
  /// document's file is actually about to be used (opened for preview) --
  /// not cached or persisted, so a URL is never valid for longer than it
  /// takes to load the file it points to.
  Future<String> getSignedUrl(String storagePath);
}
