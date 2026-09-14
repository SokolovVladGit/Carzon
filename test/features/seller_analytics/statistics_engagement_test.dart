import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_engagement.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_performance.dart';
import 'package:carzon/features/seller_analytics/presentation/utils/statistics_engagement.dart';
import 'package:carzon/features/seller_analytics/presentation/utils/statistics_inventory.dart';
import 'package:flutter_test/flutter_test.dart';

SellerListingPerformance _row(String id, {int inquiries = 0, int views = 0}) {
  return SellerListingPerformance(
    listingId: id,
    title: id,
    status: ListingStatus.active,
    createdAt: DateTime(2026, 8, 1),
    make: 'BMW',
    model: id,
    year: 2018,
    periodViews: views,
    currentFavorites: 0,
    periodInquiries: inquiries,
  );
}

void main() {
  test('missing engagement row maps to zeros', () {
    final joined = listingEngagementOrZero(const [
      SellerListingEngagement(
        listingId: 'a',
        periodImpressions: 9,
        periodPhoneActions: 1,
        periodWhatsappActions: 0,
        periodTelegramActions: 0,
        periodShares: 2,
      ),
    ], 'missing');
    expect(joined.listingId, 'missing');
    expect(joined.periodImpressions, 0);
    expect(joined.periodContactActions, 0);
    expect(joined.periodShares, 0);
  });

  test('join is by listing_id', () {
    final joined = listingEngagementOrZero(const [
      SellerListingEngagement.zero('a'),
      SellerListingEngagement(
        listingId: 'b',
        periodImpressions: 5,
        periodPhoneActions: 2,
        periodWhatsappActions: 1,
        periodTelegramActions: 0,
        periodShares: 0,
      ),
    ], 'b');
    expect(joined.periodImpressions, 5);
    expect(joined.periodContactActions, 3);
  });

  test('top listings ranking ignores impressions and contact actions', () {
    final top = rankTopListings([
      _row('impressions-heavy', views: 1, inquiries: 0),
      _row('inquiries-heavy', views: 1, inquiries: 4),
      _row('views-heavy', views: 80, inquiries: 0),
    ]);
    expect(top.map((e) => e.listingId).take(2), [
      'inquiries-heavy',
      'views-heavy',
    ]);
  });
}
