import 'package:digital_vault/features/authentication/domain/auth_exception.dart';
import 'package:digital_vault/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() => fakeRepository = FakeAuthRepository());
  tearDown(() => fakeRepository.dispose());

  Future<void> pumpForgotPasswordPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const MaterialApp(home: ForgotPasswordPage()),
      ),
    );
  }

  testWidgets('submitting an empty email shows a validation error', (tester) async {
    await pumpForgotPasswordPage(tester);

    await tester.tap(find.text('Reset Password'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(fakeRepository.sendPasswordResetEmailCallCount, 0);
  });

  testWidgets('a valid submission shows a generic confirmation, not whether the email exists',
      (tester) async {
    await pumpForgotPasswordPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(fakeRepository.sendPasswordResetEmailCallCount, 1);
    expect(fakeRepository.lastEmail, 'user@example.com');
    expect(find.text('If an account exists for that email, a reset link has been sent.'),
        findsOneWidget);
  });

  testWidgets('a failure shows the friendly error message', (tester) async {
    fakeRepository.failureToThrow = const AuthException('Enter a valid email address.');
    await pumpForgotPasswordPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });
}
