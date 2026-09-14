import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_demand.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_performance.dart';
import 'package:carzon/features/seller_analytics/presentation/utils/statistics_demand.dart';
import 'package:flutter_test/flutter_test.dart';

SellerListingPerformance _row({
  required String id,
  ListingStatus status = ListingStatus.active,
}) {
  return SellerListingPerformance(
    listingId: id,
    title: id,
    status: status,
    createdAt: DateTime(2026, 8, 1),
    make: 'BMW',
    model: id,
    year: 2018,
    periodViews: 1,
    currentFavorites: 0,
    periodInquiries: 0,
  );
}

SellerListingDemand _demand({
  required String id,
  int? matchingUsers,
  bool suppressed = false,
}) {
  return SellerListingDemand(
    listingId: id,
    matchingUsers: matchingUsers,
    isSuppressed: suppressed,
  );
}

void main() {
  test('top demand ranks visible counts and listing id ties', () {
    final top = rankTopDemandListings(
      [_row(id: 'c'), _row(id: 'a'), _row(id: 'b'), _row(id: 'd')],
      demands: {
        'c': _demand(id: 'c', matchingUsers: 12),
        'a': _demand(id: 'a', matchingUsers: 20),
        'b': _demand(id: 'b', matchingUsers: 20),
        'd': _demand(id: 'd', matchingUsers: 9),
      },
    );
    expect(top.map((e) => e.listingId), ['a', 'b', 'c']);
  });

  test('top demand excludes suppressed, zero, sold, and missing rows', () {
    final top = rankTopDemandListings(
      [
        _row(id: 'visible'),
        _row(id: 'zero'),
        _row(id: 'hidden'),
        _row(id: 'sold', status: ListingStatus.sold),
        _row(id: 'missing'),
      ],
      demands: {
        'visible': _demand(id: 'visible', matchingUsers: 8),
        'zero': _demand(id: 'zero', matchingUsers: 0),
        'hidden': _demand(id: 'hidden', suppressed: true),
        'sold': _demand(id: 'sold', matchingUsers: 40),
      },
    );
    expect(top.map((e) => e.listingId), ['visible']);
  });

  test('top demand is omitted when nothing is safely visible', () {
    expect(
      rankTopDemandListings(
        [_row(id: 'a'), _row(id: 'b')],
        demands: {
          'a': _demand(id: 'a', matchingUsers: 0),
          'b': _demand(id: 'b', suppressed: true),
        },
      ),
      isEmpty,
    );
  });
}
