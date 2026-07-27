import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../domain/auth_exception.dart';
import '../controllers/logout_controller.dart';

/// Drop-in logout action for any `AppBar.actions` list. Currently used by
/// the Dashboard placeholder so the login -> dashboard -> logout loop is
/// reachable end-to-end.
class LogoutIconButton extends ConsumerWidget {
  const LogoutIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logoutControllerProvider);

    ref.listen(logoutControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        final message = error is AuthException ? error.message : AppStrings.genericErrorMessage;
        Helpers.showSnackBar(context, message);
      }
    });

    return IconButton(
      tooltip: 'Log out',
      icon: state.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.logout),
      onPressed: state.isLoading
          ? null
          : () => ref.read(logoutControllerProvider.notifier).logout(),
    );
  }
}
