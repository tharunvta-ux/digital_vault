import 'document_category.dart';

/// Domain representation of a single vault document's metadata.
///
/// Mirrors the columns the `vault_documents` Postgres table stores, but is
/// deliberately free of any Supabase/Storage types (e.g. no PostgREST row
/// type, no `Reference`) so the domain and presentation layers never
/// depend on a specific backend — only the data layer knows either exists.
class VaultDocument {
  const VaultDocument({
    required this.documentId,
    required this.ownerUid,
    required this.title,
    required this.category,
    required this.fileType,
    required this.fileUrl,
    required this.storagePath,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for this document (the `vault_documents` table's
  /// `id` UUID once persisted).
  final String documentId;

  /// UID of the user who owns this document. Repository methods never take
  /// a UID parameter (see the repository interface's doc comment) — this
  /// field exists because it's part of the stored metadata, not because
  /// callers use it to scope queries themselves.
  final String ownerUid;

  /// Display name for the document, editable via rename.
  final String title;

  final DocumentCategory category;

  /// The kind of file this is (e.g. `pdf`, `jpg`, `png`). Kept as a plain
  /// string rather than a dedicated enum for now — Step 2 is scoped to
  /// exactly this entity, the category enum, and the repository interface,
  /// so introducing a second enum wasn't part of the request. Worth
  /// reconsidering once the upload step defines exactly which values get
  /// written here.
  final String fileType;

  /// Secure, downloadable URL for the underlying file in Storage.
  final String fileUrl;

  /// Path to the underlying file within Storage — needed to delete the
  /// file (not just its metadata) later.
  final String storagePath;

  /// File size in bytes. Formatting (e.g. "2.4 MB") is a presentation
  /// concern, not stored here.
  final int fileSize;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced — needed for operations
  /// like rename, which produce an updated document from an existing one
  /// without mutating it in place.
  VaultDocument copyWith({
    String? documentId,
    String? ownerUid,
    String? title,
    DocumentCategory? category,
    String? fileType,
    String? fileUrl,
    String? storagePath,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultDocument(
      documentId: documentId ?? this.documentId,
      ownerUid: ownerUid ?? this.ownerUid,
      title: title ?? this.title,
      category: category ?? this.category,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultDocument &&
          other.documentId == documentId &&
          other.ownerUid == ownerUid &&
          other.title == title &&
          other.category == category &&
          other.fileType == fileType &&
          other.fileUrl == fileUrl &&
          other.storagePath == storagePath &&
          other.fileSize == fileSize &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        documentId,
        ownerUid,
        title,
        category,
        fileType,
        fileUrl,
        storagePath,
        fileSize,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'VaultDocument(documentId: $documentId, title: $title, category: $category)';
}
