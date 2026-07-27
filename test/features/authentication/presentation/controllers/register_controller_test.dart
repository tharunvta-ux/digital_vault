import 'dart:async';

import 'package:digital_vault/features/authentication/domain/auth_exception.dart';
import 'package:digital_vault/features/authentication/presentation/controllers/register_controller.dart';
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

  test('register success transitions loading -> data and calls through once', () async {
    final states = <AsyncValue<void>>[];
    container.listen(registerControllerProvider, (previous, next) => states.add(next),
        fireImmediately: true);

    await container
        .read(registerControllerProvider.notifier)
        .register(email: 'new@user.com', password: 'password123');

    expect(states.map((s) => s.isLoading).toList(), [false, true, false]);
    expect(fakeRepository.registerCallCount, 1);
  });

  test('register failure surfaces the AuthException on state', () async {
    fakeRepository.failureToThrow = const AuthException('An account already exists with this email.');

    await container
        .read(registerControllerProvider.notifier)
        .register(email: 'dup@user.com', password: 'password123');

    final state = container.read(registerControllerProvider);
    expect(state.hasError, isTrue);
    expect((state.error as AuthException).message, 'An account already exists with this email.');
  });

  test('a second concurrent call while one is in flight is ignored', () async {
    fakeRepository.pendingGate = Completer<void>();
    final notifier = container.read(registerControllerProvider.notifier);

    final first = notifier.register(email: 'a@b.com', password: 'password123');
    final second = notifier.register(email: 'a@b.com', password: 'password123');

    fakeRepository.pendingGate!.complete();
    await Future.wait([first, second]);

    expect(fakeRepository.registerCallCount, 1);
  });
}
