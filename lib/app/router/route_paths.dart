/// Central registry of route paths and names used with [GoRouter].
class RoutePaths {
  const RoutePaths._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String smartVault = '/smart-vault';
  static const String reminder = '/reminder';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// Route names, used for `context.goNamed(...)` navigation.
class RouteNames {
  const RouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String dashboard = 'dashboard';
  static const String smartVault = 'smartVault';
  static const String reminder = 'reminder';
  static const String profile = 'profile';
  static const String settings = 'settings';
}
