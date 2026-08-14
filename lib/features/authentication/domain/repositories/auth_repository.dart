import '../entities/user_entity.dart';
import '../recovery_failure_reason.dart';

/// Contract for authentication operations, implemented by the data layer
/// and depended on only through this abstraction by usecases/controllers.
///
/// No `currentUser` getter on purpose: every "is the user logged in" check
/// in the app goes through [authStateChanges] so there is exactly one
/// source of truth for auth state (persistent login relies on this).
abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();

  /// True while the current session is a password-recovery session -- both
  /// that and a normal login produce a non-null session, so this can't be
  /// derived from [authStateChanges] alone.
  Stream<bool> passwordRecoveryEvents();

  /// Emits the reason whenever a recovery-link exchange fails (an expired
  /// or already-used link). `null` is never emitted by this stream itself
  /// -- a prior failure is only ever cleared explicitly by the presentation
  /// layer (see the "Request New Link" flow), not by a later, unrelated
  /// auth event superseding it.
  Stream<RecoveryFailureReason> recoveryFailureEvents();

  Future<UserEntity> login({required String email, required String password});

  Future<UserEntity> register({required String email, required String password});

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> updatePassword({required String newPassword});

  Future<void> logout();
}
