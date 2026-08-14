import 'package:digital_vault/app/router/auth_redirect.dart';
import 'package:digital_vault/app/router/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeAuthRedirect while resolving initial auth state', () {
    test('stays on splash', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: false,
          isResolving: true,
          isPasswordRecovery: false,
          hasRecoveryFailure: false,
          matchedLocation: RoutePaths.splash,
        ),
        isNull,
      );
    });

    test('is sent back to splash from any other route', () {
      for (final location in [RoutePaths.login, RoutePaths.dashboard, RoutePaths.register]) {
        expect(
          computeAuthRedirect(
            isLoggedIn: false,
            isResolving: true,
            isPasswordRecovery: false,
            hasRecoveryFailure: false,
            matchedLocation: location,
          ),
          RoutePaths.splash,
        );
      }
    });
  });

  group('computeAuthRedirect when logged out', () {
    test('public routes are left alone', () {
      for (final location in [RoutePaths.login, RoutePaths.register, RoutePaths.forgotPassword]) {
        expect(
          computeAuthRedirect(
            isLoggedIn: false,
            isResolving: false,
            isPasswordRecovery: false,
            hasRecoveryFailure: false,
            matchedLocation: location,
          ),
          isNull,
        );
      }
    });

    test('splash and every protected route redirect to login', () {
      for (final location in [
        RoutePaths.splash,
        RoutePaths.dashboard,
        RoutePaths.profile,
        RoutePaths.settings,
        RoutePaths.reminder,
        RoutePaths.smartVault,
      ]) {
        expect(
          computeAuthRedirect(
            isLoggedIn: false,
            isResolving: false,
            isPasswordRecovery: false,
            hasRecoveryFailure: false,
            matchedLocation: location,
          ),
          RoutePaths.login,
        );
      }
    });

    test('reset-password reached without a recovery session redirects to login', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: false,
          isResolving: false,
          isPasswordRecovery: false,
          hasRecoveryFailure: false,
          matchedLocation: RoutePaths.resetPassword,
        ),
        RoutePaths.login,
      );
    });

    test('recovery-error reached without an active failure redirects to login', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: false,
          isResolving: false,
          isPasswordRecovery: false,
          hasRecoveryFailure: false,
          matchedLocation: RoutePaths.recoveryError,
        ),
        RoutePaths.login,
      );
    });
  });

  group('computeAuthRedirect when logged in', () {
    test('splash and auth routes redirect to dashboard', () {
      for (final location in [
        RoutePaths.splash,
        RoutePaths.login,
        RoutePaths.register,
        RoutePaths.forgotPassword,
      ]) {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            isResolving: false,
            isPasswordRecovery: false,
            hasRecoveryFailure: false,
            matchedLocation: location,
          ),
          RoutePaths.dashboard,
        );
      }
    });

    test('protected routes are left alone', () {
      for (final location in [RoutePaths.dashboard, RoutePaths.profile, RoutePaths.settings]) {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            isResolving: false,
            isPasswordRecovery: false,
            hasRecoveryFailure: false,
            matchedLocation: location,
          ),
          isNull,
        );
      }
    });

    test('reset-password reached without a recovery session redirects to dashboard', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: true,
          isResolving: false,
          isPasswordRecovery: false,
          hasRecoveryFailure: false,
          matchedLocation: RoutePaths.resetPassword,
        ),
        RoutePaths.dashboard,
      );
    });

    test('recovery-error reached without an active failure redirects to dashboard', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: true,
          isResolving: false,
          isPasswordRecovery: false,
          hasRecoveryFailure: false,
          matchedLocation: RoutePaths.recoveryError,
        ),
        RoutePaths.dashboard,
      );
    });
  });

  group('computeAuthRedirect during password recovery', () {
    test('forces navigation to reset-password from anywhere, even though a recovery session '
        'also makes isLoggedIn true', () {
      for (final location in [
        RoutePaths.splash,
        RoutePaths.login,
        RoutePaths.dashboard,
        RoutePaths.smartVault,
      ]) {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            isResolving: false,
            isPasswordRecovery: true,
            hasRecoveryFailure: false,
            matchedLocation: location,
          ),
          RoutePaths.resetPassword,
        );
      }
    });

    test('already on reset-password, stays there', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: true,
          isResolving: false,
          isPasswordRecovery: true,
          hasRecoveryFailure: false,
          matchedLocation: RoutePaths.resetPassword,
        ),
        isNull,
      );
    });

    test('takes priority over the resolving check once resolved', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: true,
          isResolving: false,
          isPasswordRecovery: true,
          hasRecoveryFailure: false,
          matchedLocation: RoutePaths.login,
        ),
        RoutePaths.resetPassword,
      );
    });
  });

  group('computeAuthRedirect on a recovery failure (expired/already-used/invalid link)', () {
    test('forces navigation to recovery-error from anywhere -- never to login', () {
      for (final location in [
        RoutePaths.splash,
        RoutePaths.login,
        RoutePaths.dashboard,
        RoutePaths.smartVault,
        RoutePaths.resetPassword,
      ]) {
        expect(
          computeAuthRedirect(
            isLoggedIn: false,
            isResolving: false,
            isPasswordRecovery: false,
            hasRecoveryFailure: true,
            matchedLocation: location,
          ),
          RoutePaths.recoveryError,
        );
      }
    });

    test('takes priority even when isLoggedIn is somehow also true', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: true,
          isResolving: false,
          isPasswordRecovery: false,
          hasRecoveryFailure: true,
          matchedLocation: RoutePaths.dashboard,
        ),
        RoutePaths.recoveryError,
      );
    });

    test('takes priority over isPasswordRecovery (mutually exclusive in practice, but defined '
        'here for robustness)', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: true,
          isResolving: false,
          isPasswordRecovery: true,
          hasRecoveryFailure: true,
          matchedLocation: RoutePaths.login,
        ),
        RoutePaths.recoveryError,
      );
    });

    test('already on recovery-error, stays there', () {
      expect(
        computeAuthRedirect(
          isLoggedIn: false,
          isResolving: false,
          isPasswordRecovery: false,
          hasRecoveryFailure: true,
          matchedLocation: RoutePaths.recoveryError,
        ),
        isNull,
      );
    });
  });
}
