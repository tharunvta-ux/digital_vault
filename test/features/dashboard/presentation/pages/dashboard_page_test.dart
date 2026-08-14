import 'package:digital_vault/app/router/route_paths.dart';
import 'package:digital_vault/features/authentication/domain/entities/user_entity.dart';
import 'package:digital_vault/features/authentication/presentation/providers/auth_providers.dart';
import 'package:digital_vault/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:digital_vault/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:digital_vault/features/dashboard/presentation/widgets/statistics_section.dart';
import 'package:digital_vault/features/reminder/presentation/providers/reminder_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/helpers/fake_auth_repository.dart';
import '../../../reminder/helpers/fake_reminder_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;
  late FakeReminderRepository fakeReminderRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository(
      initialUser: const UserEntity(uid: 'uid-1', email: 'jane.doe@example.com'),
    );
    // The Dashboard now renders a live "Upcoming Reminders" section (Module
    // 5, Phase 6) alongside "Recent Vault Items" -- faked the same way
    // `authRepositoryProvider` is, so it exercises its real empty state
    // instead of hitting the real (here, uninitialized) Supabase client.
    fakeReminderRepository = FakeReminderRepository();
  });
  tearDown(() {
    fakeRepository.dispose();
    fakeReminderRepository.dispose();
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          reminderRepositoryProvider.overrideWithValue(fakeReminderRepository),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Only the navigation tests need a real GoRouter (for context.push to
  // resolve) -- the Smart Vault/Reminder routes point at minimal marker
  // widgets, not the real pages, since fully rendering those modules' own
  // provider graphs is their own tests' responsibility, not this
  // Dashboard test's.
  Future<void> pumpDashboardWithRouter(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.dashboard,
      routes: [
        GoRoute(path: RoutePaths.dashboard, builder: (context, state) => const DashboardPage()),
        GoRoute(
          path: RoutePaths.smartVault,
          builder: (context, state) => const Scaffold(body: Center(child: Text('Smart Vault Route'))),
        ),
        GoRoute(
          path: RoutePaths.reminder,
          builder: (context, state) => const Scaffold(body: Center(child: Text('Reminder Route'))),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          reminderRepositoryProvider.overrideWithValue(fakeReminderRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a welcome greeting derived from the user email', (tester) async {
    await pumpDashboard(tester);

    expect(find.text('Welcome back, Jane Doe'), findsOneWidget);
  });

  testWidgets('shows all four placeholder statistics', (tester) async {
    await pumpDashboard(tester);

    expect(find.byType(StatCard), findsNWidgets(4));
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Storage Used'), findsOneWidget);
  });

  testWidgets('tapping the Upload Document quick action navigates to Smart Vault', (tester) async {
    await pumpDashboardWithRouter(tester);

    await tester.tap(find.text('Upload Document'));
    await tester.pumpAndSettle();

    expect(find.text('Smart Vault Route'), findsOneWidget);
  });

  testWidgets('tapping a still-unbuilt quick action shows Coming Soon and triggers no side effects',
      (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Create Reminder'));
    await tester.pump();

    expect(find.text('Coming Soon'), findsOneWidget);
    expect(fakeRepository.logoutCallCount, 0);
  });

  testWidgets(
      'shows the Recent Vault Items placeholder and the live, empty Upcoming Reminders section',
      (tester) async {
    await pumpDashboard(tester);

    expect(find.text('Recent Vault Items'), findsOneWidget);
    expect(find.text('No recent documents.'), findsOneWidget);
    expect(find.text('Upcoming Reminders'), findsOneWidget);
    expect(find.text('No upcoming reminders.'), findsOneWidget);
  });

  testWidgets('bottom nav shows all four tabs with Dashboard selected', (tester) async {
    await pumpDashboard(tester);

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0);
    expect(navBar.destinations.length, 4);
    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('Reminder'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('tapping the Vault tab navigates to Smart Vault', (tester) async {
    await pumpDashboardWithRouter(tester);

    await tester.tap(find.text('Vault'));
    await tester.pumpAndSettle();

    expect(find.text('Smart Vault Route'), findsOneWidget);
  });

  testWidgets('tapping the Reminder tab navigates to the Reminder screen', (tester) async {
    await pumpDashboardWithRouter(tester);

    await tester.tap(find.text('Reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Reminder Route'), findsOneWidget);
  });

  testWidgets('tapping a still-unbuilt tab shows Coming Soon without navigating', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(find.text('Coming Soon'), findsOneWidget);
    // Still on the dashboard content -- nothing was pushed/replaced.
    expect(find.text('Welcome back, Jane Doe'), findsOneWidget);
  });

  testWidgets('passes a wider column count to StatisticsSection on tablet-width screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpDashboard(tester);
    expect(tester.widget<StatisticsSection>(find.byType(StatisticsSection)).columns, 2);

    tester.view.physicalSize = const Size(700, 800);
    await tester.pumpAndSettle();

    expect(tester.widget<StatisticsSection>(find.byType(StatisticsSection)).columns, 4);
  });
}
