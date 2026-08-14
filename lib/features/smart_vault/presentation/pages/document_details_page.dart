import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../reminder/presentation/widgets/document_reminder_section.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/vault_exception.dart';
import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/rename_document_dialog.dart';
import '../preview/image_preview.dart';
import '../preview/pdf_preview.dart';
import '../providers/vault_providers.dart';

/// Shows one document's preview, metadata, and the Rename/Delete actions.
/// Reached via `Navigator.push` from the vault list (not a named GoRoute --
/// see the Step 5 summary for why), reads its data purely by watching
/// `documentByIdProvider(documentId)`.
class DocumentDetailsPage extends ConsumerWidget {
  const DocumentDetailsPage({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentByIdProvider(documentId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Document Details'),
      body: documentAsync.when(
        data: (document) {
          if (document == null) {
            return const EmptyStateWidget(
              title: 'Document not found',
              message: 'It may have been deleted.',
              icon: Icons.error_outline,
            );
          }
          return _DocumentDetailsBody(document: document);
        },
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => AppErrorWidget(
          message: error is VaultException ? error.message : AppStrings.genericErrorMessage,
          onRetry: () => ref.invalidate(documentByIdProvider(documentId)),
        ),
      ),
    );
  }
}

class _DocumentDetailsBody extends StatelessWidget {
  const _DocumentDetailsBody({required this.document});

  final VaultDocument document;

  Widget _buildPreview(BuildContext context) {
    final type = document.fileType.toLowerCase();
    if (type == 'pdf') {
      return PdfPreview(url: document.fileUrl);
    }
    if (type == 'jpg' || type == 'jpeg' || type == 'png') {
      return ImagePreview(url: document.fileUrl);
    }
    return Center(
      child: Icon(
        Icons.insert_drive_file_outlined,
        size: 96,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = AppBreakpoints.isTablet(context.screenSize.width) ||
        AppBreakpoints.isDesktop(context.screenSize.width);

    final preview = ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: _buildPreview(context),
    );

    final metadata = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(document.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Category', value: document.category.label),
          _DetailRow(label: 'File Size', value: Formatters.fileSize(document.fileSize)),
          _DetailRow(label: 'Created', value: Formatters.date(document.createdAt)),
          _DetailRow(label: 'Updated', value: Formatters.date(document.updatedAt)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Rename',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => RenameDocumentDialog(document: document),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SecondaryButton(
                  label: 'Delete',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => DeleteConfirmationDialog(document: document),
                    );
                    if (confirmed == true && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DocumentReminderSection(documentId: document.documentId),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: SizedBox(height: 500, child: preview)),
          Expanded(flex: 2, child: SingleChildScrollView(child: metadata)),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 320, child: preview),
          metadata,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(flex: 3, child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
