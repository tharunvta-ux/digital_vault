import '../../domain/entities/document_category.dart';
import '../../domain/entities/vault_document.dart';

/// Maps between a Supabase/PostgREST row (snake_case columns) and the domain
/// [VaultDocument]. The only file in this feature that knows the
/// `vault_documents` table's column names.
class VaultDocumentModel extends VaultDocument {
  const VaultDocumentModel({
    required super.documentId,
    required super.ownerUid,
    required super.title,
    required super.category,
    required super.fileType,
    required super.fileUrl,
    required super.storagePath,
    required super.fileSize,
    required super.createdAt,
    required super.updatedAt,
  });

  /// [data] is a raw row as returned by PostgREST (e.g. from `.select()` or
  /// a `.stream()` event) -- always a plain `Map<String, dynamic>`, unlike
  /// Firestore's wrapping `DocumentSnapshot`.
  factory VaultDocumentModel.fromMap(Map<String, dynamic> data) {
    return VaultDocumentModel(
      documentId: data['id'] as String,
      ownerUid: data['owner_uid'] as String,
      title: data['title'] as String,
      // Defensive fallback to `other`: if a category is ever renamed or
      // removed, an older stored value doesn't crash the app on read.
      category: DocumentCategory.values.firstWhere(
        (candidate) => candidate.name == data['category'],
        orElse: () => DocumentCategory.other,
      ),
      fileType: data['file_type'] as String,
      fileUrl: data['file_url'] as String,
      storagePath: data['storage_path'] as String,
      fileSize: (data['file_size'] as num).toInt(),
      // PostgREST serializes `timestamptz` columns as ISO 8601 strings.
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': documentId,
      'owner_uid': ownerUid,
      'title': title,
      'category': category.name,
      'file_type': fileType,
      'file_url': fileUrl,
      'storage_path': storagePath,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
