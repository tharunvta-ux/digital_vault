import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/reminder_controller.dart';
import '../utils/reminder_document_lookup.dart';
import '../utils/reminder_ui_status.dart';

/// Small, subtle reminder indicator for a Smart Vault document card --
/// nothing at all when the document has no reminder, otherwise a single
/// small icon (with a tooltip carrying the descriptive text) reflecting its
/// current status. Deliberately not `ReminderStatusChip`: that's a
/// prominent pill meant to anchor a reminder-focused screen, which would
/// visually compete with a document card's own title/metadata instead of
/// sitting quietly beside it.
class DocumentReminderIndicator extends ConsumerWidget {
  const DocumentReminderIndicator({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(reminderControllerProvider).reminders.primaryForDocument(documentId);
    if (reminder == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final status = ReminderUiStatus.of(reminder);
    final (IconData icon, Color color, String label) = switch (status) {
      ReminderUiStatus.upcoming => (Icons.notifications_active, theme.colorScheme.primary, 'Reminder active'),
      ReminderUiStatus.overdue => (Icons.warning_amber_rounded, theme.colorScheme.error, 'Reminder overdue'),
      ReminderUiStatus.completed => (Icons.check_circle, theme.colorScheme.secondary, 'Reminder completed'),
    };

    return Tooltip(message: label, child: Icon(icon, size: 16, color: color));
  }
}
