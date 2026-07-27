import '../entities/user_entity.dart';

/// Contract for authentication operations, implemented by the data layer
/// and depended on only through this abstraction by usecases/controllers.
///
/// No `currentUser` getter on purpose: every "is the user logged in" check
/// in the app goes through [authStateChanges] so there is exactly one
/// source of truth for auth state (persistent login relies on this).
abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();

  Future<UserEntity> login({required String email, required String password});

  Future<UserEntity> register({required String email, required String password});

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> logout();
}
