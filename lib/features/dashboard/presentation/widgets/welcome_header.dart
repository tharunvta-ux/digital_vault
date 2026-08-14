import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../providers/dashboard_providers.dart';

/// Greeting + a non-interactive avatar placeholder. The name is derived
/// from the user's email (see `dashboard_providers.dart`) since no
/// displayName exists yet — falls back to a bare greeting if unavailable.
class WelcomeHeader extends ConsumerWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(welcomeNameProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final greeting = name == null ? 'Welcome back' : 'Welcome back, $name';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primaryContainer,
          child: name == null
              ? Icon(Icons.person_outline, color: colorScheme.onPrimaryContainer)
              : Text(
                  name[0],
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            greeting,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
