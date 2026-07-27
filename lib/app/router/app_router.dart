import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/authentication_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reminder/presentation/pages/reminder_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/smart_vault/presentation/pages/smart_vault_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'route_paths.dart';

/// Exposes the app's [GoRouter] instance so it can be read/overridden
/// through Riverpod like the rest of the app's dependencies.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.authentication,
        name: RouteNames.authentication,
        builder: (context, state) => const AuthenticationPage(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.smartVault,
        name: RouteNames.smartVault,
        builder: (context, state) => const SmartVaultPage(),
      ),
      GoRoute(
        path: RoutePaths.reminder,
        name: RouteNames.reminder,
        builder: (context, state) => const ReminderPage(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
