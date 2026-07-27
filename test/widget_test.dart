import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_vault/app/app.dart';

void main() {
  testWidgets('App starts on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DigitalVaultApp()),
    );

    expect(find.text('Digital Vault'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
  });
}
