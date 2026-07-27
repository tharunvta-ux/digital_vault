import 'package:digital_vault/core/utils/app_strings.dart';
import 'package:digital_vault/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:digital_vault/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:digital_vault/features/authentication/domain/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Throws a plain (non-Firebase) error from every method, to exercise the
/// repository's generic catch-all fallback. `FirebaseAuthException` itself
/// has a `@protected` constructor and can't be built from test code, so the
/// FirebaseAuthException -> friendly-message branch is covered instead via
/// [mapAuthErrorCode] directly (see below) plus the live Firebase smoke test.
class _ThrowingDataSource implements AuthRemoteDataSource {
  _ThrowingDataSource(this.error);
  final Object error;

  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  Future<User> login({required String email, required String password}) => throw error;

  @override
  Future<User> register({required String email, required String password}) => throw error;

  @override
  Future<void> sendPasswordResetEmail({required String email}) => throw error;

  @override
  Future<void> logout() => throw error;
}

void main() {
  group('mapAuthErrorCode', () {
    test('maps credential-related codes to a single friendly message', () {
      for (final code in ['user-not-found', 'wrong-password', 'invalid-credential']) {
        expect(mapAuthErrorCode(code), 'Invalid email or password.');
      }
    });

    test('maps email-already-in-use', () {
      expect(mapAuthErrorCode('email-already-in-use'), contains('already exists'));
    });

    test('maps invalid-email', () {
      expect(mapAuthErrorCode('invalid-email'), contains('valid email'));
    });

    test('maps weak-password', () {
      expect(mapAuthErrorCode('weak-password'), contains('weak'));
    });

    test('maps network-request-failed', () {
      expect(mapAuthErrorCode('network-request-failed'), contains('Network'));
    });

    test('maps user-disabled', () {
      expect(mapAuthErrorCode('user-disabled'), contains('disabled'));
    });

    test('maps too-many-requests', () {
      expect(mapAuthErrorCode('too-many-requests'), contains('Too many attempts'));
    });

    test('maps operation-not-allowed and configuration-not-found (sign-in method disabled '
        'or Authentication not yet set up in the Firebase console)', () {
      for (final code in ['operation-not-allowed', 'configuration-not-found']) {
        expect(mapAuthErrorCode(code), 'Sign-in is not available right now. Please try again later.');
      }
    });

    test('unmapped codes fall back to the generic message', () {
      expect(mapAuthErrorCode('some-unmapped-code'), AppStrings.genericErrorMessage);
    });
  });

  group('AuthRepositoryImpl', () {
    test('never leaks a raw, non-Firebase error message to callers', () async {
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
