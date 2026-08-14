import 'package:flutter/material.dart';

import '../../../../core/utils/app_dimensions.dart';
import '../../../../core/utils/app_spacing.dart';

/// A single placeholder statistic tile (icon + value + label).
class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, required this.icon, super.key});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppDimensions.iconMd, color: colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
