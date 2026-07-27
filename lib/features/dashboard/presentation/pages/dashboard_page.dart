import 'package:flutter/material.dart';

import '../../../../core/widgets/feature_placeholder_page.dart';
import '../../../authentication/presentation/widgets/logout_icon_button.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Dashboard',
      actions: [LogoutIconButton()],
    );
  }
}
