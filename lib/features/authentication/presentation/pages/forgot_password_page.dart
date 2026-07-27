import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/auth_exception.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_page_scaffold.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetEmail(email: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resetState = ref.watch(forgotPasswordControllerProvider);

    // Nothing redirects this page away automatically (unlike login/register,
    // a password-reset email doesn't change auth state), so both outcomes
    // are surfaced here directly.
    ref.listen(forgotPasswordControllerProvider, (previous, next) {
      if (previous?.isLoading != true) return;
      final error = next.error;
      if (error != null) {
        final message = error is AuthException ? error.message : AppStrings.genericErrorMessage;
        Helpers.showSnackBar(context, message);
      } else if (next.hasValue) {
        Helpers.showSnackBar(
          context,
          'If an account exists for that email, a reset link has been sent.',
        );
      }
    });

    return AuthPageScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset your password',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Enter your email and we'll send you a reset link",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Reset Password',
              isLoading: resetState.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
