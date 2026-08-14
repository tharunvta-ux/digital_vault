import 'package:digital_vault/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:digital_vault/features/dashboard/presentation/widgets/statistics_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSection(WidgetTester tester, int columns) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: StatisticsSection(columns: columns)),
        ),
      ),
    );
  }

  testWidgets('renders all four placeholder stats', (tester) async {
    await pumpSection(tester, 2);

    expect(find.byType(StatCard), findsNWidgets(4));
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Storage Used'), findsOneWidget);
  });

  testWidgets('2 columns lays the four stats out across two rows of two', (tester) async {
    await pumpSection(tester, 2);

    // StatCard itself contains no Row, so every Row in this tree is one of
    // StatisticsSection's own chunk rows.
    expect(find.byType(Row), findsNWidgets(2));
    for (final rowFinder in find.byType(Row).evaluate()) {
      final row = rowFinder.widget as Row;
      expect(row.children.whereType<Expanded>().length, 2);
    }
  });

  testWidgets('4 columns lays all four stats out in a single row', (tester) async {
    await pumpSection(tester, 4);

    expect(find.byType(Row), findsNWidgets(1));
    final row = tester.widget<Row>(find.byType(Row));
    expect(row.children.whereType<Expanded>().length, 4);
  });
}
