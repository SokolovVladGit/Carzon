import 'package:equatable/equatable.dart';

import 'seller_type.dart';

/// Public seller summary returned by `get_seller_public_profile`.
///
/// Trust fields ([ratingAverage], verification flags, etc.) are parsed for
/// future phases but must not be shown in the MVP UI.
class SellerPublicProfile extends Equatable {
  const SellerPublicProfile({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.memberSince,
    required this.sellerType,
    required this.activeListingsCount,
    required this.ratingAverage,
    required this.ratingCount,
    required this.reviewCount,
    required this.verifiedPhone,
    required this.verifiedEmail,
    required this.verifiedDealer,
  });

  final String userId;

  /// May be null when the backend has no display name yet.
  final String? displayName;

  /// Public HTTPS URL for the avatar. Null/empty ⇒ use initials/icon.
  final String? avatarUrl;

  final DateTime memberSince;
  final SellerType sellerType;
  final int activeListingsCount;

  final double? ratingAverage;
  final int ratingCount;
  final int reviewCount;
  final bool verifiedPhone;
  final bool verifiedEmail;
  final bool verifiedDealer;

  @override
  List<Object?> get props => [
    userId,
    displayName,
    avatarUrl,
    memberSince,
    sellerType,
    activeListingsCount,
    ratingAverage,
    ratingCount,
    reviewCount,
    verifiedPhone,
    verifiedEmail,
    verifiedDealer,
  ];
}
