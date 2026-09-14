import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/seller_analytics/data/mappers/seller_analytics_mapper.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sellerAnalyticsSummaryFromRow', () {
    test('maps all fields including dealer type', () {
      final summary = sellerAnalyticsSummaryFromRow({
        'seller_type': 'dealer',
        'verified_dealer': true,
        'active_count': 2,
        'sold_count': 1,
        'period_views': 40,
        'current_favorites': 3,
        'period_inquiries': 2,
        'conversion_percent': 5,
      });

      expect(summary.sellerType, SellerType.dealer);
      expect(summary.verifiedDealer, isTrue);
      expect(summary.activeCount, 2);
      expect(summary.soldCount, 1);
      expect(summary.periodViews, 40);
      expect(summary.currentFavorites, 3);
      expect(summary.periodInquiries, 2);
      expect(summary.conversionPercent, 5);
    });

    test('maps nullable conversion and unknown seller type to private', () {
      final summary = sellerAnalyticsSummaryFromRow({
        'seller_type': 'something-else',
        'verified_dealer': 'f',
        'active_count': '0',
        'sold_count': 0.0,
        'period_views': 0,
        'current_favorites': 0,
        'period_inquiries': 0,
        'conversion_percent': null,
      });

      expect(summary.sellerType, SellerType.private);
      expect(summary.verifiedDealer, isFalse);
      expect(summary.conversionPercent, isNull);
    });

    test('parses numeric conversion from string and double', () {
      expect(parseSellerAnalyticsNullablePercent('4.2'), 4.2);
      expect(parseSellerAnalyticsNullablePercent(4.2), 4.2);
      expect(parseSellerAnalyticsNullablePercent(''), isNull);
      expect(parseSellerAnalyticsNullablePercent(null), isNull);
    });

    test('rejects unparseable conversion_percent', () {
      expect(
        () => parseSellerAnalyticsNullablePercent('not-a-number'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('sellerAnalyticsDailyPointFromRow', () {
    test('maps date string and views', () {
      final point = sellerAnalyticsDailyPointFromRow({
        'metric_date': '2026-09-01',
        'views': '12',
      });
      expect(point.date, DateTime(2026, 9, 1));
      expect(point.views, 12);
    });

    test('maps DateTime metric_date to calendar day', () {
      final point = sellerAnalyticsDailyPointFromRow({
        'metric_date': DateTime.utc(2026, 9, 13, 21, 15),
        'views': 0,
      });
      expect(point.date.year, 2026);
      expect(point.date.month, 9);
      expect(point.date.day, 13);
      expect(point.views, 0);
    });
  });

  group('sellerListingPerformanceFromRow', () {
    test('maps nullable sold_at and listing identity', () {
      final listing = sellerListingPerformanceFromRow({
        'listing_id': '11111111-2222-3333-4444-555555555555',
        'title': 'BMW 320d, 2018',
        'status': 'sold',
        'created_at': '2026-08-01T10:00:00+03:00',
        'sold_at': null,
        'make': 'BMW',
        'model': '320d',
        'year': 2018.0,
        'period_views': 9,
        'current_favorites': 1,
        'period_inquiries': 0,
      });

      expect(listing.listingId, '11111111-2222-3333-4444-555555555555');
      expect(listing.status, ListingStatus.sold);
      expect(listing.soldAt, isNull);
      expect(listing.soldDurationDays(), isNull);
      expect(listing.displayTitle, 'BMW 320d, 2018');
      expect(listing.periodViews, 9);
    });

    test('maps sold_at when present', () {
      final listing = sellerListingPerformanceFromRow({
        'listing_id': 'id-1',
        'title': 'Mazda 6',
        'status': 'sold',
        'created_at': DateTime(2026, 8, 1),
        'sold_at': DateTime(2026, 8, 11),
        'make': 'Mazda',
        'model': '6',
        'year': 2016,
        'period_views': 0,
        'current_favorites': 0,
        'period_inquiries': 0,
      });

      expect(listing.soldAt, DateTime(2026, 8, 11));
      expect(listing.soldDurationDays(), 10);
    });
  });

  group('seller engagement mapping', () {
    test('maps summary action counts', () {
      final summary = sellerEngagementSummaryFromRow({
        'period_impressions': 10,
        'period_phone_actions': 2,
        'period_whatsapp_actions': 3,
        'period_telegram_actions': 1,
        'period_shares': 4,
      });
      expect(summary.periodImpressions, 10);
      expect(summary.periodContactActions, 6);
      expect(summary.periodShares, 4);
    });

    test(
      'maps listing engagement and missing identity columns stay absent',
      () {
        final row = sellerListingEngagementFromRow({
          'listing_id': 'listing-1',
          'period_impressions': 8,
          'period_phone_actions': 1,
          'period_whatsapp_actions': 0,
          'period_telegram_actions': 2,
          'period_shares': 1,
          'viewer_hash': 'secret',
        });
        expect(row.listingId, 'listing-1');
        expect(row.periodContactActions, 3);
        expect(row.props.contains('secret'), isFalse);
      },
    );
  });

  group('seller demand mapping', () {
    test('maps visible inventory count', () {
      final demand = sellerInventoryDemandFromRow({
        'matching_users': 18,
        'is_suppressed': false,
      });
      expect(demand.matchingUsers, 18);
      expect(demand.isSuppressed, isFalse);
      expect(demand.isVisibleCount, isTrue);
    });

    test('maps zero inventory demand', () {
      final demand = sellerInventoryDemandFromRow({
        'matching_users': 0,
        'is_suppressed': false,
      });
      expect(demand.isZero, isTrue);
      expect(demand.matchingUsers, 0);
    });

    test('maps suppressed inventory demand as null + true', () {
      final demand = sellerInventoryDemandFromRow({
        'matching_users': null,
        'is_suppressed': true,
      });
      expect(demand.matchingUsers, isNull);
      expect(demand.isPrivacySuppressed, isTrue);
    });

    test('rejects null matching_users when not suppressed', () {
      expect(
        () => sellerInventoryDemandFromRow({
          'matching_users': null,
          'is_suppressed': false,
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('rejects leaked 1-4 matching_users', () {
      expect(
        () => sellerInventoryDemandFromRow({
          'matching_users': 3,
          'is_suppressed': false,
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('rejects suppressed payload that still includes a count', () {
      expect(
        () => sellerInventoryDemandFromRow({
          'matching_users': 5,
          'is_suppressed': true,
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('maps listing demand rows including listing_id', () {
      final row = sellerListingDemandFromRow({
        'listing_id': 'listing-1',
        'matching_users': 5,
        'is_suppressed': false,
        'user_id': 'secret',
      });
      expect(row.listingId, 'listing-1');
      expect(row.matchingUsers, 5);
      expect(row.isVisibleCount, isTrue);
      expect(row.props.contains('secret'), isFalse);
    });

    test('maps suppressed listing demand', () {
      final row = sellerListingDemandFromRow({
        'listing_id': 'listing-2',
        'matching_users': null,
        'is_suppressed': true,
      });
      expect(row.isPrivacySuppressed, isTrue);
    });

    test('maps zero listing demand', () {
      final row = sellerListingDemandFromRow({
        'listing_id': 'listing-3',
        'matching_users': 0,
        'is_suppressed': false,
      });
      expect(row.isZero, isTrue);
    });
  });
}
