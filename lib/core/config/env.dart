import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client-safe compile-time configuration.
///
/// Values must be passed via `--dart-define` or
/// `--dart-define-from-file=.env.client` (see `.env.client.example`).
/// Each key uses a **literal** [String.fromEnvironment] — dynamic key lookup
/// does not receive compile-time defines.
///
/// Widget tests may call [dotenv.testLoad] when compile-time defines are empty;
/// that path is never used at app startup.
class Env {
  Env._();

  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _passwordResetRedirectUrl = String.fromEnvironment(
    'SUPABASE_PASSWORD_RESET_REDIRECT_URL',
  );
  static const String _reportEmail = String.fromEnvironment(
    'CARZON_REPORT_EMAIL',
  );
  static const String _pushNotificationsEnabled = String.fromEnvironment(
    'PUSH_NOTIFICATIONS_ENABLED',
  );

  /// Keys the app cannot run without.
  static const List<String> requiredKeys = <String>[
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
  ];

  static String get supabaseUrl => _required(_supabaseUrl, 'SUPABASE_URL');

  static String get supabaseAnonKey =>
      _required(_supabaseAnonKey, 'SUPABASE_ANON_KEY');

  /// Optional deep-link target for password-reset / email-confirmation emails.
  static String? get passwordResetRedirectUrl => _optionalNonEmpty(
    _passwordResetRedirectUrl,
    'SUPABASE_PASSWORD_RESET_REDIRECT_URL',
  );

  /// Optional mailto destination for in-app listing reports; hidden when absent.
  static String? get reportEmail {
    final value = _optionalNonEmpty(_reportEmail, 'CARZON_REPORT_EMAIL');
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Client FCM bootstrap flag. Default **false** when unset or empty.
  static bool get pushNotificationsEnabled {
    final raw = _optionalNonEmpty(
      _pushNotificationsEnabled,
      'PUSH_NOTIFICATIONS_ENABLED',
    );
    if (raw == null) return false;
    switch (raw.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }

  /// Required keys missing from compile-time defines (and test dotenv fallback).
  static List<String> missingKeys() {
    final missing = <String>[];
    if (_isMissing(_supabaseUrl, 'SUPABASE_URL')) {
      missing.add('SUPABASE_URL');
    }
    if (_isMissing(_supabaseAnonKey, 'SUPABASE_ANON_KEY')) {
      missing.add('SUPABASE_ANON_KEY');
    }
    return missing;
  }

  static bool _isMissing(String compiled, String dotenvKey) {
    if (compiled.isNotEmpty) return false;
    final test = _testDotenvValue(dotenvKey);
    return test == null || test.isEmpty;
  }

  static String _required(String compiled, String dotenvKey) {
    if (compiled.isNotEmpty) return compiled;
    final test = _testDotenvValue(dotenvKey);
    if (test != null && test.isNotEmpty) return test;
    throw StateError(
      'Missing required environment variable: $dotenvKey. '
      'Copy .env.client.example to .env.client, fill client-safe values, '
      'and run with --dart-define-from-file=.env.client',
    );
  }

  static String? _optionalNonEmpty(String compiled, String dotenvKey) {
    if (compiled.isNotEmpty) return compiled;
    final test = _testDotenvValue(dotenvKey);
    if (test == null || test.isEmpty) return null;
    return test;
  }

  static String? _testDotenvValue(String key) {
    try {
      return dotenv.maybeGet(key);
    } catch (_) {
      return null;
    }
  }
}
