import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper contract over the Firebase Auth SDK. Returns Firebase's own
/// types (unlike the domain repository, which returns domain types) and
/// lets [FirebaseAuthException] propagate uncaught — translation into a
/// user-friendly message happens one layer up, in the repository impl.
abstract class AuthRemoteDataSource {
  Stream<User?> authStateChanges();

  Future<User> login({required String email, required String password});

  Future<User> register({required String email, required String password});

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> logout();
}
