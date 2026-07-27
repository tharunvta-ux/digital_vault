import 'dart:async';

import 'package:digital_vault/features/authentication/domain/auth_exception.dart';
import 'package:digital_vault/features/authentication/presentation/controllers/login_controller.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
  });

  tearDown(() {
    container.dispose();
    fakeRepository.dispose();
  });

  test('login success transitions loading -> data and calls through once', () async {
    final states = <AsyncValue<void>>[];
    container.listen(loginControllerProvider, (previous, next) => states.add(next),
        fireImmediately: true);

    await container
        .read(loginControllerProvider.notifier)
        .login(email: 'a@b.com', password: 'password123');

    expect(states.map((s) => s.isLoading).toList(), [false, true, false]);
    expect(states.last.hasError, isFalse);
    expect(fakeRepository.loginCallCount, 1);
  });

  test('login failure surfaces the AuthException on state', () async {
    fakeRepository.failureToThrow = const AuthException('Invalid email or password.');

    await container
        .read(loginControllerProvider.notifier)
        .login(email: 'a@b.com', password: 'wrong');

    final state = container.read(loginControllerProvider);
    expect(state.hasError, isTrue);
    expect((state.error as AuthException).message, 'Invalid email or password.');
  });

  test('a second concurrent call while one is in flight is ignored', () async {
    fakeRepository.pendingGate = Completer<void>();
    final notifier = container.read(loginControllerProvider.notifier);

    final first = notifier.login(email: 'a@b.com', password: 'password123');
    final second = notifier.login(email: 'a@b.com', password: 'password123');

    fakeRepository.pendingGate!.complete();
    await Future.wait([first, second]);

    expect(fakeRepository.loginCallCount, 1);
  });
}
