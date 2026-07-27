import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_vault/app/app.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';

import 'features/authentication/helpers/fake_auth_repository.dart';

void main() {
  testWidgets('App starts on the splash screen while auth state resolves', (
    WidgetTester tester,
  ) async {
    final fakeRepository = FakeAuthRepository();
    addTearDown(fakeRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const DigitalVaultApp(),
      ),
    );

    expect(find.text('Digital Vault'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
  });
}
