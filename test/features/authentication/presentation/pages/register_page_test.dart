import 'package:digital_vault/features/authentication/presentation/pages/register_page.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() => fakeRepository = FakeAuthRepository());
  tearDown(() => fakeRepository.dispose());

  Future<void> pumpRegisterPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const MaterialApp(home: RegisterPage()),
      ),
    );
  }

  testWidgets('submitting empty fields shows validation errors and does not call the repository',
      (tester) async {
    await pumpRegisterPage(tester);

    await tester.tap(find.text('Register'));
    await tester.pump();

    expect(find.text('Full Name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    // An empty password fails the required check inside minLength before
    // the length check ever runs — see the dedicated "too short" test below
    // for the minLength message itself.
    expect(find.text('Password is required'), findsOneWidget);
    expect(fakeRepository.registerCallCount, 0);
  });

  testWidgets('a non-empty password under the minimum length is rejected', (tester) async {
    await pumpRegisterPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Jane Doe');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'short');
    await tester.tap(find.text('Register'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(fakeRepository.registerCallCount, 0);
  });

  testWidgets('mismatched passwords are rejected', (tester) async {
    await pumpRegisterPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Jane Doe');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'somethingElse123',
    );
    await tester.tap(find.text('Register'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(fakeRepository.registerCallCount, 0);
  });

  testWidgets('a valid submission calls through with only email/password, never the name',
      (tester) async {
    await pumpRegisterPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Jane Doe');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'password123',
    );
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(fakeRepository.registerCallCount, 1);
    expect(fakeRepository.lastEmail, 'jane@example.com');
    expect(fakeRepository.lastPassword, 'password123');
  });
}
