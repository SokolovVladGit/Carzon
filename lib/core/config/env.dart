import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Strongly-typed access to environment variables loaded from `.env`.
///
/// All sensitive values (Supabase URL, anon key, etc.) MUST come from here.
/// Never hardcode credentials in the codebase.
class Env {
  Env._();

  /// Keys that the app cannot run without.
  static const List<String> requiredKeys = <String>[
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
  ];

  static String get supabaseUrl => _required('SUPABASE_URL');
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');

  /// Optional. When set, password-reset emails will deep-link to this
  /// URL (app custom scheme or a web fallback). When absent, Supabase
  /// uses the project's Site URL; the MVP still works end-to-end in
  /// the browser even without native deep-link plumbing.
  static String? get passwordResetRedirectUrl {
    final value = dotenv.maybeGet('SUPABASE_PASSWORD_RESET_REDIRECT_URL');
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Optional. Destination address for the in-app "Report listing"
  /// mailto action on `ListingDetailsPage`. When absent (or empty),
  /// the report action is hidden entirely — the app is fully usable
  /// without it and MUST NOT synthesize a fake production address.
  ///
  /// This is intentionally NOT part of [requiredKeys]: Carzon must
  /// boot and serve the public feed even if the ops team has not yet
  /// provisioned a reports inbox.
  static String? get reportEmail {
    final value = dotenv.maybeGet('CARZON_REPORT_EMAIL');
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  /// Returns the list of required keys that are missing or empty.
  /// Use during startup to fail fast with a clear UI instead of crashing later.
  static List<String> missingKeys() {
    return requiredKeys
        .where((k) {
          final v = dotenv.maybeGet(k);
          return v == null || v.isEmpty;
        })
        .toList(growable: false);
  }

  static String _required(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required environment variable: $key. '
        'Check the .env file (see .env.example).',
      );
    }
    return value;
  }
}
