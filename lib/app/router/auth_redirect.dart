import 'route_paths.dart';

/// Pure auth-gate policy, kept separate from [GoRouter]/Riverpod so it can
/// be unit-tested as plain input -> output with no widget tree involved.
///
/// Splash, Login, Register, and Forgot Password are the only public routes;
/// everything else (Dashboard included) requires a logged-in user.
///
/// Reset Password is a third category, neither public nor normally
/// protected: it's only reachable while [isPasswordRecovery] is true (the
/// user arrived via the reset-email deep link), which forces navigation
/// there from anywhere -- even though a recovery session also makes
/// [isLoggedIn] true, it must not be treated as a normal login. Reached any
/// other way (stale link, direct navigation), it falls back to whatever the
/// normal logged-in/logged-out rule would have done.
///
/// Recovery Error is a fourth category, checked with the highest priority
/// of all (even above [isPasswordRecovery]): whenever [hasRecoveryFailure]
/// is true, the user is sent there from anywhere and stays there,
/// regardless of what [isLoggedIn]/[isPasswordRecovery] say -- an expired
/// or already-used recovery link must never fall through to the ordinary
/// Login screen. It's only left by an explicit action (the "Request New
/// Link" button clearing the failure before navigating), not by any
/// redirect-priority rule here.
String? computeAuthRedirect({
  required bool isLoggedIn,
  required bool isResolving,
  required bool isPasswordRecovery,
  required bool hasRecoveryFailure,
  required String matchedLocation,
}) {
  final isSplash = matchedLocation == RoutePaths.splash;
  final isAuthRoute = matchedLocation == RoutePaths.login ||
      matchedLocation == RoutePaths.register ||
      matchedLocation == RoutePaths.forgotPassword;
  final isResetPasswordRoute = matchedLocation == RoutePaths.resetPassword;
  final isRecoveryErrorRoute = matchedLocation == RoutePaths.recoveryError;

  if (isResolving) {
    return isSplash ? null : RoutePaths.splash;
  }

  if (hasRecoveryFailure) {
    return isRecoveryErrorRoute ? null : RoutePaths.recoveryError;
  }

  if (isPasswordRecovery) {
    return isResetPasswordRoute ? null : RoutePaths.resetPassword;
  }

  if (isResetPasswordRoute || isRecoveryErrorRoute) {
    // Reached without an active recovery session/failure (e.g. the failure
    // was already cleared via "Request New Link", or a stale/direct
    // navigation) -- treat like any other protected/auth state.
    return isLoggedIn ? RoutePaths.dashboard : RoutePaths.login;
  }

  if (!isLoggedIn) {
    return isAuthRoute ? null : RoutePaths.login;
  }

  return (isAuthRoute || isSplash) ? RoutePaths.dashboard : null;
}
