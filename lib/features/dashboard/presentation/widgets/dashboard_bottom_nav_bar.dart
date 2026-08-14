import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/utils/helpers.dart';

/// Bottom navigation for the dashboard. Dashboard, Vault, and Reminder are
/// real destinations; Profile doesn't exist yet and still shows
/// "Coming Soon".
class DashboardBottomNavBar extends StatelessWidget {
  const DashboardBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        // push, not go: go() replaces the current location, leaving
        // Navigator.canPop() false and no way back to Dashboard (no back
        // button, no bottom nav on either Smart Vault or Reminder itself).
        if (index == 1) {
          context.push(RoutePaths.smartVault);
        } else if (index == 2) {
          context.push(RoutePaths.reminder);
        } else if (index != 0) {
          Helpers.showSnackBar(context, 'Coming Soon');
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.lock_outline), label: 'Vault'),
        NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Reminder'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
