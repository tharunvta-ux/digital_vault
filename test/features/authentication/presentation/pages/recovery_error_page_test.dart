import 'package:digital_vault/features/authentication/domain/recovery_failure_reason.dart';
import 'package:digital_vault/features/authentication/presentation/pages/recovery_error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the given title, description, and button text, and calls onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RecoveryErrorPage(
          title: 'Some Title',
          description: 'Some description.',
          icon: Icons.error_outline,
          buttonText: 'Do Something',
          onPressed: () => pressed = true,
        ),
      ),
    );

    expect(find.text('Some Title'), findsOneWidget);
    expect(find.text('Some description.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Do Something'), findsOneWidget);

    await tester.tap(find.text('Do Something'));
    expect(pressed, isTrue);
  });

  group('RecoveryErrorPage.forReason', () {
    testWidgets('expired -- shows the expired-link copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RecoveryErrorPage.forReason(RecoveryFailureReason.expired, onPressed: () {}),
        ),
      );

      expect(find.text('Password Reset Link Expired'), findsOneWidget);
      expect(find.textContaining('This password reset link has expired.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Request New Link'), findsOneWidget);
    });

    testWidgets('alreadyUsed -- shows the already-used-link copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RecoveryErrorPage.forReason(RecoveryFailureReason.alreadyUsed, onPressed: () {}),
        ),
      );

      expect(find.text('Password Reset Link Already Used'), findsOneWidget);
      expect(find.textContaining('This password reset link has already been used.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Request New Link'), findsOneWidget);
    });

    testWidgets('unknown -- shows the generic unable-to-verify copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RecoveryErrorPage.forReason(RecoveryFailureReason.unknown, onPressed: () {}),
        ),
      );

      expect(find.text('Unable to Verify Link'), findsOneWidget);
      expect(find.textContaining('Unable to verify password reset link.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Request New Link'), findsOneWidget);
    });

    testWidgets('calls the given onPressed callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: RecoveryErrorPage.forReason(RecoveryFailureReason.expired, onPressed: () => pressed = true),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Request New Link'));
      expect(pressed, isTrue);
    });
  });
}
