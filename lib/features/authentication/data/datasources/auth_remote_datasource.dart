import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper contract over the Supabase Auth SDK. Returns Supabase's own
/// types (unlike the domain repository, which returns domain types) and
/// lets [AuthException] (Supabase's, not the domain one of the same name)
/// propagate uncaught — translation into a user-friendly message happens
/// one layer up, in the repository impl.
abstract class AuthRemoteDataSource {
  Stream<User?> authStateChanges();

  /// Emits `true` while the current session is a password-recovery session
  /// (the user arrived via the reset-password email link and hasn't set a
  /// new password yet), `false` otherwise. Needed because [authStateChanges]
  /// alone can't distinguish "normally logged in" from "mid password
  /// recovery" -- both have a non-null session.
  Stream<bool> passwordRecoveryEvents();

  /// Emits the [AuthException] behind a failed recovery-link exchange (an
  /// expired or already-used link, surfaced by Supabase as a stream error
  /// on `onAuthStateChange` -- see `_loggedAuthStateChange` in the Supabase
  /// implementation), or `null` for any other stream event. Kept as the raw
  /// Supabase exception here, same as every other method on this interface
  /// -- translating it into a domain [RecoveryFailureReason] happens one
  /// layer up, in the repository impl, mirroring the existing
  /// error-code-to-message mapping used for login/register failures.
  Stream<AuthException?> recoveryFailureEvents();

  Future<User> login({required String email, required String password});

  Future<User> register({required String email, required String password});

  Future<void> sendPasswordResetEmail({required String email});

  /// Only succeeds while a session is active -- in practice, called right
  /// after a password-recovery deep link has established one.
  Future<void> updatePassword({required String newPassword});

  Future<void> logout();
}
