import 'dart:async';

import 'package:digital_vault/features/authentication/presentation/controllers/logout_controller.dart';
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

  test('logout transitions loading -> data and calls through once', () async {
    final states = <AsyncValue<void>>[];
    container.listen(logoutControllerProvider, (previous, next) => states.add(next),
        fireImmediately: true);

    await container.read(logoutControllerProvider.notifier).logout();

    expect(states.map((s) => s.isLoading).toList(), [false, true, false]);
    expect(fakeRepository.logoutCallCount, 1);
  });

  test('a second concurrent call while one is in flight is ignored', () async {
    fakeRepository.pendingGate = Completer<void>();
    final notifier = container.read(logoutControllerProvider.notifier);

    final first = notifier.logout();
    final second = notifier.logout();

    fakeRepository.pendingGate!.complete();
    await Future.wait([first, second]);

    expect(fakeRepository.logoutCallCount, 1);
  });
}
