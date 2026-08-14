import '../../../core/errors/app_exception.dart';

/// Thrown by the data layer after translating a Postgres error (or a
/// "not signed in" precondition) into a user-friendly message. Mirrors
/// `VaultException` from the Smart Vault feature exactly.
class ReminderException extends AppException {
  const ReminderException(super.message);
}
