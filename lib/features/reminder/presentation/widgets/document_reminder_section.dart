import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/reminder.dart';
import '../controllers/reminder_controller.dart';
import '../dialogs/reminder_delete_dialog.dart';
import '../providers/reminder_providers.dart';
import '../utils/reminder_document_lookup.dart';
import '../utils/reminder_ui_status.dart';
import '../pages/create_reminder_page.dart';
import '../pages/edit_reminder_page.dart';
import '../pages/reminder_details_page.dart';
import 'reminder_status_chip.dart';

/// The Reminder section embedded in Smart Vault's Document Details screen.
/// Everything reminder-specific -- the lookup, the status/date/time
/// display, every action -- lives here and in the rest of the Reminder
/// module; Smart Vault only ever drops this one widget in and passes a
/// `documentId`, never touching `ReminderController`/`ReminderState`
/// itself.
///
/// Reuses [reminderControllerProvider]'s already-live `reminders` list
/// (kept current by its Realtime subscription since Phase 3) rather than
/// issuing a query of its own -- opening this screen never hits Supabase a
/// second time for reminder data.
class DocumentReminderSection extends ConsumerWidget {
  const DocumentReminderSection({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderControllerProvider);
    final theme = Theme.of(context);

    Widget body;
    if (state.reminders.isEmpty && state.isLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LoadingIndicator(message: 'Loading reminder...'),
      );
    } else if (state.reminders.isEmpty && state.hasError) {
      body = AppErrorWidget(
        message: state.errorMessage ?? AppStrings.genericErrorMessage,
        onRetry: () => ref.invalidate(watchRemindersProvider),
      );
    } else {
      final reminder = state.reminders.primaryForDocument(documentId);
      body = reminder == null ? _NoReminder(documentId: documentId) : _ReminderSummary(reminder: reminder);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            body,
          ],
        ),
      ),
    );
  }
}

class _NoReminder extends StatelessWidget {
  const _NoReminder({required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No reminder configured',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: 'Create Reminder',
          fullWidth: false,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CreateReminderPage(documentId: documentId)),
          ),
        ),
      ],
    );
  }
}

class _ReminderSummary extends ConsumerWidget {
  const _ReminderSummary({required this.reminder});

  final Reminder reminder;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ReminderDeleteDialog(reminder: reminder),
    );
    if (confirmed == true && context.mounted) {
      Helpers.showSnackBar(context, 'Reminder deleted.');
    }
  }

  Future<void> _toggleCompleted(BuildContext context, WidgetRef ref) async {
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
    final theme = Theme.of(context);
    final status = ReminderUiStatus.of(reminder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                reminder.title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ReminderStatusChip(status: status),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(Formatters.date(reminder.scheduledAt), style: theme.textTheme.bodySmall),
            const SizedBox(width: AppSpacing.md),
            Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(Formatters.time(reminder.scheduledAt), style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.repeat, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(reminder.repeatType.label, style: theme.textTheme.bodySmall),
            const SizedBox(width: AppSpacing.md),
            Icon(
              reminder.notificationEnabled ? Icons.notifications_active : Icons.notifications_off,
              size: 16,
              color: reminder.notificationEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              reminder.notificationEnabled ? 'Notifications on' : 'Notifications off',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReminderDetailsPage(reminderId: reminder.id)),
              ),
              child: const Text('View'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditReminderPage(reminderId: reminder.id)),
              ),
              child: const Text('Edit'),
            ),
            OutlinedButton(onPressed: () => _delete(context, ref), child: const Text('Delete')),
            FilledButton.tonal(
              onPressed: () => _toggleCompleted(context, ref),
              child: Text(reminder.completed ? 'Reopen' : 'Mark Completed'),
            ),
          ],
        ),
      ],
    );
  }
}
