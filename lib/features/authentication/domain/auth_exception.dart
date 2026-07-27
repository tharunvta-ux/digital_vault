import '../../../core/errors/app_exception.dart';

/// Thrown by the data layer (after translating a [FirebaseAuthException] or
/// other platform failure into a user-friendly message) and caught by the
/// presentation layer. Lives directly under `domain/`, not in a subfolder,
/// since both outer layers depend on it without depending on each other.
class AuthException extends AppException {
  const AuthException(super.message);
}
