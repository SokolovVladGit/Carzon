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
    );
    return SupabaseService(Supabase.instance.client);
  }
}
