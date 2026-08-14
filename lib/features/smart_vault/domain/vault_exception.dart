import '../../../core/errors/app_exception.dart';

/// Thrown by the data layer after translating a Postgres/Storage error (or
/// a "not signed in" precondition) into a user-friendly message. Mirrors
/// `AuthException` from the authentication feature exactly.
///
/// Technically a domain-layer file even though Step 3 is scoped to the data
/// layer — the same situation `AuthException` was in: something thrown by
/// `data/` and caught by a future `presentation/` layer has to live where
/// neither depends on the other. Flagging this rather than adding it
/// silently.
class VaultException extends AppException {
  const VaultException(super.message);
}
