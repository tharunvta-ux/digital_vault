import 'package:flutter/material.dart';

import '../utils/app_spacing.dart';
import '../utils/app_strings.dart';
import 'primary_button.dart';

/// Generic error state with an optional retry action.
///
/// Named `AppErrorWidget` (not `ErrorWidget`) to avoid clashing with
/// Flutter's built-in framework error widget.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    this.message = AppStrings.genericErrorMessage,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: AppStrings.retry,
                onPressed: onRetry,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
