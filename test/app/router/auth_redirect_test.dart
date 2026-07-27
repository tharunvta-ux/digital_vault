import 'package:digital_vault/app/router/auth_redirect.dart';
import 'package:digital_vault/app/router/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeAuthRedirect while resolving initial auth state', () {
    test('stays on splash', () {
      expect(
        computeAuthRedirect(isLoggedIn: false, isResolving: true, matchedLocation: RoutePaths.splash),
        isNull,
      );
    });

    test('is sent back to splash from any other route', () {
      for (final location in [RoutePaths.login, RoutePaths.dashboard, RoutePaths.register]) {
        expect(
          computeAuthRedirect(isLoggedIn: false, isResolving: true, matchedLocation: location),
          RoutePaths.splash,
        );
      }
    });
  });

  group('computeAuthRedirect when logged out', () {
    test('public routes are left alone', () {
      for (final location in [RoutePaths.login, RoutePaths.register, RoutePaths.forgotPassword]) {
        expect(
          computeAuthRedirect(isLoggedIn: false, isResolving: false, matchedLocation: location),
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
          computeAuthRedirect(isLoggedIn: false, isResolving: false, matchedLocation: location),
          RoutePaths.login,
        );
      }
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
          computeAuthRedirect(isLoggedIn: true, isResolving: false, matchedLocation: location),
          RoutePaths.dashboard,
        );
      }
    });

    test('protected routes are left alone', () {
      for (final location in [RoutePaths.dashboard, RoutePaths.profile, RoutePaths.settings]) {
        expect(
          computeAuthRedirect(isLoggedIn: true, isResolving: false, matchedLocation: location),
          isNull,
        );
      }
    });
  });
}
