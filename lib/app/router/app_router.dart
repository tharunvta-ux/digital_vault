import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reminder/presentation/pages/reminder_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/smart_vault/presentation/pages/smart_vault_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'auth_redirect.dart';
import 'route_paths.dart';

/// Exposes the app's [GoRouter] instance so it can be read/overridden
/// through Riverpod like the rest of the app's dependencies.
///
/// The [GoRouter] itself is built exactly once — its `redirect` callback
/// re-runs on every navigation *and* whenever [refreshListenable] fires, so
/// auth state changes (login/logout) drive navigation without ever
/// recreating the router (which would lose navigation state).
final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.listen(authStateChangesProvider, (previous, next) => refreshListenable.value++);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      return computeAuthRedirect(
        isLoggedIn: authState.valueOrNull != null,
        isResolving: authState.isLoading && !authState.hasValue,
        matchedLocation: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
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
