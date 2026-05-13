import '../../../core/services/supabase_service.dart';

/// Whether the Supabase session currently has a signed-in user (for FCM RPCs).
abstract interface class PushAuthGate {
  bool get hasAuthenticatedUser;
}

/// [PushAuthGate] backed by [SupabaseService]. Used by push registration only.
class SupabasePushAuthGate implements PushAuthGate {
  SupabasePushAuthGate(this._supabase);

  final SupabaseService _supabase;

  @override
  bool get hasAuthenticatedUser => _supabase.client.auth.currentUser != null;
}
