import 'package:digital_vault/app/app.dart';
import 'package:digital_vault/features/authentication/domain/entities/user_entity.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/authentication/helpers/fake_auth_repository.dart';

void main() {
  testWidgets('cold start while logged out lands on the Login screen', (tester) async {
    final fakeRepository = FakeAuthRepository();
    addTearDown(fakeRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const DigitalVaultApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('cold start while logged in (persistent login) lands on the Dashboard screen',
      (tester) async {
    final fakeRepository = FakeAuthRepository(
      initialUser: const UserEntity(uid: 'uid-1', email: 'user@example.com'),
    );
    addTearDown(fakeRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const DigitalVaultApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('logging out from Dashboard redirects back to Login', (tester) async {
    final fakeRepository = FakeAuthRepository(
      initialUser: const UserEntity(uid: 'uid-1', email: 'user@example.com'),
    );
    addTearDown(fakeRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const DigitalVaultApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
