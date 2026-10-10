import 'package:equatable/equatable.dart';

/// Pure domain entity. No knowledge of Supabase or any data layer.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.hasEmailPasswordIdentity = true,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;

  /// `true` when the user has an email/password identity, or when identity
  /// data is unavailable (keep password-change visible rather than hide it
  /// incorrectly). `false` only when identities were parsed and none is email.
  final bool hasEmailPasswordIdentity;

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    avatarUrl,
    hasEmailPasswordIdentity,
  ];
}
