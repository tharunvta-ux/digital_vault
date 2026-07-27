import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class LogoutController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> logout() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(logoutUseCaseProvider)());
  }
}

final logoutControllerProvider =
    AsyncNotifierProvider.autoDispose<LogoutController, void>(LogoutController.new);
