import 'package:flutter/material.dart';

/// Material 3's `SearchBar`, matching `VaultSearchBar`'s convention -- a
/// search field is a visually distinct pattern from a labeled form field.
class ReminderSearchBar extends StatelessWidget {
  const ReminderSearchBar({required this.controller, required this.onChanged, super.key});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      onChanged: onChanged,
      hintText: 'Search reminders, documents, or notes',
      leading: const Icon(Icons.search),
      trailing: [
        if (controller.text.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller.clear();
              onChanged('');
            },
          ),
      ],
    );
  }
}
