import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_widget.dart';
import 'dashboard_preview_card.dart';

class RecentVaultItemsCard extends StatelessWidget {
  const RecentVaultItemsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardPreviewCard(
      title: 'Recent Vault Items',
      child: EmptyStateWidget(
        title: 'No recent documents.',
        icon: Icons.description_outlined,
      ),
    );
  }
}
