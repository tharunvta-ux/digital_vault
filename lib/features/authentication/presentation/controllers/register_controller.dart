import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Orchestrates a single registration attempt and exposes its loading/error
/// state. Note: only email/password are ever passed through — the Register
/// screen's Full Name field is UI-only and never reaches this controller.
class RegisterController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> register({required String email, required String password}) async {
    if (state.isLoading) return;
    // TEMPORARY DEV LOGGING -- remove once the registration issue is diagnosed.
    debugPrint('[STEP 2] RegisterController.register -- entered');
    debugPrint('[STEP 2] email: $email');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(registerUseCaseProvider)(email: email, password: password),
    );
    debugPrint(
      '[STEP 2] RegisterController.register -- AsyncValue.guard settled. '
      'hasError: ${state.hasError}, hasValue: ${state.hasValue}',
    );
    if (state.hasError) {
      debugPrint('[STEP 2] error: ${state.error}');
      debugPrint('[STEP 2] error runtimeType: ${state.error.runtimeType}');
      debugPrint('[STEP 2] stackTrace:\n${state.stackTrace}');
    }
  }
}

final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, void>(RegisterController.new);
