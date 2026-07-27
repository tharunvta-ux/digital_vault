import 'dart:async';

import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:digital_vault/features/authentication/presentation/widgets/logout_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('tap calls through to logout and shows a spinner while in flight', (tester) async {
    final fakeRepository = FakeAuthRepository();
    addTearDown(fakeRepository.dispose);
    // Without a gate, the fake's async chain drains entirely within the
    // microtask queue that a single pump() already flushes, so there'd be
    // no observable "in flight" moment to assert on.
    fakeRepository.pendingGate = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const MaterialApp(
          home: Scaffold(body: LogoutIconButton()),
        ),
      ),
    );

    expect(find.byIcon(Icons.logout), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    fakeRepository.pendingGate!.complete();
    await tester.pumpAndSettle();

    expect(fakeRepository.logoutCallCount, 1);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
