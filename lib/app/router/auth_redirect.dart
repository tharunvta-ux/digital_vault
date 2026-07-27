import 'route_paths.dart';

/// Pure auth-gate policy, kept separate from [GoRouter]/Riverpod so it can
/// be unit-tested as plain input -> output with no widget tree involved.
///
/// Splash, Login, Register, and Forgot Password are the only public routes;
/// everything else (Dashboard included) requires a logged-in user.
String? computeAuthRedirect({
  required bool isLoggedIn,
  required bool isResolving,
  required String matchedLocation,
}) {
  final isSplash = matchedLocation == RoutePaths.splash;
  final isAuthRoute = matchedLocation == RoutePaths.login ||
      matchedLocation == RoutePaths.register ||
      matchedLocation == RoutePaths.forgotPassword;

  if (isResolving) {
    return isSplash ? null : RoutePaths.splash;
  }

  if (!isLoggedIn) {
    return isAuthRoute ? null : RoutePaths.login;
  }

  return (isAuthRoute || isSplash) ? RoutePaths.dashboard : null;
}
