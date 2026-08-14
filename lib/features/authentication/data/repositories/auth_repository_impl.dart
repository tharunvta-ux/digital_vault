import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/utils/app_strings.dart';
import '../../domain/auth_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/recovery_failure_reason.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// The single place that touches Supabase's `AuthException` -- every other
/// layer only ever sees the domain [AuthException] (a different class,
/// same name; the Supabase one is always referred to here via the
/// `supabase.` prefix to keep them unambiguous) with an already-friendly
/// message.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<UserEntity?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map(
          (user) => user == null ? null : UserModel.fromSupabaseUser(user),
        );
  }

  @override
  Future<UserEntity> login({required String email, required String password}) {
    return _run(() async {
      final user = await _remoteDataSource.login(email: email, password: password);
      return UserModel.fromSupabaseUser(user);
    });
  }

  @override
  Future<UserEntity> register({required String email, required String password}) {
    // TEMPORARY DEV LOGGING -- remove once the registration issue is diagnosed.
    debugPrint('[STEP 4] AuthRepositoryImpl.register -- entered');
    debugPrint('[STEP 4] email: $email');
    return _run(() async {
      debugPrint('[STEP 4] AuthRepositoryImpl.register -- calling _remoteDataSource.register()');
      final user = await _remoteDataSource.register(email: email, password: password);
      debugPrint('[STEP 4] AuthRepositoryImpl.register -- _remoteDataSource.register() returned. user.id: ${user.id}');
      return UserModel.fromSupabaseUser(user);
    });
  }

  @override
  Stream<bool> passwordRecoveryEvents() {
    return _remoteDataSource.passwordRecoveryEvents();
  }

  @override
  Stream<RecoveryFailureReason> recoveryFailureEvents() {
    return _remoteDataSource
        .recoveryFailureEvents()
        .map(mapRecoveryFailureReason)
        .where((reason) => reason != null)
        .cast<RecoveryFailureReason>();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _run(() => _remoteDataSource.sendPasswordResetEmail(email: email));
  }

  @override
  Future<void> updatePassword({required String newPassword}) {
    return _run(() => _remoteDataSource.updatePassword(newPassword: newPassword));
  }

  @override
  Future<void> logout() {
    return _run(_remoteDataSource.logout);
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on supabase.AuthException catch (e, stackTrace) {
      // TEMPORARY DEV LOGGING -- added to diagnose a Sign Up failure that
      // was being hidden behind the generic error message. Remove this
      // block and restore `throw AuthException(mapAuthErrorCode(e.code));`
      // once the real cause is confirmed.
      debugPrint('=== AUTH DEBUG: supabase.AuthException caught ===');
      debugPrint('Exception: $e');
      debugPrint('Runtime type: ${e.runtimeType}');
      debugPrint('AuthException.message: ${e.message}');
      debugPrint('AuthException.statusCode: ${e.statusCode}');
      debugPrint('Stack trace:\n$stackTrace');
      throw AuthException(e.message);
    } catch (e, stackTrace) {
      // TEMPORARY DEV LOGGING -- see note above. This branch catches
      // anything that is NOT a supabase.AuthException (e.g. a Postgres
      // trigger error, a network failure, a type error) -- exactly the
      // kind of error that was being silently flattened into the generic
      // message before.
      debugPrint('=== AUTH DEBUG: non-Supabase exception caught ===');
      debugPrint('Exception: $e');
      debugPrint('Runtime type: ${e.runtimeType}');
      debugPrint('Stack trace:\n$stackTrace');
      throw AuthException(e.toString());
    }
  }
}

/// Pure mapping from a Supabase Auth error code to a user-friendly message.
/// Codes verified against Supabase's documented list
/// (supabase.com/docs/guides/auth/debugging/error-codes), not guessed --
/// Firebase and Supabase use entirely different strings for the same
/// situations (e.g. Firebase had separate `wrong-password`/`user-not-found`
/// codes; Supabase returns a single `invalid_credentials` for both, so it
/// never reveals which one it was).
///
/// `code` is nullable here (unlike the Firebase-era version): Supabase's
/// `AuthException.code` is `String?` -- "some errors that occur before a
/// response is received will not have one present," per its own docs.
///
/// Kept as a top-level function, matching the same pattern used for
/// Smart Vault's Postgres/Storage error mapping, for consistency across the
/// codebase.
String mapAuthErrorCode(String? code) {
  switch (code) {
    case 'invalid_credentials':
    case 'user_not_found':
      return 'Invalid email or password.';
    case 'user_already_exists':
    case 'email_exists':
      return 'An account already exists with this email.';
    case 'email_address_invalid':
      return 'Enter a valid email address.';
    case 'weak_password':
      return 'Password is too weak. Choose a stronger password.';
    case 'email_not_confirmed':
      return 'Please confirm your email before signing in.';
    case 'user_banned':
      return 'This account has been disabled.';
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return 'Too many attempts. Please try again later.';
    case 'signup_disabled':
    case 'email_provider_disabled':
      return 'Sign-in is not available right now. Please try again later.';
    default:
      return AppStrings.genericErrorMessage;
  }
}

/// Pure mapping from a failed recovery-link exchange's [supabase.AuthException]
/// to a domain [RecoveryFailureReason], or `null` if this exception isn't a
/// recovery-link failure at all.
///
/// `onAuthStateChange` errors aren't exclusively about recovery links --
/// e.g. a background token-refresh failure surfaces the same way -- so this
/// only claims an exception once it matches the specific shape
/// `getSessionFromUrl` (gotrue) constructs when it finds `error`/
/// `error_code`/`error_description` in the incoming URL: `code` is always
/// the URL's `error` value (`access_denied` for an expired/used/invalid
/// recovery link, verified from gotrue's source), `statusCode` is the
/// URL's `error_code`. Anything else returns `null` rather than guessing.
///
/// `otp_expired` is Supabase's single code for both a genuinely expired
/// link and an already-consumed one -- see [RecoveryFailureReason] for why
/// [RecoveryFailureReason.alreadyUsed] isn't reachable from here yet.
RecoveryFailureReason? mapRecoveryFailureReason(supabase.AuthException? error) {
  if (error == null) return null;
  if (error.code != 'access_denied') return null;
  switch (error.statusCode) {
    case 'otp_expired':
      return RecoveryFailureReason.expired;
    default:
      return RecoveryFailureReason.unknown;
  }
}
