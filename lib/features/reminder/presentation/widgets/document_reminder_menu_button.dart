import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/reminder_controller.dart';
import '../utils/reminder_document_lookup.dart';
import '../pages/create_reminder_page.dart';
import '../pages/reminder_details_page.dart';

/// A document card's reminder quick action -- "Create Reminder" (with the
/// document already selected, see `CreateReminderPage.documentId`) when
/// none exists yet, or "View Reminder" when one already does. Kept to a
/// single item either way: this is a quick action, not a full menu, and
/// Edit/Delete/Mark Complete/Reopen already live one tap away on the
/// Reminder Details screen this opens.
class DocumentReminderMenuButton extends ConsumerWidget {
  const DocumentReminderMenuButton({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(reminderControllerProvider).reminders.primaryForDocument(documentId);

    return PopupMenuButton<String>(
      tooltip: 'Reminder actions',
      onSelected: (value) {
        if (value == 'create') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CreateReminderPage(documentId: documentId)),
          );
        } else if (value == 'view' && reminder != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReminderDetailsPage(reminderId: reminder.id)),
          );
        }
      },
      itemBuilder: (context) => [
        if (reminder == null)
          const PopupMenuItem(value: 'create', child: Text('Create Reminder'))
        else
          const PopupMenuItem(value: 'view', child: Text('View Reminder')),
      ],
    );
  }
}
