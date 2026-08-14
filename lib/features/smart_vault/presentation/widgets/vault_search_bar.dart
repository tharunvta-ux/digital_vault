import 'package:flutter/material.dart';

/// Material 3's `SearchBar`, not `CustomTextField` -- a search field is a
/// visually distinct pattern (pill-shaped, prefix icon, no floating label)
/// from a labeled form field, so reusing `CustomTextField` here would fight
/// Material 3's own search conventions rather than match them.
class VaultSearchBar extends StatelessWidget {
  const VaultSearchBar({required this.controller, required this.onChanged, super.key});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      onChanged: onChanged,
      hintText: 'Search by title or category',
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
