import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/supabase_vault_remote_datasource.dart';
import '../../data/datasources/vault_remote_datasource.dart';
import '../../data/repositories/vault_repository_impl.dart';
import '../../data/services/supabase_vault_storage_service.dart';
import '../../data/services/vault_storage_service.dart';
import '../../domain/entities/document_category.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/repositories/vault_repository.dart';

/// Dependency-injection graph for the Smart Vault feature, wired the same
/// way as the authentication feature: hand-written Riverpod providers, no
/// codegen, each depending only on the one above it.
final vaultRemoteDataSourceProvider = Provider<VaultRemoteDataSource>((ref) {
  return SupabaseVaultRemoteDataSource(ref.watch(supabaseClientProvider));
});

final vaultStorageServiceProvider = Provider<VaultStorageService>((ref) {
  return SupabaseVaultStorageService(ref.watch(supabaseClientProvider));
});

/// Reuses [supabaseClientProvider] from the authentication feature rather
/// than declaring a second `Provider<SupabaseClient>` — there's only ever
/// one `Supabase.instance.client`, and duplicating the provider would risk
/// the two features silently drifting apart (e.g. one gets overridden with
/// a fake in a test and the other doesn't). Also resolves the current
/// user's UID for document ownership, replacing the `FirebaseAuth`
/// dependency this provider used before the migration.
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepositoryImpl(
    ref.watch(vaultRemoteDataSourceProvider),
    ref.watch(vaultStorageServiceProvider),
    ref.watch(supabaseClientProvider),
  );
});

/// Live view of every document owned by the current user.
///
/// Watches [authStateChangesProvider] purely so this provider *rebuilds*
/// whenever the signed-in user changes. Without that, a logout followed by
/// a different user signing in within the same app session would keep
/// streaming the previous user's Realtime subscription — the UID a stream
/// is scoped to is resolved once, when the underlying `watchAllDocuments()`
/// call is made, not on every emission.
///
/// `autoDispose`: the underlying Realtime subscription closes once nothing
/// is watching this anymore (e.g. navigating away from the vault), rather
/// than staying open for the app's entire lifetime.
final watchAllDocumentsProvider = StreamProvider.autoDispose<List<VaultDocument>>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(vaultRepositoryProvider).watchAllDocuments();
});

/// Same live-update and rebuild-on-auth-change reasoning as
/// [watchAllDocumentsProvider], scoped to a single category. `.family`
/// because it's parameterized by which category is being viewed — the
/// idiomatic Riverpod tool for "reactive data parameterized by an
/// argument," rather than a hand-rolled controller that manually forwards
/// a stream's emissions into its own state.
final watchDocumentsByCategoryProvider =
    StreamProvider.autoDispose.family<List<VaultDocument>, DocumentCategory>((ref, category) {
  ref.watch(authStateChangesProvider);
  return ref.watch(vaultRepositoryProvider).watchDocumentsByCategory(category);
});

/// A single document by ID. A one-shot read (unlike the two providers
/// above), so `FutureProvider` rather than `StreamProvider`. `.family`
/// keyed by document ID so Riverpod caches per-document and disposes each
/// entry once nothing's viewing that particular document anymore.
final documentByIdProvider = FutureProvider.autoDispose.family<VaultDocument?, String>((
  ref,
  documentId,
) {
  ref.watch(authStateChangesProvider);
  return ref.watch(vaultRepositoryProvider).getDocumentById(documentId);
});
