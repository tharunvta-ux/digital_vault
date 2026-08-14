import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';
import '../state/reminder_filter.dart';

/// Horizontally-scrolling filter chips, matching `CategoryFilterChips`'
/// convention. Only ever reports which [ReminderFilter] is chosen -- the
/// caller is responsible for applying it via `buildReminderListGroups`.
class ReminderFilterChips extends StatelessWidget {
  const ReminderFilterChips({required this.selected, required this.onSelected, super.key});

  final ReminderFilter selected;
  final ValueChanged<ReminderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final filter in ReminderFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(filter.label),
                selected: selected == filter,
                onSelected: (_) => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }
}
