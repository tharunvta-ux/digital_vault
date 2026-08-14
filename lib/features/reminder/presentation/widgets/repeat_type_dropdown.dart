import 'package:flutter/material.dart';

import '../../domain/entities/repeat_type.dart';

/// Controlled dropdown over every [RepeatType] value, shared by the Create
/// and Edit Reminder screens.
class RepeatTypeDropdown extends StatelessWidget {
  const RepeatTypeDropdown({required this.value, required this.onChanged, super.key});

  final RepeatType value;
  final ValueChanged<RepeatType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RepeatType>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()),
      items: [
        for (final repeatType in RepeatType.values)
          DropdownMenuItem(value: repeatType, child: Text(repeatType.label)),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
