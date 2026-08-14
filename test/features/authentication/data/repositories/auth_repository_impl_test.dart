import 'package:digital_vault/core/utils/app_strings.dart';
import 'package:digital_vault/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:digital_vault/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:digital_vault/features/authentication/domain/auth_exception.dart';
import 'package:digital_vault/features/authentication/domain/recovery_failure_reason.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Throws whatever error is given from every method, to exercise the
/// repository's error-translation branches. Unlike Firebase's
/// `FirebaseAuthException` (whose constructor was `@protected`), Supabase's
/// `AuthException` constructor is public, so this can throw a *real* one --
/// no need for the code-only workaround the Firebase-era test used.
class _ThrowingDataSource implements AuthRemoteDataSource {
  _ThrowingDataSource(this.error);
  final Object error;

  @override
  Stream<supabase.User?> authStateChanges() => Stream.value(null);

  @override
  Stream<bool> passwordRecoveryEvents() => Stream.value(false);

  @override
  Stream<supabase.AuthException?> recoveryFailureEvents() => Stream.value(null);

  @override
  Future<supabase.User> login({required String email, required String password}) => throw error;

  @override
  Future<supabase.User> register({required String email, required String password}) => throw error;

  @override
  Future<void> sendPasswordResetEmail({required String email}) => throw error;

  @override
  Future<void> updatePassword({required String newPassword}) => throw error;

  @override
  Future<void> logout() => throw error;
}

void main() {
  group('mapAuthErrorCode', () {
    test('maps invalid_credentials and user_not_found to a single friendly message', () {
      for (final code in ['invalid_credentials', 'user_not_found']) {
        expect(mapAuthErrorCode(code), 'Invalid email or password.');
      }
    });

    test('maps user_already_exists and email_exists', () {
      for (final code in ['user_already_exists', 'email_exists']) {
        expect(mapAuthErrorCode(code), contains('already exists'));
      }
    });

    test('maps email_address_invalid', () {
      expect(mapAuthErrorCode('email_address_invalid'), contains('valid email'));
    });

    test('maps weak_password', () {
      expect(mapAuthErrorCode('weak_password'), contains('weak'));
    });

    test('maps email_not_confirmed', () {
      expect(mapAuthErrorCode('email_not_confirmed'), contains('confirm'));
    });

    test('maps user_banned', () {
      expect(mapAuthErrorCode('user_banned'), contains('disabled'));
    });

    test('maps over_request_rate_limit and over_email_send_rate_limit', () {
      for (final code in ['over_request_rate_limit', 'over_email_send_rate_limit']) {
        expect(mapAuthErrorCode(code), contains('Too many attempts'));
      }
    });

    test('maps signup_disabled and email_provider_disabled', () {
      for (final code in ['signup_disabled', 'email_provider_disabled']) {
        expect(mapAuthErrorCode(code), 'Sign-in is not available right now. Please try again later.');
      }
    });

    test('unmapped codes fall back to the generic message', () {
      expect(mapAuthErrorCode('some-unmapped-code'), AppStrings.genericErrorMessage);
    });

    test('a null code (can happen before a response is received) falls back to the generic message',
        () {
      expect(mapAuthErrorCode(null), AppStrings.genericErrorMessage);
    });
  });

  group('mapRecoveryFailureReason', () {
    test('maps otp_expired to expired', () {
      expect(
        mapRecoveryFailureReason(const supabase.AuthException('Email link is invalid or has expired',
            code: 'access_denied', statusCode: 'otp_expired')),
        RecoveryFailureReason.expired,
      );
    });

    test('maps any other error_code under access_denied to unknown', () {
      expect(
        mapRecoveryFailureReason(
          const supabase.AuthException('Some other reason', code: 'access_denied', statusCode: 'some_other_code'),
        ),
        RecoveryFailureReason.unknown,
      );
    });

    test('returns null for an AuthException that is not access_denied (not a recovery-link failure)', () {
      expect(
        mapRecoveryFailureReason(
          const supabase.AuthException('Invalid login credentials', code: 'invalid_credentials'),
        ),
        isNull,
      );
    });

    test('returns null for a null exception', () {
      expect(mapRecoveryFailureReason(null), isNull);
    });
  });

  group('AuthRepositoryImpl', () {
    test('translates a real Supabase AuthException using its code', () async {
      final repository = AuthRepositoryImpl(
        _ThrowingDataSource(const supabase.AuthException('Invalid login credentials', code: 'invalid_credentials')),
      );

      await expectLater(
        () => repository.login(email: 'a@b.com', password: 'wrong'),
        throwsA(
          isA<AuthException>().having((e) => e.message, 'message', 'Invalid email or password.'),
        ),
      );
    });

    test('never leaks a raw, non-Supabase error message to callers', () async {
      final repository = AuthRepositoryImpl(_ThrowingDataSource(Exception('raw platform exception')));

      await expectLater(
        () => repository.login(email: 'a@b.com', password: 'password123'),
        throwsA(
          isA<AuthException>().having((e) => e.message, 'message', AppStrings.genericErrorMessage),
        ),
      );
    });

    test('wraps failures from register/sendPasswordResetEmail/logout the same way', () async {
      final repository = AuthRepositoryImpl(_ThrowingDataSource(Exception('boom')));

      await expectLater(
        () => repository.register(email: 'a@b.com', password: 'password123'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        () => repository.sendPasswordResetEmail(email: 'a@b.com'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(() => repository.logout(), throwsA(isA<AuthException>()));
    });
  });
}
