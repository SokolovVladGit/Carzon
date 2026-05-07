import 'package:equatable/equatable.dart';

/// Fields returned by `get_my_seller_profile` / `update_my_seller_display_name`.
class MySellerProfile extends Equatable {
  const MySellerProfile({
    required this.displayName,
    required this.avatarUrl,
    required this.avatarPath,
    required this.memberSince,
    required this.publicVisibility,
  });

  final String? displayName;
  final String? avatarUrl;

  /// Storage object path under `seller-avatars` (for replace/delete); null if none.
  final String? avatarPath;
  final DateTime memberSince;
  final bool publicVisibility;

  @override
  List<Object?> get props => [
    displayName,
    avatarUrl,
    avatarPath,
    memberSince,
    publicVisibility,
  ];
}
