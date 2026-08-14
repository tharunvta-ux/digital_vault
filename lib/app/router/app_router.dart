import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/domain/recovery_failure_reason.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/recovery_error_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/set_new_password_page.dart';
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
  ref.listen(passwordRecoveryProvider, (previous, next) => refreshListenable.value++);
  ref.listen(recoveryFailureReasonProvider, (previous, next) => refreshListenable.value++);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final isPasswordRecovery = ref.read(passwordRecoveryProvider).valueOrNull ?? false;
      final recoveryFailureReason = ref.read(recoveryFailureReasonProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isResolving = authState.isLoading && !authState.hasValue;
      final target = computeAuthRedirect(
        isLoggedIn: isLoggedIn,
        isResolving: isResolving,
        isPasswordRecovery: isPasswordRecovery,
        hasRecoveryFailure: recoveryFailureReason != null,
        matchedLocation: state.matchedLocation,
      );
      // TEMPORARY DEV LOGGING -- diagnosing the password-recovery deep
      // link. Fires on every navigation, so expect noise from ordinary
      // navigation too -- what matters is what happens right after a
      // [PASSWORD RECOVERY] Incoming URI log from main.dart.
      debugPrint(
        '[ROUTER DEBUG] matchedLocation: ${state.matchedLocation}, '
        'isLoggedIn: $isLoggedIn, isResolving: $isResolving, '
        'isPasswordRecovery: $isPasswordRecovery, recoveryFailureReason: $recoveryFailureReason, '
        'Navigation target: ${target ?? "(none, stay)"}',
      );
      return target;
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
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        builder: (context, state) => const SetNewPasswordPage(),
      ),
      GoRoute(
        path: RoutePaths.recoveryError,
        name: RouteNames.recoveryError,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => RecoveryErrorPage.forReason(
            ref.watch(recoveryFailureReasonProvider) ?? RecoveryFailureReason.unknown,
            onPressed: () {
              ref.read(recoveryFailureReasonProvider.notifier).clear();
              context.go(RoutePaths.forgotPassword);
            },
          ),
        ),
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
