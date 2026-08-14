import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../reminder/presentation/widgets/document_reminder_indicator.dart';
import '../../../reminder/presentation/widgets/document_reminder_menu_button.dart';
import '../../domain/entities/vault_document.dart';
import 'document_file_icon.dart';

/// A single document's summary row -- title, category, file type, size,
/// and last-updated, with a tap target for opening its details. The
/// trailing [DocumentReminderIndicator]/[DocumentReminderMenuButton] are
/// the only two additions Phase 6 made here -- both come from the Reminder
/// module and own their own reminder lookups; this card never reads
/// `ReminderController` itself.
class VaultDocumentCard extends StatelessWidget {
  const VaultDocumentCard({required this.document, required this.onTap, super.key});

  final VaultDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              DocumentFileIcon(fileType: document.fileType),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      document.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${document.category.label} • ${document.fileType.toUpperCase()} • '
                      '${Formatters.fileSize(document.fileSize)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Updated ${Formatters.date(document.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              DocumentReminderIndicator(documentId: document.documentId),
              const SizedBox(width: AppSpacing.xs),
              DocumentReminderMenuButton(documentId: document.documentId),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
