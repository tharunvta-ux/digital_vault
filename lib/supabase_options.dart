import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase project configuration: the values needed to initialize the
/// backend client.
///
/// Two different sources depending on platform:
///
/// - **Android/desktop**: read from the untracked `.env` file at runtime
///   (see `.env.example` for the required keys) via `flutter_dotenv` --
///   `dotenv.load()` must complete before these getters are read (done in
///   `main()`, skipped entirely on web -- see there).
/// - **Web**: read at *compile* time via `String.fromEnvironment`, supplied
///   through `--dart-define-from-file=web_config.json`. A web build has no
///   reliable "local untracked file" to depend on -- it may be built fresh
///   on a CI runner or a static host's build step that never had `.env` in
///   the first place (this is what broke the Netlify deploy: the app tried
///   to fetch `assets/.env` at runtime and it didn't exist). Compiling the
///   values in avoids that entirely.
///
/// Both the Supabase URL and the publishable key are meant to be embedded in
/// client apps -- they're not secrets; access control is enforced by Row
/// Level Security in Postgres and Storage policies, not by keeping these
/// hidden. That's exactly why `web_config.json` is safe to commit (unlike
/// `.env`, which is untracked purely as a convention, not because its
/// contents are sensitive).
class SupabaseOptions {
  const SupabaseOptions._();

  static String get url {
    if (kIsWeb) return _requireWebDefine('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL'));
    return dotenv.env['SUPABASE_URL']!;
  }

  static String get publishableKey {
    if (kIsWeb) {
      return _requireWebDefine(
        'SUPABASE_PUBLISHABLE_KEY',
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      );
    }
    return dotenv.env['SUPABASE_PUBLISHABLE_KEY']!;
  }

  /// Where Supabase redirects the browser after processing a password-reset
  /// link. Must exactly match an entry in the Supabase Dashboard's
  /// Authentication -> URL Configuration -> Redirect URLs allow-list.
  static String get webRedirectUrl {
    if (kIsWeb) {
      return _requireWebDefine(
        'SUPABASE_WEB_REDIRECT_URL',
        const String.fromEnvironment('SUPABASE_WEB_REDIRECT_URL'),
      );
    }
    return dotenv.env['SUPABASE_WEB_REDIRECT_URL']!;
  }

  /// `String.fromEnvironment` silently returns `''` for a define that was
  /// never passed -- unlike `dotenv.env[...]!`, which throws immediately and
  /// clearly on a missing key. This restores that same loud-failure
  /// behavior for web, instead of an empty URL/key surfacing later as a
  /// confusing network or Supabase-client error.
  static String _requireWebDefine(String key, String value) {
    if (value.isEmpty) {
      throw StateError(
        'Missing --dart-define for $key. Web builds read config at compile '
        'time, not from .env -- build with: '
        'flutter build web --dart-define-from-file=web_config.json',
      );
    }
    return value;
  }
}
