import '../../domain/entities/seller_listing_engagement.dart';

SellerListingEngagement listingEngagementOrZero(
  Iterable<SellerListingEngagement> rows,
  String listingId,
) {
  for (final row in rows) {
    if (row.listingId == listingId) return row;
  }
  return SellerListingEngagement.zero(listingId);
}

Map<String, SellerListingEngagement> indexListingEngagements(
  Iterable<SellerListingEngagement> rows,
) {
  return {for (final row in rows) row.listingId: row};
}
