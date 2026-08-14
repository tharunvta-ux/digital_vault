import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/recovery_failure_reason.dart';
import '../widgets/auth_page_scaffold.dart';

/// Generic, reusable "the recovery link didn't work" screen -- reused for
/// every failure reason via [RecoveryErrorPage.forReason] rather than
/// having one bespoke page per reason.
class RecoveryErrorPage extends StatelessWidget {
  const RecoveryErrorPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonText,
    required this.onPressed,
    super.key,
  });

  /// Fills in title/description/icon for a known [RecoveryFailureReason],
  /// leaving only navigation (`onPressed`) to the caller -- see
  /// app_router.dart for where that's wired to "clear the failure, go to
  /// Forgot Password."
  factory RecoveryErrorPage.forReason(
    RecoveryFailureReason reason, {
    required VoidCallback onPressed,
    Key? key,
  }) {
    final content = switch (reason) {
      RecoveryFailureReason.expired => (
          title: 'Password Reset Link Expired',
          description: 'This password reset link has expired.\n\nPlease request a new password reset email.',
          icon: Icons.timer_off_outlined,
        ),
      RecoveryFailureReason.alreadyUsed => (
          title: 'Password Reset Link Already Used',
          description: 'This password reset link has already been used.\n\n'
              'For your security, password reset links can only be used once.\n\n'
              'Please request a new password reset email.',
          icon: Icons.link_off,
        ),
      RecoveryFailureReason.unknown => (
          title: 'Unable to Verify Link',
          description: 'Unable to verify password reset link.\n\nPlease request a new one.',
          icon: Icons.error_outline,
        ),
    };
    return RecoveryErrorPage(
      title: content.title,
      description: content.description,
      icon: content.icon,
      buttonText: 'Request New Link',
      onPressed: onPressed,
      key: key,
    );
  }

  final String title;
  final String description;
  final IconData icon;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: buttonText, onPressed: onPressed),
        ],
      ),
    );
  }
}
