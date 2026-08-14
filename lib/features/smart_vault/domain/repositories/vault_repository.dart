import 'dart:typed_data';

import '../entities/document_category.dart';
import '../entities/vault_document.dart';

/// Contract for all Smart Vault document operations. Implemented by the
/// data layer against Supabase PostgreSQL + Supabase Storage — nothing in
/// this file, or anything that depends only on it, knows either exists.
///
/// Every method operates implicitly on the currently authenticated user —
/// callers never pass a UID. This mirrors the authentication feature's
/// repository and keeps "a user can only ever see their own documents" a
/// guarantee the implementation enforces, rather than something every call
/// site has to remember to do correctly.
abstract class VaultRepository {
  /// Uploads [fileBytes] to storage and records its metadata. Returns the
  /// resulting [VaultDocument] once both the file and its metadata are
  /// persisted. `Uint8List` (rather than a `dart:io` `File`) is used so this
  /// contract works identically on every platform this app targets,
  /// including web, which has no filesystem access.
  Future<VaultDocument> uploadDocument({
    required String title,
    required DocumentCategory category,
    required String fileType,
    required Uint8List fileBytes,
  });

  /// A live view of every document owned by the current user, most-recently
  /// updated first. Emits a new list whenever a document is added, renamed,
  /// or deleted — a `Stream`, not a one-shot `Future`, so the Vault List
  /// screen can stay in sync without manual refreshing.
  Stream<List<VaultDocument>> watchAllDocuments();

  /// A live view scoped to a single [category] — same ordering and
  /// live-update semantics as [watchAllDocuments].
  Stream<List<VaultDocument>> watchDocumentsByCategory(DocumentCategory category);

  /// One-shot search across title and category for [query]
  /// (case-insensitive, substring match). A `Future` rather than a
  /// `Stream`: search is a discrete, user-triggered action (type a query,
  /// get results), not something that needs to stay continuously live the
  /// way the main list does.
  Future<List<VaultDocument>> searchDocuments(String query);

  /// Updates [documentId]'s title, returning the updated document.
  Future<VaultDocument> renameDocument({
    required String documentId,
    required String newTitle,
  });

  /// Permanently deletes a document's metadata record and its underlying
  /// file in storage.
  Future<void> deleteDocument(String documentId);

  /// A single document by ID, or `null` if it doesn't exist or isn't owned
  /// by the current user.
  Future<VaultDocument?> getDocumentById(String documentId);
}
