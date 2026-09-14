import 'dart:io';

import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/seller_analytics/data/datasources/seller_analytics_remote_datasource.dart';
import 'package:carzon/features/seller_analytics/data/repositories/seller_analytics_repository_impl.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_daily_point.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_period.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_snapshot.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_summary.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_demand_snapshot.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_engagement_snapshot.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_engagement_summary.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_inventory_demand.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_demand.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements SellerAnalyticsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late SellerAnalyticsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(SellerAnalyticsPeriod.days30);
  });

  setUp(() {
    remote = _MockRemote();
    repository = SellerAnalyticsRepositoryImpl(remote);
  });

  test('load succeeds when all RPCs succeed', () async {
    const summary = SellerAnalyticsSummary(
      sellerType: SellerType.private,
      verifiedDealer: false,
      activeCount: 0,
      soldCount: 0,
      periodViews: 0,
      currentFavorites: 0,
      periodInquiries: 0,
    );
    when(
      () => remote.fetchSummary(SellerAnalyticsPeriod.days30),
    ).thenAnswer((_) async => summary);
    when(() => remote.fetchDaily(SellerAnalyticsPeriod.days30)).thenAnswer(
      (_) async => [
        SellerAnalyticsDailyPoint(date: DateTime(2026, 9, 1), views: 0),
      ],
    );
    when(
      () => remote.fetchListings(SellerAnalyticsPeriod.days30),
    ).thenAnswer((_) async => const []);

    final result = await repository.load(SellerAnalyticsPeriod.days30);
    expect(result, isA<Success>());
    final snapshot = (result as Success).value;
    expect(snapshot.summary, summary);
    expect(snapshot.daily, hasLength(1));
    expect(snapshot.listings, isEmpty);
  });

  test('does not swallow an individual RPC failure', () async {
    when(() => remote.fetchSummary(any())).thenAnswer(
      (_) async => const SellerAnalyticsSummary(
        sellerType: SellerType.private,
        verifiedDealer: false,
        activeCount: 1,
        soldCount: 0,
        periodViews: 4,
        currentFavorites: 0,
        periodInquiries: 0,
      ),
    );
    when(
      () => remote.fetchDaily(any()),
    ).thenThrow(ServerException('daily rpc failed'));
    when(() => remote.fetchListings(any())).thenAnswer((_) async => const []);

    final result = await repository.load(SellerAnalyticsPeriod.days7);
    expect(result, isA<FailureResult<SellerAnalyticsSnapshot>>());
    final failure = (result as FailureResult<SellerAnalyticsSnapshot>).failure;
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'daily rpc failed');
  });

  test('loadEngagement succeeds without a seller id parameter', () async {
    when(
      () => remote.fetchEngagementSummary(SellerAnalyticsPeriod.days30),
    ).thenAnswer(
      (_) async => const SellerEngagementSummary(
        periodImpressions: 4,
        periodPhoneActions: 1,
        periodWhatsappActions: 0,
        periodTelegramActions: 0,
        periodShares: 2,
      ),
    );
    when(
      () => remote.fetchEngagementListings(SellerAnalyticsPeriod.days30),
    ).thenAnswer((_) async => const []);

    final result = await repository.loadEngagement(
      SellerAnalyticsPeriod.days30,
    );
    expect(result, isA<Success>());
    verify(
      () => remote.fetchEngagementSummary(SellerAnalyticsPeriod.days30),
    ).called(1);
    verify(
      () => remote.fetchEngagementListings(SellerAnalyticsPeriod.days30),
    ).called(1);
  });

  test('loadEngagement does not swallow an RPC failure', () async {
    when(
      () => remote.fetchEngagementSummary(any()),
    ).thenThrow(ServerException('engagement summary failed'));
    when(
      () => remote.fetchEngagementListings(any()),
    ).thenAnswer((_) async => const []);

    final result = await repository.loadEngagement(SellerAnalyticsPeriod.days7);
    expect(result, isA<FailureResult<SellerEngagementSnapshot>>());
  });

  test('loadDemand succeeds without a seller id parameter', () async {
    when(() => remote.fetchInventoryDemand()).thenAnswer(
      (_) async =>
          const SellerInventoryDemand(matchingUsers: 6, isSuppressed: false),
    );
    when(() => remote.fetchListingDemand()).thenAnswer(
      (_) async => const [
        SellerListingDemand(
          listingId: 'listing-1',
          matchingUsers: 6,
          isSuppressed: false,
        ),
      ],
    );

    final result = await repository.loadDemand();
    expect(result, isA<Success>());
    final snapshot = (result as Success<SellerDemandSnapshot>).value;
    expect(snapshot.inventory.matchingUsers, 6);
    expect(snapshot.listings, hasLength(1));
    verify(() => remote.fetchInventoryDemand()).called(1);
    verify(() => remote.fetchListingDemand()).called(1);
  });

  test('loadDemand maps zero, suppressed, and visible payloads', () async {
    when(() => remote.fetchInventoryDemand()).thenAnswer(
      (_) async =>
          const SellerInventoryDemand(matchingUsers: null, isSuppressed: true),
    );
    when(() => remote.fetchListingDemand()).thenAnswer(
      (_) async => const [
        SellerListingDemand(
          listingId: 'zero',
          matchingUsers: 0,
          isSuppressed: false,
        ),
        SellerListingDemand(
          listingId: 'hidden',
          matchingUsers: null,
          isSuppressed: true,
        ),
        SellerListingDemand(
          listingId: 'visible',
          matchingUsers: 5,
          isSuppressed: false,
        ),
      ],
    );

    final result = await repository.loadDemand();
    final snapshot = (result as Success<SellerDemandSnapshot>).value;
    expect(snapshot.inventory.isPrivacySuppressed, isTrue);
    expect(snapshot.listings[0].isZero, isTrue);
    expect(snapshot.listings[1].isPrivacySuppressed, isTrue);
    expect(snapshot.listings[2].matchingUsers, 5);
  });

  test('loadDemand does not swallow an RPC failure', () async {
    when(
      () => remote.fetchInventoryDemand(),
    ).thenThrow(ServerException('inventory demand failed'));
    when(() => remote.fetchListingDemand()).thenAnswer((_) async => const []);

    final result = await repository.loadDemand();
    expect(result, isA<FailureResult<SellerDemandSnapshot>>());
  });

  test('demand RPC names stay exact and take no seller id', () {
    final source = File(
      'lib/features/seller_analytics/data/datasources/supabase_seller_analytics_remote_datasource.dart',
    ).readAsStringSync();
    expect(source, contains("'get_my_seller_listing_demand'"));
    expect(source, contains("'get_my_seller_inventory_demand'"));
    expect(source, isNot(contains('p_seller_id')));
    expect(source, isNot(contains('saved_searches')));
  });
}
