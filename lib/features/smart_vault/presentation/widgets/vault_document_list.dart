import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/document_category.dart';
import '../../domain/vault_exception.dart';
import '../controllers/vault_search_controller.dart';
import '../providers/vault_providers.dart';
import 'vault_document_list_view.dart';

/// Picks the right reactive source (search results, a category filter, or
/// the full list) and renders Loading / Empty / Error / Search-Empty /
/// No-Documents states -- all via the existing shared `core/widgets`
/// components, not bespoke UI. Never calls a backend SDK or a repository
/// directly; only ever reads providers/controllers.
class VaultDocumentList extends ConsumerWidget {
  const VaultDocumentList({
    required this.isSearching,
    required this.searchQuery,
    required this.selectedCategory,
    super.key,
  });

  final bool isSearching;
  final String searchQuery;
  final DocumentCategory? selectedCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isSearching) {
      final searchState = ref.watch(vaultSearchControllerProvider);
      return searchState.when(
        data: (results) {
          if (results == null) {
            return const EmptyStateWidget(
              title: 'Search your vault',
              message: 'Type a title or category to find a document.',
              icon: Icons.search,
            );
          }
          if (results.isEmpty) {
            return const EmptyStateWidget(
              title: 'No results found',
              message: 'Try a different title or category.',
              icon: Icons.search_off,
            );
          }
          return VaultDocumentListView(documents: results);
        },
        loading: () => const LoadingIndicator(message: 'Searching...'),
        error: (error, stackTrace) => AppErrorWidget(
          message: error is VaultException ? error.message : AppStrings.genericErrorMessage,
          onRetry: () => ref.read(vaultSearchControllerProvider.notifier).search(searchQuery),
        ),
      );
    }

    final documentsAsync = selectedCategory == null
        ? ref.watch(watchAllDocumentsProvider)
        : ref.watch(watchDocumentsByCategoryProvider(selectedCategory!));

    return documentsAsync.when(
      data: (documents) {
        if (documents.isEmpty) {
          return const EmptyStateWidget(
            title: 'No documents yet',
            message: 'Upload your first document to get started.',
            icon: Icons.folder_open,
          );
        }
        return VaultDocumentListView(documents: documents);
      },
      loading: () => const LoadingIndicator(message: 'Loading your vault...'),
      error: (error, stackTrace) => AppErrorWidget(
        message: error is VaultException ? error.message : AppStrings.genericErrorMessage,
        onRetry: () => selectedCategory == null
            ? ref.invalidate(watchAllDocumentsProvider)
            : ref.invalidate(watchDocumentsByCategoryProvider(selectedCategory!)),
      ),
    );
  }
}
