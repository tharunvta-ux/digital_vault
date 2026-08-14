import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';

/// A tappable section header for the Reminder List Screen's grouped
/// display -- title, a count badge, and an expand/collapse chevron. Purely
/// presentational: which sections are collapsed lives in the list screen's
/// own local state, not here.
class ReminderSectionHeader extends StatelessWidget {
  const ReminderSectionHeader({
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onTap,
    super.key,
  });

  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count', style: theme.textTheme.labelSmall),
            ),
            const Spacer(),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }
}
