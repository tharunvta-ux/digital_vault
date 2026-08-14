import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../domain/entities/reminder.dart';
import '../controllers/reminder_controller.dart';
import '../dialogs/reminder_delete_dialog.dart';
import '../pages/edit_reminder_page.dart';
import '../utils/reminder_ui_status.dart';
import 'reminder_status_chip.dart';

/// A single reminder's summary row: title, linked document, description,
/// schedule, repeat type, notification state, and status -- with swipe
/// gestures (delete / mark complete-reopen) and an overflow menu (edit /
/// delete) as two paths to the same actions, all going through
/// [reminderControllerProvider] -- never a repository or usecase directly.
///
/// [documentTitle] is passed in rather than watched per-card: the list
/// screen already loads every vault document once (for search and display),
/// so building a `documentId -> title` lookup there and passing the single
/// matching title down avoids opening one provider read per visible card.
class ReminderCard extends ConsumerWidget {
  const ReminderCard({
    required this.reminder,
    required this.documentTitle,
    required this.onTap,
    super.key,
  });

  final Reminder reminder;
  final String? documentTitle;
  final VoidCallback onTap;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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

  void _edit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditReminderPage(reminderId: reminder.id)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ReminderUiStatus.of(reminder);

    return Dismissible(
      key: ValueKey(reminder.id),
      // Both directions only ever trigger the underlying action and snap
      // back -- the card itself never leaves the tree on its own. Removal
      // (delete) or a status change (complete/reopen) both come back
      // through the live Realtime stream `ReminderController` already
      // listens to, which is what actually updates this list. Letting
      // Dismissible remove the tile itself, ahead of that, risks the
      // classic "A dismissed Dismissible widget is still part of the tree"
      // assertion once the stream's own update arrives a moment later.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _confirmDelete(context, ref);
        } else {
          await _toggleCompleted(context, ref);
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: theme.colorScheme.secondaryContainer,
        icon: reminder.completed ? Icons.replay : Icons.check_circle,
        label: reminder.completed ? 'Reopen' : 'Complete',
        foreground: theme.colorScheme.onSecondaryContainer,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: theme.colorScheme.errorContainer,
        icon: Icons.delete,
        label: 'Delete',
        foreground: theme.colorScheme.onErrorContainer,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ReminderStatusChip(status: status),
                    PopupMenuButton<String>(
                      tooltip: 'More actions',
                      onSelected: (value) {
                        if (value == 'edit') _edit(context);
                        if (value == 'delete') _confirmDelete(context, ref);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                if (documentTitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.description_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          documentTitle!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    reminder.description!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(Formatters.date(reminder.scheduledAt), style: theme.textTheme.bodySmall),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(Formatters.time(reminder.scheduledAt), style: theme.textTheme.bodySmall),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.repeat, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(reminder.repeatType.label, style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Tooltip(
                      message: reminder.notificationEnabled ? 'Notifications on' : 'Notifications off',
                      child: Icon(
                        reminder.notificationEnabled ? Icons.notifications_active : Icons.notifications_off,
                        size: 18,
                        color: reminder.notificationEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Semantics(
        label: label,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: TextStyle(color: foreground, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
