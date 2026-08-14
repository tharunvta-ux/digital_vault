import 'package:digital_vault/features/authentication/domain/entities/user_entity.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:digital_vault/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../authentication/helpers/fake_auth_repository.dart';

void main() {
  group('welcomeNameProvider', () {
    Future<String?> nameFor(UserEntity? user) async {
      final fakeRepository = FakeAuthRepository(initialUser: user);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRepository.dispose);

      // authStateChangesProvider is a StreamProvider; let its first (replayed
      // current-user) event land before reading the derived value.
      await container.read(authStateChangesProvider.future);
      return container.read(welcomeNameProvider);
    }

    test('splits a dotted local part into title-cased words', () async {
      final name = await nameFor(const UserEntity(uid: 'uid-1', email: 'jane.doe@example.com'));
      expect(name, 'Jane Doe');
    });

    test('title-cases a single-word local part', () async {
      final name = await nameFor(const UserEntity(uid: 'uid-2', email: 'bob@example.com'));
      expect(name, 'Bob');
    });

    test('splits on underscores and hyphens too', () async {
      final name = await nameFor(const UserEntity(uid: 'uid-3', email: 'mary-anne_smith@example.com'));
      expect(name, 'Mary Anne Smith');
    });

    test('returns null when logged out', () async {
      final name = await nameFor(null);
      expect(name, isNull);
    });
  });

  group('dashboardStatsProvider', () {
    test('returns exactly the four expected placeholder stats', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stats = container.read(dashboardStatsProvider);

      expect(stats.map((s) => s.label), ['Documents', 'Reminders', 'Categories', 'Storage Used']);
      expect(stats.every((s) => s.value.isNotEmpty), isTrue);
    });
  });
}
