import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../supabase_options.dart';
import 'auth_remote_datasource.dart';

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  const SupabaseAuthRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  /// Recovery always happens in a browser now, regardless of which platform
  /// requested it -- the Android app never catches this link itself (no
  /// deep-link/custom-scheme handling; that intent-filter was removed from
  /// AndroidManifest.xml). Must be registered in the Supabase Dashboard's
  /// Authentication -> URL Configuration -> Redirect URLs allow-list --
  /// Supabase rejects any `redirectTo` not on that list. See
  /// SupabaseOptions.webRedirectUrl / .env's SUPABASE_WEB_REDIRECT_URL.
  static String get _passwordResetRedirectUrl => SupabaseOptions.webRedirectUrl;

  /// TEMPORARY DEV LOGGING -- diagnosing the deep-link password-recovery
  /// flow. `onAuthStateChange` is where gotrue reports deep-link failures
  /// (e.g. a missing/already-used PKCE code verifier from
  /// `exchangeCodeForSession`): it calls `notifyException`, which pushes the
  /// error onto this exact stream via `addError` -- not a thrown exception
  /// anywhere in *our* code, so nothing previously surfaced it. Logs every
  /// event and every error, then lets both through unchanged.
  Stream<AuthState> get _loggedAuthStateChange {
    return _supabaseClient.auth.onAuthStateChange.map((state) {
      debugPrint('[AUTH DEBUG] onAuthStateChange event: ${state.event}');
      debugPrint('[AUTH DEBUG] onAuthStateChange session present: ${state.session != null}');
      return state;
    }).handleError((Object error, StackTrace stackTrace) {
      debugPrint('[AUTH DEBUG] onAuthStateChange ERROR (likely from a failed deep-link exchange)');
      debugPrint('[AUTH DEBUG] runtimeType: ${error.runtimeType}');
      debugPrint('[AUTH DEBUG] error: $error');
      if (error is AuthException) {
        debugPrint('[AUTH DEBUG] message: ${error.message}');
        debugPrint('[AUTH DEBUG] statusCode: ${error.statusCode}');
      }
      debugPrint('[AUTH DEBUG] stackTrace:\n$stackTrace');
      throw error;
    });
  }

  @override
  Stream<User?> authStateChanges() {
    return _loggedAuthStateChange.map((state) => state.session?.user);
  }

  @override
  Stream<bool> passwordRecoveryEvents() {
    // Sticky, not momentary. `onAuthStateChange` emits far more than just
    // the recovery event (initialSession at startup, tokenRefreshed, etc.)
    // -- a bare `event == passwordRecovery` mapping (the previous
    // implementation) reverts to `false` the instant *any* unrelated event
    // fires next, which it reliably does. That made "is recovering" a
    // one-tick pulse instead of a state, so by the time the router's
    // redirect callback re-ran, it would often already see `false` and
    // correctly-by-its-own-logic send the user to /login -- not a routing
    // bug, a bug in the signal routing depends on. Recovery mode now
    // persists until the user actually leaves it: completes the reset
    // (userUpdated, fired by updatePassword) or signs out.
    return _loggedAuthStateChange
        .map((state) => state.event)
        .where(
          (event) =>
              event == AuthChangeEvent.passwordRecovery ||
              event == AuthChangeEvent.userUpdated ||
              event == AuthChangeEvent.signedOut,
        )
        .map((event) {
      final isRecovering = event == AuthChangeEvent.passwordRecovery;
      debugPrint('[AUTH DEBUG] passwordRecoveryEvents -- event: $event, isPasswordRecovery now: $isRecovering');
      return isRecovering;
    });
  }

  @override
  Stream<AuthException?> recoveryFailureEvents() {
    // Converts stream *errors* into stream *values* -- StreamTransformer,
    // not .handleError, because .handleError only lets you swallow or
    // rethrow an error, not turn it into a data event. Ordinary events
    // deliberately emit nothing here (not even null): whether a prior
    // failure is still "current" is a presentation-layer decision (see
    // recoveryFailureReasonProvider's explicit .clear(), called from the
    // "Request New Link" button) -- this stream only ever reports that a
    // new failure happened, on the event it happened.
    return _loggedAuthStateChange.transform<AuthException?>(
      StreamTransformer.fromHandlers(
        handleData: (state, sink) {},
        handleError: (Object error, StackTrace stackTrace, EventSink<AuthException?> sink) {
          if (error is AuthException) sink.add(error);
        },
      ),
    );
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final response = await _supabaseClient.auth.signInWithPassword(email: email, password: password);
    final user = response.user;
    if (user == null) {
      // Defensive: signInWithPassword throws its own AuthException on
      // invalid credentials rather than returning a null user, but nothing
      // in the SDK's type signature *guarantees* that, so this is a
      // fallback rather than the expected path.
      throw const AuthException('Invalid email or password.');
    }
    return user;
  }

  @override
  Future<User> register({required String email, required String password}) async {
    // TEMPORARY DEV LOGGING -- remove once the registration issue is diagnosed.
    debugPrint('[STEP 5] SupabaseAuthRemoteDataSource.register -- entered');
    debugPrint('[STEP 5] email: $email');
    debugPrint('[STEP 5] password length: ${password.length}');
    // This call site never passes a `data:` map to signUp(), so there is no
    // user metadata to send -- printed for completeness, not because
    // metadata is expected to be non-null.
    debugPrint('[STEP 5] metadata: null (not passed by this call site)');
    debugPrint('[STEP 5] calling supabase.auth.signUp() now...');
    try {
      final response = await _supabaseClient.auth.signUp(email: email, password: password);
      debugPrint('[STEP 5] supabase.auth.signUp() returned');
      debugPrint('[STEP 5] AuthResponse: $response');
      debugPrint('[STEP 5] response.session: ${response.session}');
      debugPrint('[STEP 5] response.user: ${response.user}');
      debugPrint('[STEP 5] response.user?.id: ${response.user?.id}');
      final user = response.user;
      if (user == null) {
        debugPrint('[STEP 5] response.user is null -- throwing fallback AuthException("Registration failed.")');
        throw const AuthException('Registration failed.');
      }
      return user;
    } on AuthException catch (e, stackTrace) {
      debugPrint('[STEP 5] supabase.auth.signUp() THREW AuthException');
      debugPrint('[STEP 5] runtimeType: ${e.runtimeType}');
      debugPrint('[STEP 5] message: ${e.message}');
      debugPrint('[STEP 5] statusCode: ${e.statusCode}');
      debugPrint('[STEP 5] stackTrace:\n$stackTrace');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[STEP 5] supabase.auth.signUp() THREW a non-AuthException error');
      debugPrint('[STEP 5] runtimeType: ${e.runtimeType}');
      debugPrint('[STEP 5] exception: $e');
      debugPrint('[STEP 5] stackTrace:\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _supabaseClient.auth.resetPasswordForEmail(email, redirectTo: _passwordResetRedirectUrl);
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await _supabaseClient.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> logout() => _supabaseClient.auth.signOut();
}
