import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../reminder/presentation/controllers/reminder_controller.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/vault_exception.dart';
import '../controllers/delete_document_controller.dart';

/// Confirmation dialog before a destructive delete via
/// [DeleteDocumentController]. Pops with `true` only once the delete has
/// actually succeeded -- a failure leaves the dialog open with an error
/// message rather than closing as if it worked, so a failed delete can
/// never be mistaken for a successful one.
class DeleteConfirmationDialog extends ConsumerWidget {
  const DeleteConfirmationDialog({required this.document, super.key});

  final VaultDocument document;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    // Cancels any local notification for this document's reminder(s)
    // *before* the delete -- not after. The document row and its
    // `reminders` rows are removed together via `ON DELETE CASCADE` (no
    // separate deletion call happens here, or ever, for the reminder side);
    // by the time that finishes, `ReminderController` may have already
    // dropped the reminder from its own live list via the same Realtime
    // event, which would leave nothing here to look up. Cancelling first,
    // while the reminder is still known, avoids that race -- and cancelling
    // a notification for a reminder that turns out not to be deleted after
    // all (an unlikely subsequent failure) is a harmless, fully recoverable
    // outcome, unlike a ghost notification firing for a document that no
    // longer exists.
    await ref.read(reminderControllerProvider.notifier).cancelNotificationsForDocument(document.documentId);
    await ref.read(deleteDocumentControllerProvider.notifier).delete(document.documentId);
    if (!context.mounted) return;
    final state = ref.read(deleteDocumentControllerProvider);
    if (state.hasError) {
      final error = state.error;
      final message = error is VaultException ? error.message : AppStrings.genericErrorMessage;
      Helpers.showSnackBar(context, message);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteState = ref.watch(deleteDocumentControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Delete Document'),
      content: Text('Delete "${document.title}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: deleteState.isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          ),
          onPressed: deleteState.isLoading ? null : () => _confirmDelete(context, ref),
          child: deleteState.isLoading
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onErrorContainer),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
