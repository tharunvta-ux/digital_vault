import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vault_document.dart';
import '../providers/vault_providers.dart';

/// Orchestrates a single rename and exposes its loading/error state, plus
/// the updated document on success. `autoDispose` so leaving and returning
/// to a rename dialog always starts clean.
class RenameDocumentController extends AutoDisposeAsyncNotifier<VaultDocument?> {
  @override
  FutureOr<VaultDocument?> build() => null;

  Future<void> rename({required String documentId, required String newTitle}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vaultRepositoryProvider).renameDocument(
            documentId: documentId,
            newTitle: newTitle,
          ),
    );
    // watchAllDocumentsProvider/watchDocumentsByCategoryProvider are live
    // Realtime streams and pick this up on their own. documentByIdProvider
    // is a one-shot FutureProvider, not a stream -- it has no mechanism to
    // notice this change by itself, so a screen watching this specific
    // document's cached read needs to be told to re-fetch.
    if (!state.hasError) {
      ref.invalidate(documentByIdProvider(documentId));
    }
  }
}

final renameDocumentControllerProvider =
    AsyncNotifierProvider.autoDispose<RenameDocumentController, VaultDocument?>(
  RenameDocumentController.new,
);
