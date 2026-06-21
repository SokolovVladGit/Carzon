import 'package:equatable/equatable.dart';

/// Safe row from `list_blocked_users` (no email/phone/private fields).
class BlockedUser extends Equatable {
  const BlockedUser({
    required this.blockedUserId,
    required this.createdAt,
    this.displayName,
    this.avatarUrl,
  });

  final String blockedUserId;
  final DateTime createdAt;
  final String? displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [blockedUserId, createdAt, displayName, avatarUrl];
}
