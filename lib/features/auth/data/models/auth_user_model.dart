import '../../domain/entities/auth_user.dart';

/// Data layer model. Converts between Supabase representation and the
/// domain entity. Keeping this separate insulates the domain from
/// backend-specific shapes (and future React/web reuse).
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.avatarUrl,
    super.hasEmailPasswordIdentity,
  });

  factory AuthUserModel.fromSupabase(Map<String, dynamic> json) {
    final metadata =
        (json['user_metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AuthUserModel(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      fullName: metadata['full_name'] as String?,
      avatarUrl: metadata['avatar_url'] as String?,
      hasEmailPasswordIdentity: emailPasswordIdentityFromJson(json),
    );
  }

  /// `false` only when identities/providers were present and none is `email`.
  /// Missing identity data stays `true` so password-change is not hidden.
  static bool emailPasswordIdentityFromJson(Map<String, dynamic> json) {
    final identities = json['identities'];
    if (identities is List) {
      return identities.any((raw) {
        if (raw is Map) {
          return raw['provider']?.toString() == 'email';
        }
        return false;
      });
    }
    final appMetadata = json['app_metadata'];
    if (appMetadata is Map) {
      final providers = appMetadata['providers'];
      if (providers is List) {
        return providers.map((e) => e.toString()).contains('email');
      }
    }
    return true;
  }
}
