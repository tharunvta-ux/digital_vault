/// Generic, feature-agnostic strings reused across the app.
///
/// Feature-specific copy belongs inside that feature's own files, not here.
class AppStrings {
  const AppStrings._();

  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
}
