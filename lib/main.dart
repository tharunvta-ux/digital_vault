import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'features/reminder/presentation/startup/reminder_notification_bootstrap.dart';
import 'supabase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web reads its config at compile time instead (see SupabaseOptions) --
  // there's no .env asset to load there, and no reason to depend on one for
  // a build that might run on a fresh CI checkout or a static host's build
  // step that never had this untracked file to begin with.
  if (!kIsWeb) {
    await dotenv.load(fileName: '.env');
  }

  // TEMPORARY DEV LOGGING -- remove once the "Invalid API key" issue is
  // diagnosed. Never prints the full key (only its prefix + length), per
  // the debugging requirements this was added for.
  bool initSucceeded = false;
  Object? initError;
  try {
    await Supabase.initialize(url: SupabaseOptions.url, publishableKey: SupabaseOptions.publishableKey);
    initSucceeded = true;
  } catch (e, stackTrace) {
    initError = e;
    debugPrint('[SUPABASE DEBUG] Supabase.initialize THREW: $e');
    debugPrint('[SUPABASE DEBUG] Runtime type: ${e.runtimeType}');
    debugPrint('[SUPABASE DEBUG] Stack trace:\n$stackTrace');
    rethrow;
  } finally {
    final key = SupabaseOptions.publishableKey;
    debugPrint('========== SUPABASE DEBUG ==========');
    debugPrint('Project URL: ${SupabaseOptions.url}');
    debugPrint('Key Prefix: ${key.substring(0, key.indexOf('_', 3) + 1)}');
    debugPrint('Key Length: ${key.length}');
    debugPrint('Initialization Success: $initSucceeded${initError != null ? ' (threw: $initError)' : ''}');
    // Constructed, not read from a public getter -- supabase_client.dart
    // builds it internally as `'$supabaseUrl/auth/v1'` (SupabaseClient has
    // no public accessor for it), so this reproduces that exact formula
    // against the same SupabaseOptions.url value used above.
    debugPrint('Current Auth Endpoint: ${SupabaseOptions.url}/auth/v1');
    debugPrint('===================================');
  }

  // TEMPORARY DEV LOGGING -- diagnosing the password-recovery deep link.
  // `AppLinks()` is a singleton over a broadcast stream (verified from
  // app_links' own source), so this listener runs alongside -- not instead
  // of -- supabase_flutter's own internal one; it only observes, never
  // calls anything. This is the one place that can show the *raw* incoming
  // URI independent of whether gotrue's internal code-exchange succeeds,
  // which is otherwise invisible (that logic is private to the package).
  AppLinks().uriLinkStream.listen((uri) {
    debugPrint('========== PASSWORD RECOVERY ==========');
    debugPrint('Incoming URI: $uri');
    debugPrint('Deep link received: true');
    debugPrint('uri.query (raw, before #): "${uri.query}"');
    debugPrint('uri.queryParameters: ${uri.queryParameters}');
    debugPrint('uri.fragment (raw, after #): "${uri.fragment}"');

    // Reproduces supabase_flutter's OWN internal check, exactly --
    // `_isAuthCallbackDeeplink` in supabase_auth.dart:203-214 -- since that
    // method is private and can't be called or logged from here directly.
    // With a hash-routed redirect URL (`.../#/reset-password`), Supabase
    // appends the code as `?code=...`, producing a fragment shaped like
    // `/reset-password?code=XXXX`. `Uri.splitQueryString` on THAT string
    // does not extract a clean `code` key -- it splits on the first `=`
    // and produces a single mangled key `/reset-password?code`, verified
    // directly: Uri.splitQueryString('/reset-password?code=abc123') ==
    // {'/reset-password?code': 'abc123'}, NOT {'code': 'abc123'}. If that's
    // what shows up below, the SDK's own callback detection is failing
    // silently -- passwordRecovery never fires, not because of a race or a
    // reused code, but because the deep link is never recognized as an
    // auth callback at all.
    final fragmentParameters = Uri.splitQueryString(uri.fragment);
    debugPrint('Uri.splitQueryString(uri.fragment): $fragmentParameters');
    bool hasParam(String key) => uri.queryParameters.containsKey(key) || fragmentParameters.containsKey(key);
    final wouldBeRecognizedAsAuthCallback = hasParam('access_token') ||
        hasParam('code') ||
        hasParam('error') ||
        hasParam('error_code') ||
        hasParam('error_description');
    debugPrint(
      'Would supabase_flutter recognize this as an auth callback '
      '(replicates _isAuthCallbackDeeplink exactly): $wouldBeRecognizedAsAuthCallback',
    );

    debugPrint('token (query): ${uri.queryParameters['token']}');
    debugPrint('type (query): ${uri.queryParameters['type']}');
    debugPrint('code (query): ${uri.queryParameters['code']}');
    debugPrint('code (fragment-parsed): ${fragmentParameters['code']}');
    debugPrint('type (fragment-parsed): ${fragmentParameters['type']}');
    debugPrint('access_token (fragment-parsed): ${fragmentParameters['access_token']}');
    debugPrint('error (query): ${uri.queryParameters['error']}');
    debugPrint('error (fragment-parsed): ${fragmentParameters['error']}');
    debugPrint('error_description (query): ${uri.queryParameters['error_description']}');
    debugPrint('error_description (fragment-parsed): ${fragmentParameters['error_description']}');
    debugPrint(
      'Note: exchangeCodeForSession() itself runs inside supabase_flutter, '
      'not observable directly -- if wouldBeRecognizedAsAuthCallback is '
      'true above, its outcome shows up as the next [AUTH DEBUG] '
      'onAuthStateChange event or error, logged separately. If false, '
      'supabase_flutter returns early and never attempts it at all.',
    );
    debugPrint('========================================');
  });

  // A manually-created container, not the ProviderScope widget's own,
  // because the notification bootstrap below needs to read providers
  // (Supabase-backed reminder data) before the widget tree -- and therefore
  // before ProviderScope itself -- exists. UncontrolledProviderScope hands
  // this same container to the widget tree afterward, so every provider
  // read from here on (including by the bootstrap's own effects, like
  // authStateChangesProvider) is the same instance the rest of the app
  // sees -- nothing gets initialized twice.
  final container = ProviderContainer();
  await restoreReminderNotificationsOnStartup(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DigitalVaultApp(),
    ),
  );
}
