import 'dart:async';

import 'package:digital_vault/features/authentication/domain/auth_exception.dart';
import 'package:digital_vault/features/authentication/presentation/controllers/forgot_password_controller.dart';
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

  test('sendResetEmail success transitions loading -> data and calls through once', () async {
    final states = <AsyncValue<void>>[];
    container.listen(forgotPasswordControllerProvider, (previous, next) => states.add(next),
        fireImmediately: true);

    await container
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetEmail(email: 'a@b.com');

    expect(states.map((s) => s.isLoading).toList(), [false, true, false]);
    expect(fakeRepository.sendPasswordResetEmailCallCount, 1);
  });

  test('failure surfaces the AuthException on state', () async {
    fakeRepository.failureToThrow = const AuthException('Enter a valid email address.');

    await container
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetEmail(email: 'not-an-email');

    final state = container.read(forgotPasswordControllerProvider);
    expect(state.hasError, isTrue);
    expect((state.error as AuthException).message, 'Enter a valid email address.');
  });

  test('a second concurrent call while one is in flight is ignored', () async {
    fakeRepository.pendingGate = Completer<void>();
    final notifier = container.read(forgotPasswordControllerProvider.notifier);

    final first = notifier.sendResetEmail(email: 'a@b.com');
    final second = notifier.sendResetEmail(email: 'a@b.com');

    fakeRepository.pendingGate!.complete();
    await Future.wait([first, second]);

    expect(fakeRepository.sendPasswordResetEmailCallCount, 1);
  });
}
