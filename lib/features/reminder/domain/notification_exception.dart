import '../../../core/errors/app_exception.dart';

/// Thrown by [NotificationService] after translating a plugin/platform
/// failure (initialization, permission, scheduling, or cancellation) into a
/// user-friendly message. Mirrors `ReminderException`/`VaultException`
/// exactly.
class NotificationException extends AppException {
  const NotificationException(super.message);
}
