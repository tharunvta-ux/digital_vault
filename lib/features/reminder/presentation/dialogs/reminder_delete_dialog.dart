import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/reminder.dart';
import '../controllers/reminder_controller.dart';

/// Confirmation dialog before a destructive delete, matching Smart Vault's
/// `DeleteConfirmationDialog` convention: pops with `true` only once the
/// delete has actually succeeded through [reminderControllerProvider] -- a
/// failure leaves the dialog open with an inline error rather than closing
/// as if it worked.
class ReminderDeleteDialog extends ConsumerWidget {
  const ReminderDeleteDialog({required this.reminder, super.key});

  final Reminder reminder;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await ref.read(reminderControllerProvider.notifier).deleteReminder(reminder.id);
    if (!context.mounted) return;
    final state = ref.read(reminderControllerProvider);
    if (!state.hasError) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Delete Reminder'),
      content: Text(
        state.hasError
            ? state.errorMessage ?? AppStrings.genericErrorMessage
            : 'Delete "${reminder.title}"? This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          ),
          onPressed: state.isLoading ? null : () => _confirmDelete(context, ref),
          child: state.isLoading
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
