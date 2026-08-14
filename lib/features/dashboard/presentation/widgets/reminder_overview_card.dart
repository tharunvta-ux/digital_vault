import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../reminder/domain/entities/reminder.dart';
import '../../../reminder/presentation/controllers/reminder_controller.dart';
import '../../../reminder/presentation/pages/reminder_details_page.dart';
import '../../../reminder/presentation/providers/reminder_providers.dart';
import '../../../reminder/presentation/widgets/reminder_status_chip.dart';
import '../../../reminder/presentation/utils/reminder_ui_status.dart';
import '../../../smart_vault/presentation/providers/vault_providers.dart';
import 'dashboard_preview_card.dart';

/// Dashboard's "Upcoming Reminders" section. Reuses
/// [reminderControllerProvider]'s already-live `reminders` list (kept
/// current by its own Realtime subscription) -- the Dashboard never queries
/// Supabase for reminder data itself, and never reimplements what counts as
/// "upcoming."
class ReminderOverviewCard extends ConsumerWidget {
  const ReminderOverviewCard({super.key});

  static const int _maxRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderControllerProvider);

    Widget child;
    if (state.reminders.isEmpty && state.isLoading) {
      child = const LoadingIndicator();
    } else if (state.reminders.isEmpty && state.hasError) {
      child = AppErrorWidget(
        message: state.errorMessage ?? AppStrings.genericErrorMessage,
        onRetry: () => ref.invalidate(watchRemindersProvider),
      );
    } else {
      final upcoming = [...state.upcomingReminders]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      if (upcoming.isEmpty) {
        child = const EmptyStateWidget(title: 'No upcoming reminders.', icon: Icons.notifications_none);
      } else {
        child = Column(
          children: [
            for (final reminder in upcoming.take(_maxRows)) _ReminderRow(reminder: reminder),
          ],
        );
      }
    }

    return DashboardPreviewCard(title: 'Upcoming Reminders', child: child);
  }
}

class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final documentTitle = ref.watch(documentByIdProvider(reminder.documentId)).valueOrNull?.title;
    final status = ReminderUiStatus.of(reminder);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReminderDetailsPage(reminderId: reminder.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    [
                      ?documentTitle,
                      '${Formatters.date(reminder.scheduledAt)} ${Formatters.time(reminder.scheduledAt)}',
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ReminderStatusChip(status: status),
          ],
        ),
      ),
    );
  }
}
