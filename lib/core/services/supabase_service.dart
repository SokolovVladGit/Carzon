import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Thin wrapper around the Supabase singleton.
///
/// Centralizes initialization so the rest of the codebase never touches
/// `Supabase.initialize` directly. Datasources depend on this service
/// (registered in DI) — never on `Supabase.instance.client` globally.
class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  static Future<SupabaseService> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: false,
      // Disable Supabase's built-in deep-link observer so the app has
      // a single, testable code path for auth callbacks in
      // `AuthDeepLinkService`. Leaving it on would cause the same URI
      // to be consumed twice (the SDK subscribes to `app_links`
      // internally whenever this flag is true), and the second
      // `getSessionFromUrl` call fails because the one-time PKCE code
      // verifier has already been exchanged.
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
      ),
    );
    return SupabaseService(Supabase.instance.client);
  }
}
