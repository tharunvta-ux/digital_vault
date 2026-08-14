import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/validation_constants.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/auth_exception.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/password_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    // TEMPORARY DEV LOGGING -- remove once the registration issue is diagnosed.
    debugPrint('[STEP 1] RegisterPage._submit -- Register button pressed');
    debugPrint('[STEP 1] email: $email');
    ref.read(registerControllerProvider.notifier).register(
          email: email,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registerState = ref.watch(registerControllerProvider);

    ref.listen(registerControllerProvider, (previous, next) {
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
              'Create your account',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Set up your secure vault',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Full Name is UI-only: intentionally uncontrolled, and never
            // read by _submit or passed to the register controller.
            CustomTextField(
              label: 'Full Name',
              validator: (value) => Validators.required(value, fieldName: 'Full Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordTextField(
              label: 'Password',
              controller: _passwordController,
              validator: (value) => Validators.minLength(
                value,
                ValidationConstants.minPasswordLength,
                fieldName: 'Password',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordTextField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              validator: (value) => Validators.match(
                value,
                _passwordController.text,
                message: 'Passwords do not match',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Register',
              isLoading: registerState.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
