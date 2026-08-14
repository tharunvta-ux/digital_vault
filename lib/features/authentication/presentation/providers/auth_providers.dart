import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/supabase_auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/recovery_failure_reason.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/update_password_usecase.dart';
import '../../domain/usecases/watch_auth_state_changes_usecase.dart';
import '../../domain/usecases/watch_password_recovery_usecase.dart';
import '../../domain/usecases/watch_recovery_failure_usecase.dart';

/// Dependency-injection graph for the authentication feature, wired entirely
/// through hand-written Riverpod providers (matching the rest of the app —
/// no codegen). Each provider depends only on the one above it, so swapping
/// [authRepositoryProvider] (e.g. with a fake in tests) reconfigures
/// everything downstream automatically.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = Supabase.instance.client;
  // TEMPORARY DEV LOGGING -- remove once the registration issue is
  // diagnosed. This fires once, whenever this provider is first resolved
  // (in practice, at app startup, since authStateChangesProvider is watched
  // by the router from the first frame) -- NOT on every Register press,
  // because this provider is not `.autoDispose` and Riverpod caches its
  // result. It only confirms the DI graph reaches a live client instance.
  debugPrint('[PROVIDER] supabaseClientProvider resolved -- client hashCode: ${client.hashCode}');
  return client;
});

/// The one line that actually switches which backend authentication runs
/// against. Everything below this, all the way through every controller
/// and every page, depends only on the [AuthRepository]/[AuthRemoteDataSource]
/// interfaces, never on a concrete Firebase or Supabase type -- so this is
/// the only provider that needed to change.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dataSource = SupabaseAuthRemoteDataSource(ref.watch(supabaseClientProvider));
  // TEMPORARY DEV LOGGING -- remove once the registration issue is
  // diagnosed. Same one-time-at-resolution caveat as supabaseClientProvider
  // above. Confirms the concrete type actually wired in is the Supabase
  // implementation, not a stale reference.
  debugPrint('[PROVIDER] authRemoteDataSourceProvider resolved -- concrete type: ${dataSource.runtimeType}');
  return dataSource;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>((ref) {
  return SendPasswordResetUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final watchAuthStateChangesUseCaseProvider = Provider<WatchAuthStateChangesUseCase>((ref) {
  return WatchAuthStateChangesUseCase(ref.watch(authRepositoryProvider));
});

final updatePasswordUseCaseProvider = Provider<UpdatePasswordUseCase>((ref) {
  return UpdatePasswordUseCase(ref.watch(authRepositoryProvider));
});

final watchPasswordRecoveryUseCaseProvider = Provider<WatchPasswordRecoveryUseCase>((ref) {
  return WatchPasswordRecoveryUseCase(ref.watch(authRepositoryProvider));
});

final watchRecoveryFailureUseCaseProvider = Provider<WatchRecoveryFailureUseCase>((ref) {
  return WatchRecoveryFailureUseCase(ref.watch(authRepositoryProvider));
});

/// The single source of truth for "is the user logged in" — drives both
/// router redirects and persistent login.
final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(watchAuthStateChangesUseCaseProvider)();
});

/// True while the user is mid password-recovery (arrived via the reset
/// email's deep link, hasn't set a new password yet). Drives the router's
/// override so a recovery session lands on the reset-password screen
/// instead of the dashboard -- see auth_redirect.dart.
final passwordRecoveryProvider = StreamProvider<bool>((ref) {
  return ref.watch(watchPasswordRecoveryUseCaseProvider)();
});

/// Internal -- only [recoveryFailureReasonProvider] should read this. A
/// plain StreamProvider can't be reset from outside, which is exactly why
/// it's wrapped below: the underlying stream only ever emits a *new*
/// failure, never a "cleared" state, so something has to own when a stale
/// failure stops being shown.
final _recoveryFailureStreamProvider = StreamProvider<RecoveryFailureReason>((ref) {
  return ref.watch(watchRecoveryFailureUseCaseProvider)();
});

/// The current recovery failure to show on the recovery-error screen, or
/// `null` if there isn't one. Latches onto whatever
/// [_recoveryFailureStreamProvider] emits and stays there -- unlike
/// [passwordRecoveryProvider], nothing about a *later*, unrelated auth
/// event should silently dismiss an error the user hasn't acted on yet.
/// Only cleared explicitly, by [RecoveryFailureReasonNotifier.clear] --
/// called from the "Request New Link" button before navigating away.
class RecoveryFailureReasonNotifier extends Notifier<RecoveryFailureReason?> {
  @override
  RecoveryFailureReason? build() {
    ref.listen(_recoveryFailureStreamProvider, (previous, next) {
      final reason = next.valueOrNull;
      if (reason != null) state = reason;
    });
    return null;
  }

  void clear() => state = null;
}

final recoveryFailureReasonProvider =
    NotifierProvider<RecoveryFailureReasonNotifier, RecoveryFailureReason?>(RecoveryFailureReasonNotifier.new);
