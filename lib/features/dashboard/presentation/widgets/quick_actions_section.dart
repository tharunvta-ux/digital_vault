import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/helpers.dart';

/// Quick actions. "Upload Document" now has a real destination (Smart
/// Vault); "Create Reminder" and "View Categories" don't exist yet and
/// still show "Coming Soon".
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  static const _actions = [
    (label: 'Upload Document', icon: Icons.upload_file_outlined),
    (label: 'Create Reminder', icon: Icons.add_alert_outlined),
    (label: 'View Categories', icon: Icons.category_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final action in _actions)
          OutlinedButton.icon(
            // push, not go: see DashboardBottomNavBar for why go() would
            // leave Smart Vault with no way back to Dashboard.
            onPressed: () => action.label == 'Upload Document'
                ? context.push(RoutePaths.smartVault)
                : Helpers.showSnackBar(context, 'Coming Soon'),
            icon: Icon(action.icon),
            label: Text(action.label),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
      ],
    );
  }
}
