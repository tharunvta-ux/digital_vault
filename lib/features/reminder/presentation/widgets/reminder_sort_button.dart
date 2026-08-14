import 'package:flutter/material.dart';

import '../state/reminder_sort_option.dart';

/// Sort selector for the Reminder List Screen -- a `PopupMenuButton` rather
/// than another row of chips, since sort is a single mutually-exclusive
/// choice with no need for its own always-visible row.
class ReminderSortButton extends StatelessWidget {
  const ReminderSortButton({required this.selected, required this.onSelected, super.key});

  final ReminderSortOption selected;
  final ValueChanged<ReminderSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ReminderSortOption>(
      tooltip: 'Sort reminders',
      icon: const Icon(Icons.sort),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in ReminderSortOption.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Icon(option == selected ? Icons.check : null, size: 18),
                const SizedBox(width: 8),
                Text(option.label),
              ],
            ),
          ),
      ],
    );
  }
}
