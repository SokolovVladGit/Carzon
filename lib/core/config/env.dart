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

  /// Returns the list of required keys that are missing or empty.
  /// Use during startup to fail fast with a clear UI instead of crashing later.
  static List<String> missingKeys() {
    return requiredKeys.where((k) {
      final v = dotenv.maybeGet(k);
      return v == null || v.isEmpty;
    }).toList(growable: false);
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
