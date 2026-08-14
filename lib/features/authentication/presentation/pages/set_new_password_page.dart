import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/validation_constants.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/auth_exception.dart';
import '../controllers/set_new_password_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/password_text_field.dart';

/// Reached only via the password-recovery deep link (see auth_redirect.dart
/// -- the router forces this route whenever a recovery session is active).
class SetNewPasswordPage extends ConsumerStatefulWidget {
  const SetNewPasswordPage({super.key});

  @override
  ConsumerState<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends ConsumerState<SetNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(setNewPasswordControllerProvider.notifier).updatePassword(
          newPassword: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(setNewPasswordControllerProvider);

    ref.listen(setNewPasswordControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        final message = error is AuthException ? error.message : AppStrings.genericErrorMessage;
        Helpers.showSnackBar(context, message);
      }
    });

    return AuthPageScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set a new password',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a new password for your account',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            PasswordTextField(
              label: 'New Password',
              controller: _passwordController,
              validator: (value) => Validators.minLength(
                value,
                ValidationConstants.minPasswordLength,
                fieldName: 'Password',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordTextField(
              label: 'Confirm New Password',
              controller: _confirmPasswordController,
              validator: (value) => Validators.match(
                value,
                _passwordController.text,
                message: 'Passwords do not match',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Set New Password',
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
