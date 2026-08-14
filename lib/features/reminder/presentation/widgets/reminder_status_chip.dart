import 'package:flutter/material.dart';

import '../utils/reminder_ui_status.dart';

/// Small pill showing a reminder's current display status, colored via
/// Material 3's semantic container color pairs -- consistent with how the
/// rest of the app (e.g. the delete dialog's error-container button)
/// already borrows those instead of raw [Colors] constants.
class ReminderStatusChip extends StatelessWidget {
  const ReminderStatusChip({required this.status, super.key});

  final ReminderUiStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color background, Color foreground) = switch (status) {
      ReminderUiStatus.upcoming => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      ReminderUiStatus.overdue => (colorScheme.errorContainer, colorScheme.onErrorContainer),
      ReminderUiStatus.completed => (colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
