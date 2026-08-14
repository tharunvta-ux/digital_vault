/// Thin wrapper contract over the Supabase `vault_documents` table. Deals
/// only in raw rows (`Map<String, dynamic>`, as returned by PostgREST) and
/// UIDs; mapping to/from the domain entity happens one layer up, in the
/// repository (via `VaultDocumentModel`), exactly like the auth feature's
/// datasource stays ignorant of `UserEntity`.
///
/// Every method is scoped by an explicit [uid] parameter rather than
/// resolving "who's logged in" itself — that's the repository's job (see
/// its doc comment); this class just does whatever per-user filter it's
/// told. Row Level Security enforces the same scoping server-side, so this
/// is defense in depth, not the only thing standing between a user and
/// someone else's documents.
abstract class VaultRemoteDataSource {
  /// A new, not-yet-persisted document ID — generated client-side with no
  /// network round-trip, so the same ID can be used for both the Storage
  /// upload and the database row.
  String newDocumentId();

  Future<void> createDocument({
    required String uid,
    required String documentId,
    required Map<String, dynamic> data,
  });

  /// Live, most-recently-updated-first list of every document for [uid].
  Stream<List<Map<String, dynamic>>> watchDocuments(String uid);

  /// One-shot, most-recently-updated-first list of every document for
  /// [uid] -- a plain PostgREST `select`, no Realtime subscription. For
  /// callers (like search) that need the current list once and are done;
  /// unlike [watchDocuments], this never opens a Realtime channel.
  Future<List<Map<String, dynamic>>> fetchDocuments(String uid);

  /// Live, most-recently-updated-first list scoped to a single category.
  Stream<List<Map<String, dynamic>>> watchDocumentsByCategory({
    required String uid,
    required String category,
  });

  /// A single document, or `null` if it doesn't exist under [uid].
  Future<Map<String, dynamic>?> getDocument({
    required String uid,
    required String documentId,
  });

  Future<void> updateDocument({
    required String uid,
    required String documentId,
    required Map<String, dynamic> data,
  });

  Future<void> deleteDocument({required String uid, required String documentId});
}
