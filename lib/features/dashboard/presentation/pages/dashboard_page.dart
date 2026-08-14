import 'package:flutter/material.dart';

import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/widgets/logout_icon_button.dart';
import '../widgets/dashboard_bottom_nav_bar.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_vault_items_card.dart';
import '../widgets/reminder_overview_card.dart';
import '../widgets/statistics_section.dart';
import '../widgets/welcome_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = context.screenSize.width;
    final columns = AppBreakpoints.columnsFor(width);
    final isWideLayout = width >= AppBreakpoints.tablet;
    final horizontalPadding = AppBreakpoints.isDesktop(width) ? AppSpacing.xl : AppSpacing.md;

    final previewCards = isWideLayout
        ? const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: RecentVaultItemsCard()),
              SizedBox(width: AppSpacing.md),
              Expanded(child: ReminderOverviewCard()),
            ],
          )
        : const Column(
            children: [
              RecentVaultItemsCard(),
              SizedBox(height: AppSpacing.md),
              ReminderOverviewCard(),
            ],
          );

    return Scaffold(
      appBar: const CustomAppBar(title: 'Dashboard', actions: [LogoutIconButton()]),
      bottomNavigationBar: const DashboardBottomNavBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WelcomeHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  StatisticsSection(columns: columns),
                  const SizedBox(height: AppSpacing.lg),
                  const QuickActionsSection(),
                  const SizedBox(height: AppSpacing.lg),
                  previewCards,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
