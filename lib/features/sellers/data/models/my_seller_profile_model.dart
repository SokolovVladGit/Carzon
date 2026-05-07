import '../../domain/entities/my_seller_profile.dart';

class MySellerProfileModel extends MySellerProfile {
  const MySellerProfileModel({
    required super.displayName,
    required super.avatarUrl,
    required super.avatarPath,
    required super.memberSince,
    required super.publicVisibility,
  });

  factory MySellerProfileModel.fromJson(Map<String, dynamic> json) {
    final msRaw = json['member_since'];
    DateTime memberSince;
    if (msRaw is String) {
      memberSince = DateTime.parse(msRaw);
    } else if (msRaw is DateTime) {
      memberSince = msRaw;
    } else {
      throw FormatException('my_seller_profile member_since', msRaw);
    }

    return MySellerProfileModel(
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarPath: json['avatar_path'] as String?,
      memberSince: memberSince,
      publicVisibility: json['public_visibility'] as bool? ?? true,
    );
  }
}
