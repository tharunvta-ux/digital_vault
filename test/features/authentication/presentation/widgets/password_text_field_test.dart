import 'package:digital_vault/features/authentication/presentation/widgets/password_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping the visibility icon toggles obscured text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PasswordTextField(label: 'Password')),
      ),
    );

    TextField textField() => tester.widget<TextField>(find.byType(TextField));

    expect(textField().obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(textField().obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
