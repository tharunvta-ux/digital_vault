import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../smart_vault/presentation/providers/vault_providers.dart';
import '../../domain/entities/reminder.dart';
import '../controllers/reminder_controller.dart';
import '../dialogs/reminder_delete_dialog.dart';
import '../utils/reminder_list_extensions.dart';
import '../utils/reminder_ui_status.dart';
import '../widgets/reminder_status_chip.dart';
import 'edit_reminder_page.dart';

/// Full detail view for a single reminder -- Edit, Delete, and a toggling
/// Mark Complete/Reopen action, all through [reminderControllerProvider].
/// Like [EditReminderPage], looks the reminder up in the already-live
/// `reminders` list rather than issuing a separate fetch.
class ReminderDetailsPage extends ConsumerWidget {
  const ReminderDetailsPage({required this.reminderId, super.key});

  final String reminderId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ReminderDeleteDialog(reminder: reminder),
    );
    if (confirmed == true && context.mounted) {
      Helpers.showSnackBar(context, 'Reminder deleted.');
      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleCompleted(BuildContext context, WidgetRef ref, Reminder reminder) async {
    final notifier = ref.read(reminderControllerProvider.notifier);
    final wasCompleted = reminder.completed;
    if (wasCompleted) {
      await notifier.reopenReminder(reminder.id);
    } else {
      await notifier.setReminderCompleted(reminder.id);
    }
    if (!context.mounted) return;
    final state = ref.read(reminderControllerProvider);
    if (state.hasError) {
      Helpers.showSnackBar(context, state.errorMessage ?? AppStrings.genericErrorMessage);
    } else {
      Helpers.showSnackBar(context, wasCompleted ? 'Reminder reopened.' : 'Reminder marked complete.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderControllerProvider);
    final reminder = state.reminders.findById(reminderId);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reminder Details'),
      body: reminder == null
          ? (state.isLoading
              ? const LoadingIndicator()
              : const EmptyStateWidget(
                  title: 'Reminder not found',
                  message: 'It may have been deleted.',
                  icon: Icons.event_busy,
                ))
          : _ReminderDetailsBody(
              reminder: reminder,
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditReminderPage(reminderId: reminder.id)),
              ),
              onDelete: () => _delete(context, ref, reminder),
              onToggleCompleted: () => _toggleCompleted(context, ref, reminder),
            ),
    );
  }
}

class _ReminderDetailsBody extends ConsumerWidget {
  const _ReminderDetailsBody({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleCompleted,
  });

  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final documentTitle = ref.watch(documentByIdProvider(reminder.documentId)).valueOrNull?.title;
    final status = ReminderUiStatus.of(reminder);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(reminder.title, style: theme.textTheme.headlineSmall)),
              ReminderStatusChip(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (documentTitle != null) _DetailRow(label: 'Document', value: documentTitle),
          if (reminder.description != null && reminder.description!.isNotEmpty)
            _DetailRow(label: 'Description', value: reminder.description!),
          _DetailRow(label: 'Date', value: Formatters.date(reminder.scheduledAt)),
          _DetailRow(label: 'Time', value: Formatters.time(reminder.scheduledAt)),
          _DetailRow(label: 'Repeat', value: reminder.repeatType.label),
          _DetailRow(label: 'Notifications', value: reminder.notificationEnabled ? 'Enabled' : 'Disabled'),
          _DetailRow(label: 'Created', value: Formatters.date(reminder.createdAt)),
          _DetailRow(label: 'Updated', value: Formatters.date(reminder.updatedAt)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Edit', onPressed: onEdit)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: SecondaryButton(label: 'Delete', onPressed: onDelete)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: reminder.completed ? 'Reopen' : 'Mark Complete',
            onPressed: onToggleCompleted,
          ),
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
