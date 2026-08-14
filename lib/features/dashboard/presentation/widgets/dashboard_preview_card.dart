import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';

/// Shared `Card` + bold section-header wrapper for dashboard preview
/// sections (Recent Vault Items, Reminder Overview). Keeps card chrome and
/// the section title in one place instead of duplicating it per section.
class DashboardPreviewCard extends StatelessWidget {
  const DashboardPreviewCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}
