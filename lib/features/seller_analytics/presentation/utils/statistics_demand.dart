import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_performance.dart';

Map<String, SellerListingDemand> indexListingDemands(
  Iterable<SellerListingDemand> rows,
) {
  return {for (final row in rows) row.listingId: row};
}

/// Visible unsuppressed demand only. Empty when nothing can be ranked safely.
List<SellerListingPerformance> rankTopDemandListings(
  List<SellerListingPerformance> listings, {
  required Map<String, SellerListingDemand> demands,
  int limit = 3,
}) {
  final ranked = <SellerListingPerformance>[];
  for (final listing in listings) {
    if (listing.status != ListingStatus.active) continue;
    final demand = demands[listing.listingId];
    if (demand == null || !demand.isVisibleCount) continue;
    ranked.add(listing);
  }
  if (ranked.isEmpty) return const [];
  ranked.sort((a, b) {
    final aCount = demands[a.listingId]!.matchingUsers!;
    final bCount = demands[b.listingId]!.matchingUsers!;
    final byCount = bCount.compareTo(aCount);
    if (byCount != 0) return byCount;
    return a.listingId.compareTo(b.listingId);
  });
  if (ranked.length <= limit) return ranked;
  return ranked.sublist(0, limit);
}
