import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_performance.dart';
import 'package:carzon/features/seller_analytics/presentation/utils/statistics_inventory.dart';
import 'package:flutter_test/flutter_test.dart';

SellerListingPerformance _row({
  required String id,
  int views = 0,
  int inquiries = 0,
  int favorites = 0,
  ListingStatus status = ListingStatus.active,
  DateTime? createdAt,
  DateTime? soldAt,
}) {
  return SellerListingPerformance(
    listingId: id,
    title: id,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 8, 1),
    soldAt: soldAt,
    make: 'BMW',
    model: id,
    year: 2018,
    periodViews: views,
    currentFavorites: favorites,
    periodInquiries: inquiries,
  );
}

void main() {
  test('top listings rank inquiries then views then favorites', () {
    final top = rankTopListings([
      _row(id: 'c', views: 50, inquiries: 1, favorites: 9),
      _row(id: 'a', views: 10, inquiries: 4, favorites: 0),
      _row(id: 'b', views: 80, inquiries: 4, favorites: 1),
      _row(id: 'd', views: 1, inquiries: 0, favorites: 0),
    ]);
    expect(top.map((e) => e.listingId), ['b', 'a', 'c']);
  });

  test('all-zero engagement does not fabricate a top listing', () {
    expect(
      rankTopListings([
        _row(id: 'a'),
        _row(id: 'b', status: ListingStatus.sold),
      ]),
      isEmpty,
    );
  });

  test('inventory sorting and filtering stay local and deterministic', () {
    final now = DateTime(2026, 9, 13);
    final rows = [
      _row(id: 'old', views: 1, createdAt: DateTime(2026, 1, 1)),
      _row(
        id: 'sold-no-date',
        status: ListingStatus.sold,
        inquiries: 8,
        createdAt: DateTime(2026, 2, 1),
      ),
      _row(
        id: 'sold-long',
        status: ListingStatus.sold,
        favorites: 5,
        createdAt: DateTime(2026, 3, 1),
        soldAt: DateTime(2026, 6, 1),
      ),
    ];

    expect(
      sortInventoryListings(
        rows,
        sort: StatisticsInventorySort.mostInquiries,
        now: now,
      ).map((e) => e.listingId),
      ['sold-no-date', 'old', 'sold-long'],
    );
    expect(
      sortInventoryListings(
        rows,
        sort: StatisticsInventorySort.newest,
        now: now,
      ).first.listingId,
      'sold-long',
    );
    expect(
      sortInventoryListings(
        rows,
        sort: StatisticsInventorySort.longestListed,
        now: now,
      ).map((e) => e.listingId).first,
      'old',
    );
    expect(
      sortInventoryListings(
        rows,
        sort: StatisticsInventorySort.longestListed,
        now: now,
      ).map((e) => e.listingId).last,
      'sold-no-date',
    );
    expect(
      filterInventoryListings(
        rows,
        StatisticsInventoryFilter.sold,
      ).map((e) => e.listingId),
      ['sold-no-date', 'sold-long'],
    );
  });
}
