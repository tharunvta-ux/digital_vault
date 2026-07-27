import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Orchestrates a single password-reset-email request. Unlike login/register,
/// success here does not change auth state, so the page must react to
/// success itself (e.g. a confirmation snackbar) rather than relying on
/// router redirects.
class ForgotPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> sendResetEmail({required String email}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(sendPasswordResetUseCaseProvider)(email: email),
    );
  }
}

final forgotPasswordControllerProvider = AsyncNotifierProvider.autoDispose<
    ForgotPasswordController, void>(ForgotPasswordController.new);
