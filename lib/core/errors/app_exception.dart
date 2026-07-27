/// Base type for app-level exceptions.
///
/// Feature modules should extend this with more specific exception types
/// as their business logic is implemented.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
