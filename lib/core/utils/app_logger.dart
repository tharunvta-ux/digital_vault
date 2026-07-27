import 'dart:developer' as developer;

/// Thin wrapper around `dart:developer` logging so call sites don't reach
/// for `print` and log output stays filterable by name/level.
class AppLogger {
  const AppLogger._();

  static void debug(String message) => _log(message, level: 500);

  static void info(String message) => _log(message, level: 800);

  static void warning(String message) => _log(message, level: 900);

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'DigitalVault',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(String message, {required int level}) {
    developer.log(message, name: 'DigitalVault', level: level);
  }
}
