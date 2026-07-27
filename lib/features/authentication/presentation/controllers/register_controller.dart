import 'dart:async';

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
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(registerUseCaseProvider)(email: email, password: password),
    );
  }
}

final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, void>(RegisterController.new);
