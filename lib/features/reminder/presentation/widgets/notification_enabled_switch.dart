import 'package:flutter/material.dart';

/// Controlled on/off switch for `Reminder.notificationEnabled`, shared by
/// the Create and Edit Reminder screens.
class NotificationEnabledSwitch extends StatelessWidget {
  const NotificationEnabledSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Enable notification'),
      subtitle: const Text('Get a reminder alert at the scheduled time.'),
      value: value,
      onChanged: onChanged,
    );
  }
}
