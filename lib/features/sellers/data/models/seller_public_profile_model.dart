import '../../domain/entities/seller_public_profile.dart';
import '../../domain/entities/seller_type.dart';

class SellerPublicProfileModel extends SellerPublicProfile {
  const SellerPublicProfileModel({
    required super.userId,
    required super.displayName,
    required super.avatarUrl,
    required super.memberSince,
    required super.sellerType,
    required super.activeListingsCount,
    required super.ratingAverage,
    required super.ratingCount,
    required super.reviewCount,
    required super.verifiedPhone,
    required super.verifiedEmail,
    required super.verifiedDealer,
  });

  factory SellerPublicProfileModel.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['rating_average'];
    double? ratingAverage;
    if (ratingRaw is num) {
      ratingAverage = ratingRaw.toDouble();
    } else if (ratingRaw is String && ratingRaw.trim().isNotEmpty) {
      ratingAverage = double.tryParse(ratingRaw.trim());
    }

    final memberSinceRaw = json['member_since'];
    DateTime memberSince;
    if (memberSinceRaw is String) {
      memberSince = DateTime.parse(memberSinceRaw);
    } else if (memberSinceRaw is DateTime) {
      memberSince = memberSinceRaw;
    } else {
      throw FormatException('seller profile member_since', memberSinceRaw);
    }

    final activeRaw = json['active_listings_count'];
    final activeListingsCount = activeRaw is int
        ? activeRaw
        : (activeRaw as num?)?.toInt() ?? 0;

    return SellerPublicProfileModel(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      memberSince: memberSince,
      sellerType: _parseSellerType(json['seller_type'] as String?),
      activeListingsCount: activeListingsCount,
      ratingAverage: ratingAverage,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      verifiedPhone: json['verified_phone'] as bool? ?? false,
      verifiedEmail: json['verified_email'] as bool? ?? false,
      verifiedDealer: json['verified_dealer'] as bool? ?? false,
    );
  }

  static SellerType _parseSellerType(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'dealer':
        return SellerType.dealer;
      default:
        return SellerType.private;
    }
  }
}
