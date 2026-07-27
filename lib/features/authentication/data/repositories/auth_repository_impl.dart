import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/utils/app_strings.dart';
import '../../domain/auth_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// The single place that touches [FirebaseAuthException] — every other
/// layer only ever sees [AuthException] with an already-friendly message.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<UserEntity?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map(
          (user) => user == null ? null : UserModel.fromFirebaseUser(user),
        );
  }

  @override
  Future<UserEntity> login({required String email, required String password}) {
    return _run(() async {
      final user = await _remoteDataSource.login(email: email, password: password);
      return UserModel.fromFirebaseUser(user);
    });
  }

  @override
  Future<UserEntity> register({required String email, required String password}) {
    return _run(() async {
      final user = await _remoteDataSource.register(email: email, password: password);
      return UserModel.fromFirebaseUser(user);
    });
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _run(() => _remoteDataSource.sendPasswordResetEmail(email: email));
  }

  @override
  Future<void> logout() {
    return _run(_remoteDataSource.logout);
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthErrorCode(e.code));
    } catch (_) {
      throw const AuthException(AppStrings.genericErrorMessage);
    }
  }
}

/// Pure mapping from a Firebase Auth error code to a user-friendly message.
///
/// Kept as a top-level function (rather than a private method) so it's
/// directly unit-testable with a plain string — [FirebaseAuthException]'s
/// constructor is `@protected` and cannot be instantiated from outside the
/// firebase_auth package, so tests exercise this via the code alone rather
/// than constructing a real exception.
String mapAuthErrorCode(String code) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Invalid email or password.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Password is too weak. Choose a stronger password.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'operation-not-allowed':
    case 'configuration-not-found':
      return 'Sign-in is not available right now. Please try again later.';
    default:
      return AppStrings.genericErrorMessage;
  }
}
