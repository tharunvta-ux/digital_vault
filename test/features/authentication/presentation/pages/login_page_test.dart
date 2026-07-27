import 'dart:async';

import 'package:digital_vault/features/authentication/presentation/pages/login_page.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() => fakeRepository = FakeAuthRepository());
  tearDown(() => fakeRepository.dispose());

  Future<void> pumpLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
  }

  testWidgets('submitting empty fields shows validation errors and does not call the repository',
      (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(fakeRepository.loginCallCount, 0);
  });

  testWidgets('a malformed email shows a format error', (tester) async {
    await pumpLoginPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(fakeRepository.loginCallCount, 0);
  });

  testWidgets('a valid submission calls through with the entered credentials', (tester) async {
    await pumpLoginPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(fakeRepository.loginCallCount, 1);
    expect(fakeRepository.lastEmail, 'user@example.com');
    expect(fakeRepository.lastPassword, 'password123');
  });

  testWidgets('the submit button disables while a login request is in flight', (tester) async {
    fakeRepository.pendingGate = Completer<void>();
    await pumpLoginPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    fakeRepository.pendingGate!.complete();
    await tester.pumpAndSettle();
  });
}
