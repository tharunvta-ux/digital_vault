import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../providers/dashboard_providers.dart';
import 'stat_card.dart';

/// Lays out the placeholder statistics in a manual row-chunked grid — for a
/// small, fixed item count this avoids GridView's aspect-ratio ceremony
/// while still giving equal-width, equal-height cards per row.
class StatisticsSection extends ConsumerWidget {
  const StatisticsSection({required this.columns, super.key});

  final int columns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final rows = <Widget>[];

    for (var i = 0; i < stats.length; i += columns) {
      final chunk = stats.skip(i).take(columns).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.md));
      rows.add(
        // IntrinsicHeight lets `stretch` give every card in the row the same
        // height without needing a bounded height from the parent — this
        // Row sits inside a scrolling body, whose height is unbounded.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < chunk.length; j++) ...[
                if (j > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child:
                      StatCard(label: chunk[j].label, value: chunk[j].value, icon: chunk[j].icon),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}
