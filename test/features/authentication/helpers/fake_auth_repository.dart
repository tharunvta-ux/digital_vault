import 'dart:async';

import 'package:digital_vault/features/authentication/domain/entities/user_entity.dart';
import 'package:digital_vault/features/authentication/domain/repositories/auth_repository.dart';

/// Hand-written test double — no mocking library needed since
/// [AuthRepository] only ever traffics in our own domain types.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({UserEntity? initialUser}) : _currentUser = initialUser;

  UserEntity? _currentUser;
  final StreamController<UserEntity?> _controller = StreamController<UserEntity?>.broadcast();

  /// Set to make the next call throw; automatically reset after it fires.
  Exception? failureToThrow;

  int loginCallCount = 0;
  int registerCallCount = 0;
  int sendPasswordResetEmailCallCount = 0;
  int logoutCallCount = 0;

  /// Arguments from the most recent call, for tests that assert a page
  /// wired its form fields through to the right method correctly.
  String? lastEmail;
  String? lastPassword;

  /// When set, calls await this completer before resolving — lets a test
  /// hold a call "in flight" to assert loading state, then let it finish.
  Completer<void>? pendingGate;

  @override
  Stream<UserEntity?> authStateChanges() async* {
    // Mirrors real Firebase behavior: a new subscriber immediately gets the
    // current session, then subsequent changes.
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    loginCallCount++;
    lastEmail = email;
    lastPassword = password;
    await _maybeAwaitGate();
    _maybeThrow();
    final user = UserEntity(uid: 'uid-$email', email: email);
    _emit(user);
    return user;
  }

  @override
  Future<UserEntity> register({required String email, required String password}) async {
    registerCallCount++;
    lastEmail = email;
    lastPassword = password;
    await _maybeAwaitGate();
    _maybeThrow();
    final user = UserEntity(uid: 'uid-$email', email: email);
    _emit(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    sendPasswordResetEmailCallCount++;
    lastEmail = email;
    await _maybeAwaitGate();
    _maybeThrow();
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    await _maybeAwaitGate();
    _maybeThrow();
    _emit(null);
  }

  void _emit(UserEntity? user) {
    _currentUser = user;
    _controller.add(user);
  }

  void _maybeThrow() {
    final error = failureToThrow;
    if (error != null) {
      failureToThrow = null;
      throw error;
    }
  }

  Future<void> _maybeAwaitGate() async {
    final gate = pendingGate;
    if (gate != null) await gate.future;
  }

  void dispose() => _controller.close();
}
