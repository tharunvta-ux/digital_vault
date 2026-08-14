import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/document_category.dart';
import '../../domain/entities/vault_document.dart';
import '../providers/vault_providers.dart';

/// Orchestrates a single document upload and exposes its loading/error
/// state, plus the resulting document on success (so a future presentation
/// layer can, for example, navigate straight to its detail page without
/// waiting for the live list to re-emit).
///
/// `autoDispose` so returning to the upload flow always starts clean, not
/// with a stale result/error from a previous visit.
class UploadDocumentController extends AutoDisposeAsyncNotifier<VaultDocument?> {
  @override
  FutureOr<VaultDocument?> build() => null;

  Future<void> upload({
    required String title,
    required DocumentCategory category,
    required String fileType,
    required Uint8List fileBytes,
  }) async {
    if (state.isLoading) return;
    // TEMPORARY DEV LOGGING -- diagnosing why uploads never reach Supabase.
    // Remove once resolved.
    debugPrint('[UPLOAD] Controller entered');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vaultRepositoryProvider).uploadDocument(
            title: title,
            category: category,
            fileType: fileType,
            fileBytes: fileBytes,
          ),
    );
    if (state.hasError) {
      debugPrint('[UPLOAD] Controller: upload failed -- ${state.error}');
    } else {
      debugPrint('[UPLOAD] Controller: upload succeeded');
    }
  }
}

final uploadDocumentControllerProvider =
    AsyncNotifierProvider.autoDispose<UploadDocumentController, VaultDocument?>(
  UploadDocumentController.new,
);
