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
  });

  factory AuthUserModel.fromSupabase(Map<String, dynamic> json) {
    final metadata =
        (json['user_metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AuthUserModel(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      fullName: metadata['full_name'] as String?,
      avatarUrl: metadata['avatar_url'] as String?,
    );
  }
}
