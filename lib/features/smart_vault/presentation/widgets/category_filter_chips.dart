import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../domain/entities/document_category.dart';

/// Horizontally-scrolling filter chips -- `null` selection means "All".
/// Uses `watchDocumentsByCategoryProvider`'s existing `.family` under the
/// hood via the caller; this widget only reports which category is chosen,
/// it never touches a provider itself.
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({required this.selected, required this.onSelected, super.key});

  final DocumentCategory? selected;
  final ValueChanged<DocumentCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in DocumentCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(category.label),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}
