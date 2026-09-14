import 'package:equatable/equatable.dart';

/// Per-listing unique matching accounts for one active seller listing.
class SellerListingDemand extends Equatable {
  const SellerListingDemand({
    required this.listingId,
    required this.matchingUsers,
    required this.isSuppressed,
  });

  final String listingId;
  final int? matchingUsers;
  final bool isSuppressed;

  bool get isZero => !isSuppressed && matchingUsers == 0;

  bool get isPrivacySuppressed => isSuppressed && matchingUsers == null;

  bool get isVisibleCount =>
      !isSuppressed && matchingUsers != null && matchingUsers! >= 5;

  @override
  List<Object?> get props => [listingId, matchingUsers, isSuppressed];
}
