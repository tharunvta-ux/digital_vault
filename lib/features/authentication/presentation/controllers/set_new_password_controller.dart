import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Orchestrates a single "set new password" attempt, reached only via the
/// password-recovery deep link, and exposes its loading/error state.
///
/// No success handling needed here: a successful update flips the session's
/// event away from password-recovery, and the router's own redirect (see
/// auth_redirect.dart) sends the user to the dashboard automatically, the
/// same way a successful login/register already does.
class SetNewPasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updatePassword({required String newPassword}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(updatePasswordUseCaseProvider)(newPassword: newPassword),
    );
  }
}

final setNewPasswordControllerProvider =
    AsyncNotifierProvider.autoDispose<SetNewPasswordController, void>(SetNewPasswordController.new);
