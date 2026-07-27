import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/firebase_auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/watch_auth_state_changes_usecase.dart';

/// Dependency-injection graph for the authentication feature, wired entirely
/// through hand-written Riverpod providers (matching the rest of the app —
/// no codegen). Each provider depends only on the one above it, so swapping
/// [authRepositoryProvider] (e.g. with a fake in tests) reconfigures
/// everything downstream automatically.
final firebaseAuthInstanceProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return FirebaseAuthRemoteDataSource(ref.watch(firebaseAuthInstanceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>((ref) {
  return SendPasswordResetUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final watchAuthStateChangesUseCaseProvider = Provider<WatchAuthStateChangesUseCase>((ref) {
  return WatchAuthStateChangesUseCase(ref.watch(authRepositoryProvider));
});

/// The single source of truth for "is the user logged in" — drives both
/// router redirects and persistent login.
final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(watchAuthStateChangesUseCaseProvider)();
});
