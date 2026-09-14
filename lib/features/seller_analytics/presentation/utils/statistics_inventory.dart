import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/seller_listing_performance.dart';

enum StatisticsInventorySort {
  mostInquiries,
  mostViewed,
  mostFavorited,
  newest,
  longestListed,
}

enum StatisticsInventoryFilter { all, active, sold }

bool listingHasEngagement(SellerListingPerformance listing) {
  return listing.periodViews > 0 ||
      listing.periodInquiries > 0 ||
      listing.currentFavorites > 0;
}

/// Strongest buyer-interest listings. Empty when every row has zero engagement.
List<SellerListingPerformance> rankTopListings(
  List<SellerListingPerformance> listings, {
  int limit = 3,
}) {
  final engaged = [
    for (final listing in listings)
      if (listingHasEngagement(listing)) listing,
  ];
  if (engaged.isEmpty) return const [];
  engaged.sort(_compareTopInterest);
  if (engaged.length <= limit) return engaged;
  return engaged.sublist(0, limit);
}

int _compareTopInterest(
  SellerListingPerformance a,
  SellerListingPerformance b,
) {
  final inquiries = b.periodInquiries.compareTo(a.periodInquiries);
  if (inquiries != 0) return inquiries;
  final views = b.periodViews.compareTo(a.periodViews);
  if (views != 0) return views;
  final favorites = b.currentFavorites.compareTo(a.currentFavorites);
  if (favorites != 0) return favorites;
  final id = a.listingId.compareTo(b.listingId);
  if (id != 0) return id;
  return a.title.compareTo(b.title);
}

List<SellerListingPerformance> filterInventoryListings(
  List<SellerListingPerformance> listings,
  StatisticsInventoryFilter filter,
) {
  return switch (filter) {
    StatisticsInventoryFilter.all => listings,
    StatisticsInventoryFilter.active => [
      for (final listing in listings)
        if (listing.status == ListingStatus.active) listing,
    ],
    StatisticsInventoryFilter.sold => [
      for (final listing in listings)
        if (listing.status == ListingStatus.sold) listing,
    ],
  };
}

List<SellerListingPerformance> sortInventoryListings(
  List<SellerListingPerformance> listings, {
  required StatisticsInventorySort sort,
  required DateTime now,
}) {
  final copy = [...listings];
  copy.sort((a, b) => _compareInventory(a, b, sort: sort, now: now));
  return copy;
}

int? trackedDurationDays(SellerListingPerformance listing, DateTime now) {
  if (listing.soldAt != null) return listing.soldDurationDays();
  if (listing.status == ListingStatus.active) {
    return listing.activeListingAgeDays(now);
  }
  return null;
}

int _compareInventory(
  SellerListingPerformance a,
  SellerListingPerformance b, {
  required StatisticsInventorySort sort,
  required DateTime now,
}) {
  final primary = switch (sort) {
    StatisticsInventorySort.mostInquiries => b.periodInquiries.compareTo(
      a.periodInquiries,
    ),
    StatisticsInventorySort.mostViewed => b.periodViews.compareTo(
      a.periodViews,
    ),
    StatisticsInventorySort.mostFavorited => b.currentFavorites.compareTo(
      a.currentFavorites,
    ),
    StatisticsInventorySort.newest => b.createdAt.compareTo(a.createdAt),
    StatisticsInventorySort.longestListed => _compareLongest(a, b, now),
  };
  if (primary != 0) return primary;
  return a.listingId.compareTo(b.listingId);
}

int _compareLongest(
  SellerListingPerformance a,
  SellerListingPerformance b,
  DateTime now,
) {
  final aDays = trackedDurationDays(a, now);
  final bDays = trackedDurationDays(b, now);
  if (aDays == null && bDays == null) return 0;
  if (aDays == null) return 1;
  if (bDays == null) return -1;
  return bDays.compareTo(aDays);
}
