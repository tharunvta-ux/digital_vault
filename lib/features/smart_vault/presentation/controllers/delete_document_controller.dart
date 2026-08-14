import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vault_providers.dart';

/// Orchestrates a single delete and exposes its loading/error state.
/// Nothing meaningful to return on success beyond "it happened," so state
/// is `void` rather than the document (unlike upload/rename).
class DeleteDocumentController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> delete(String documentId) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(vaultRepositoryProvider).deleteDocument(documentId));
    // Same reasoning as RenameDocumentController: the live-list streams
    // pick this up on their own, but documentByIdProvider is a one-shot
    // FutureProvider and needs to be told to re-fetch (it will then
    // resolve to `null`, which a Document Details screen can use to show
    // "this document was deleted").
    if (!state.hasError) {
      ref.invalidate(documentByIdProvider(documentId));
    }
  }
}

final deleteDocumentControllerProvider =
    AsyncNotifierProvider.autoDispose<DeleteDocumentController, void>(DeleteDocumentController.new);
