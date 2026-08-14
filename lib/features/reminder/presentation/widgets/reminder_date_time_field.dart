import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/formatters.dart';

/// Controlled date + time picker row, shared by the Create and Edit
/// Reminder screens. Owns no state itself -- [value] is always supplied by
/// the caller, and [onChanged] is called with a new combined [DateTime]
/// whenever either picker returns a selection.
class ReminderDateTimeField extends StatelessWidget {
  const ReminderDateTimeField({required this.value, required this.onChanged, super.key});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value.isBefore(now) ? now : value,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    onChanged(DateTime(picked.year, picked.month, picked.day, value.hour, value.minute));
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
    if (picked == null) return;
    onChanged(DateTime(value.year, value.month, value.day, picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(Formatters.date(value)),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickTime(context),
            icon: const Icon(Icons.access_time),
            label: Text(Formatters.time(value)),
          ),
        ),
      ],
    );
  }
}
