import '../../domain/entities/blocked_user.dart';

class BlockedUserModel extends BlockedUser {
  const BlockedUserModel({
    required super.blockedUserId,
    required super.createdAt,
    super.displayName,
    super.avatarUrl,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      blockedUserId: json['blocked_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
