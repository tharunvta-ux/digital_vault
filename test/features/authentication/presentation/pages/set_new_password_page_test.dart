import 'package:digital_vault/features/authentication/domain/auth_exception.dart';
import 'package:digital_vault/features/authentication/presentation/pages/set_new_password_page.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() => fakeRepository = FakeAuthRepository());
  tearDown(() => fakeRepository.dispose());

  Future<void> pumpSetNewPasswordPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const MaterialApp(home: SetNewPasswordPage()),
      ),
    );
  }

  testWidgets('submitting empty fields shows validation errors and does not call the repository',
      (tester) async {
    await pumpSetNewPasswordPage(tester);

    await tester.tap(find.text('Set New Password'));
    await tester.pump();

    expect(find.text('Password is required'), findsOneWidget);
    expect(fakeRepository.updatePasswordCallCount, 0);
  });

  testWidgets('mismatched passwords show an error and do not call the repository', (tester) async {
    await pumpSetNewPasswordPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'password123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'different123');
    await tester.tap(find.text('Set New Password'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(fakeRepository.updatePasswordCallCount, 0);
  });

  testWidgets('a valid submission calls updatePassword with the entered password', (tester) async {
    await pumpSetNewPasswordPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'newpassword123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'newpassword123');
    await tester.tap(find.text('Set New Password'));
    await tester.pumpAndSettle();

    expect(fakeRepository.updatePasswordCallCount, 1);
    expect(fakeRepository.lastNewPassword, 'newpassword123');
  });

  testWidgets('a failure shows the friendly error message', (tester) async {
    fakeRepository.failureToThrow = const AuthException('Password is too weak. Choose a stronger password.');
    await pumpSetNewPasswordPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'newpassword123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm New Password'), 'newpassword123');
    await tester.tap(find.text('Set New Password'));
    await tester.pumpAndSettle();

    expect(find.text('Password is too weak. Choose a stronger password.'), findsOneWidget);
  });
}
