import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_daily_point.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_period.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_snapshot.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_analytics_summary.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_demand_snapshot.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_engagement_snapshot.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_engagement_summary.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_inventory_demand.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_demand.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_engagement.dart';
import 'package:carzon/features/seller_analytics/domain/entities/seller_listing_performance.dart';
import 'package:carzon/features/seller_analytics/domain/usecases/get_seller_analytics.dart';
import 'package:carzon/features/seller_analytics/domain/usecases/get_seller_demand.dart';
import 'package:carzon/features/seller_analytics/domain/usecases/get_seller_engagement.dart';
import 'package:carzon/features/seller_analytics/presentation/bloc/seller_analytics_cubit.dart';
import 'package:carzon/features/seller_analytics/presentation/bloc/seller_analytics_state.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetSellerAnalytics extends Mock implements GetSellerAnalytics {}

class _MockGetSellerEngagement extends Mock implements GetSellerEngagement {}

class _MockGetSellerDemand extends Mock implements GetSellerDemand {}

SellerDemandSnapshot _demand({
  int? matchingUsers = 0,
  bool suppressed = false,
  String listingId = 'listing-1',
}) {
  return SellerDemandSnapshot(
    inventory: SellerInventoryDemand(
      matchingUsers: matchingUsers,
      isSuppressed: suppressed,
    ),
    listings: [
      SellerListingDemand(
        listingId: listingId,
        matchingUsers: matchingUsers,
        isSuppressed: suppressed,
      ),
    ],
  );
}

SellerEngagementSnapshot _engagement({
  int impressions = 0,
  int phone = 0,
  String listingId = 'listing-1',
}) {
  return SellerEngagementSnapshot(
    summary: SellerEngagementSummary(
      periodImpressions: impressions,
      periodPhoneActions: phone,
      periodWhatsappActions: 0,
      periodTelegramActions: 0,
      periodShares: 0,
    ),
    listings: [
      SellerListingEngagement(
        listingId: listingId,
        periodImpressions: impressions,
        periodPhoneActions: phone,
        periodWhatsappActions: 0,
        periodTelegramActions: 0,
        periodShares: 0,
      ),
    ],
  );
}

SellerAnalyticsSnapshot _snapshot({
  SellerAnalyticsPeriod period = SellerAnalyticsPeriod.days30,
  int views = 10,
  SellerType sellerType = SellerType.private,
  int activeCount = 1,
  int soldCount = 0,
}) {
  return SellerAnalyticsSnapshot(
    period: period,
    summary: SellerAnalyticsSummary(
      sellerType: sellerType,
      verifiedDealer: sellerType == SellerType.dealer,
      activeCount: activeCount,
      soldCount: soldCount,
      periodViews: views,
      currentFavorites: 2,
      periodInquiries: 1,
      conversionPercent: 10,
    ),
    daily: [
      SellerAnalyticsDailyPoint(date: DateTime(2026, 9, 1), views: views),
    ],
    listings: [
      SellerListingPerformance(
        listingId: 'listing-1',
        title: 'BMW 320d',
        status: ListingStatus.active,
        createdAt: DateTime(2026, 8, 1),
        make: 'BMW',
        model: '320d',
        year: 2018,
        periodViews: views,
        currentFavorites: 2,
        periodInquiries: 1,
      ),
    ],
  );
}

void main() {
  late _MockGetSellerAnalytics getSellerAnalytics;
  late _MockGetSellerEngagement getSellerEngagement;
  late _MockGetSellerDemand getSellerDemand;

  SellerAnalyticsCubit buildCubit() => SellerAnalyticsCubit(
    getSellerAnalytics: getSellerAnalytics,
    getSellerEngagement: getSellerEngagement,
    getSellerDemand: getSellerDemand,
  );

  setUpAll(() {
    registerFallbackValue(SellerAnalyticsPeriod.days30);
  });

  setUp(() {
    getSellerAnalytics = _MockGetSellerAnalytics();
    getSellerEngagement = _MockGetSellerEngagement();
    getSellerDemand = _MockGetSellerDemand();
    when(
      () => getSellerEngagement(any()),
    ).thenAnswer((_) async => Success(_engagement()));
    when(() => getSellerDemand()).thenAnswer((_) async => Success(_demand()));
  });

  test('default period is 30 days', () {
    final cubit = buildCubit();
    expect(cubit.state.period, SellerAnalyticsPeriod.days30);
    expect(cubit.state.status, SellerAnalyticsStatus.initial);
    cubit.close();
  });

  blocTest<SellerAnalyticsCubit, SellerAnalyticsState>(
    'load emits loaded snapshot for default 30 days',
    build: () {
      when(
        () => getSellerAnalytics(SellerAnalyticsPeriod.days30),
      ).thenAnswer((_) async => Success(_snapshot()));
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const SellerAnalyticsState(status: SellerAnalyticsStatus.loading),
      SellerAnalyticsState(
        status: SellerAnalyticsStatus.loaded,
        summary: _snapshot().summary,
        daily: _snapshot().daily,
        listings: _snapshot().listings,
      ),
    ],
  );

  blocTest<SellerAnalyticsCubit, SellerAnalyticsState>(
    'selecting 7 and 90 days reloads period-dependent analytics',
    build: () {
      when(() => getSellerAnalytics(any())).thenAnswer((invocation) async {
        final period =
            invocation.positionalArguments.first as SellerAnalyticsPeriod;
        return Success(_snapshot(period: period, views: period.days));
      });
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.selectPeriod(SellerAnalyticsPeriod.days7);
      await cubit.selectPeriod(SellerAnalyticsPeriod.days90);
    },
    verify: (cubit) {
      verify(() => getSellerAnalytics(SellerAnalyticsPeriod.days30)).called(1);
      verify(() => getSellerAnalytics(SellerAnalyticsPeriod.days7)).called(1);
      verify(() => getSellerAnalytics(SellerAnalyticsPeriod.days90)).called(1);
      expect(cubit.state.period, SellerAnalyticsPeriod.days90);
      expect(cubit.state.summary?.periodViews, 90);
    },
  );

  blocTest<SellerAnalyticsCubit, SellerAnalyticsState>(
    'RPC error produces error state without leftover payload',
    build: () {
      when(() => getSellerAnalytics(any())).thenAnswer(
        (_) async => const FailureResult(ServerFailure('rpc failed')),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const SellerAnalyticsState(status: SellerAnalyticsStatus.loading),
      const SellerAnalyticsState(status: SellerAnalyticsStatus.error),
    ],
  );

  blocTest<SellerAnalyticsCubit, SellerAnalyticsState>(
    'retry retains the selected period',
    build: () {
      when(() => getSellerAnalytics(SellerAnalyticsPeriod.days7)).thenAnswer(
        (_) async =>
            Success(_snapshot(period: SellerAnalyticsPeriod.days7, views: 7)),
      );
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load(period: SellerAnalyticsPeriod.days7);
      await cubit.retry();
    },
    verify: (cubit) {
      verify(() => getSellerAnalytics(SellerAnalyticsPeriod.days7)).called(2);
      expect(cubit.state.period, SellerAnalyticsPeriod.days7);
    },
  );

  test(
    'stale previous-period result cannot overwrite newer selection',
    () async {
      final slower = Completer<Result<SellerAnalyticsSnapshot>>();
      final faster = Completer<Result<SellerAnalyticsSnapshot>>();
      when(
        () => getSellerAnalytics(SellerAnalyticsPeriod.days30),
      ).thenAnswer((_) => slower.future);
      when(
        () => getSellerAnalytics(SellerAnalyticsPeriod.days7),
      ).thenAnswer((_) => faster.future);

      final cubit = buildCubit();
      unawaited(cubit.load());
      await Future<void>.delayed(Duration.zero);
      unawaited(cubit.selectPeriod(SellerAnalyticsPeriod.days7));
      await Future<void>.delayed(Duration.zero);

      slower.complete(
        Success(_snapshot(period: SellerAnalyticsPeriod.days30, views: 30)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SellerAnalyticsStatus.loading);
      expect(cubit.state.period, SellerAnalyticsPeriod.days7);
      expect(cubit.state.summary, isNull);

      faster.complete(
        Success(_snapshot(period: SellerAnalyticsPeriod.days7, views: 7)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SellerAnalyticsStatus.loaded);
      expect(cubit.state.period, SellerAnalyticsPeriod.days7);
      expect(cubit.state.summary?.periodViews, 7);
      await cubit.close();
    },
  );

  test('failed new period does not keep previous period payload', () async {
    when(
      () => getSellerAnalytics(SellerAnalyticsPeriod.days30),
    ).thenAnswer((_) async => Success(_snapshot(views: 30)));
    when(() => getSellerAnalytics(SellerAnalyticsPeriod.days7)).thenAnswer(
      (_) async => const FailureResult(ServerFailure('7-day failed')),
    );

    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.summary?.periodViews, 30);
    await cubit.selectPeriod(SellerAnalyticsPeriod.days7);

    expect(cubit.state.status, SellerAnalyticsStatus.error);
    expect(cubit.state.period, SellerAnalyticsPeriod.days7);
    expect(cubit.state.summary, isNull);
    await cubit.close();
  });

  test('private seller does not require engagement RPC', () async {
    when(
      () => getSellerAnalytics(any()),
    ).thenAnswer((_) async => Success(_snapshot()));
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.engagementSummary, isNull);
    verifyNever(() => getSellerEngagement(any()));
    await cubit.close();
  });

  test('dealer loads engagement summary and listings', () async {
    when(() => getSellerAnalytics(any())).thenAnswer(
      (_) async => Success(_snapshot(sellerType: SellerType.dealer)),
    );
    when(
      () => getSellerEngagement(SellerAnalyticsPeriod.days30),
    ).thenAnswer((_) async => Success(_engagement(impressions: 9, phone: 2)));
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.engagementSummary?.periodImpressions, 9);
    expect(cubit.state.engagementFor('listing-1').periodPhoneActions, 2);
    expect(cubit.state.engagementFor('missing').periodImpressions, 0);
    verify(() => getSellerEngagement(SellerAnalyticsPeriod.days30)).called(1);
    await cubit.close();
  });

  test('dealer engagement failure produces error state', () async {
    when(() => getSellerAnalytics(any())).thenAnswer(
      (_) async => Success(_snapshot(sellerType: SellerType.dealer)),
    );
    when(() => getSellerEngagement(any())).thenAnswer(
      (_) async => const FailureResult(ServerFailure('engagement down')),
    );
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.status, SellerAnalyticsStatus.error);
    expect(cubit.state.engagementSummary, isNull);
    await cubit.close();
  });

  test('dealer retry retains period for engagement reload', () async {
    when(() => getSellerAnalytics(SellerAnalyticsPeriod.days7)).thenAnswer(
      (_) async => Success(
        _snapshot(
          period: SellerAnalyticsPeriod.days7,
          sellerType: SellerType.dealer,
        ),
      ),
    );
    when(
      () => getSellerEngagement(SellerAnalyticsPeriod.days7),
    ).thenAnswer((_) async => Success(_engagement(impressions: 7)));
    final cubit = buildCubit();
    await cubit.load(period: SellerAnalyticsPeriod.days7);
    await cubit.retry();
    verify(() => getSellerEngagement(SellerAnalyticsPeriod.days7)).called(2);
    expect(cubit.state.period, SellerAnalyticsPeriod.days7);
    await cubit.close();
  });

  test('period switch loads matching engagement window', () async {
    when(() => getSellerAnalytics(any())).thenAnswer((invocation) async {
      final period =
          invocation.positionalArguments.first as SellerAnalyticsPeriod;
      return Success(
        _snapshot(
          period: period,
          sellerType: SellerType.dealer,
          views: period.days,
        ),
      );
    });
    when(() => getSellerEngagement(any())).thenAnswer((invocation) async {
      final period =
          invocation.positionalArguments.first as SellerAnalyticsPeriod;
      return Success(_engagement(impressions: period.days));
    });
    final cubit = buildCubit();
    await cubit.load();
    await cubit.selectPeriod(SellerAnalyticsPeriod.days7);
    await cubit.selectPeriod(SellerAnalyticsPeriod.days90);
    verify(() => getSellerEngagement(SellerAnalyticsPeriod.days7)).called(1);
    verify(() => getSellerEngagement(SellerAnalyticsPeriod.days90)).called(1);
    expect(cubit.state.engagementSummary?.periodImpressions, 90);
    await cubit.close();
  });

  test('stale older engagement cannot overwrite newer period', () async {
    final slowerAnalytics = Completer<Result<SellerAnalyticsSnapshot>>();
    final fasterAnalytics = Completer<Result<SellerAnalyticsSnapshot>>();
    final slowerEngagement = Completer<Result<SellerEngagementSnapshot>>();
    final fasterEngagement = Completer<Result<SellerEngagementSnapshot>>();
    when(
      () => getSellerAnalytics(SellerAnalyticsPeriod.days30),
    ).thenAnswer((_) => slowerAnalytics.future);
    when(
      () => getSellerAnalytics(SellerAnalyticsPeriod.days7),
    ).thenAnswer((_) => fasterAnalytics.future);
    when(
      () => getSellerEngagement(SellerAnalyticsPeriod.days30),
    ).thenAnswer((_) => slowerEngagement.future);
    when(
      () => getSellerEngagement(SellerAnalyticsPeriod.days7),
    ).thenAnswer((_) => fasterEngagement.future);

    final cubit = buildCubit();
    unawaited(cubit.load());
    await Future<void>.delayed(Duration.zero);
    unawaited(cubit.selectPeriod(SellerAnalyticsPeriod.days7));
    await Future<void>.delayed(Duration.zero);

    slowerAnalytics.complete(
      Success(_snapshot(sellerType: SellerType.dealer, views: 30)),
    );
    await Future<void>.delayed(Duration.zero);
    slowerEngagement.complete(Success(_engagement(impressions: 30)));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, SellerAnalyticsStatus.loading);
    expect(cubit.state.period, SellerAnalyticsPeriod.days7);
    expect(cubit.state.engagementSummary, isNull);

    fasterAnalytics.complete(
      Success(
        _snapshot(
          period: SellerAnalyticsPeriod.days7,
          sellerType: SellerType.dealer,
          views: 7,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    fasterEngagement.complete(Success(_engagement(impressions: 7)));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.period, SellerAnalyticsPeriod.days7);
    expect(cubit.state.engagementSummary?.periodImpressions, 7);
    await cubit.close();
  });

  test('private seller does not call demand RPC', () async {
    when(
      () => getSellerAnalytics(any()),
    ).thenAnswer((_) async => Success(_snapshot()));
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.demandStatus, SellerDemandLoadStatus.idle);
    verifyNever(() => getSellerDemand());
    await cubit.close();
  });

  test('dealer loads portfolio and listing demand', () async {
    when(() => getSellerAnalytics(any())).thenAnswer(
      (_) async => Success(_snapshot(sellerType: SellerType.dealer)),
    );
    when(
      () => getSellerDemand(),
    ).thenAnswer((_) async => Success(_demand(matchingUsers: 8)));
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.demandStatus, SellerDemandLoadStatus.loaded);
    expect(cubit.state.inventoryDemand?.matchingUsers, 8);
    expect(cubit.state.demandFor('listing-1')?.matchingUsers, 8);
    verify(() => getSellerDemand()).called(1);
    await cubit.close();
  });

  test('dealer demand failure does not fail the dashboard', () async {
    when(() => getSellerAnalytics(any())).thenAnswer(
      (_) async => Success(_snapshot(sellerType: SellerType.dealer)),
    );
    when(() => getSellerDemand()).thenAnswer(
      (_) async => const FailureResult(ServerFailure('demand down')),
    );
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.engagementSummary, isNotNull);
    expect(cubit.state.demandStatus, SellerDemandLoadStatus.unavailable);
    expect(cubit.state.inventoryDemand, isNull);
    await cubit.close();
  });

  test('period change retains demand and does not reload it', () async {
    when(() => getSellerAnalytics(any())).thenAnswer((invocation) async {
      final period =
          invocation.positionalArguments.first as SellerAnalyticsPeriod;
      return Success(
        _snapshot(
          period: period,
          sellerType: SellerType.dealer,
          views: period.days,
        ),
      );
    });
    when(
      () => getSellerDemand(),
    ).thenAnswer((_) async => Success(_demand(matchingUsers: 11)));
    final cubit = buildCubit();
    await cubit.load();
    await cubit.selectPeriod(SellerAnalyticsPeriod.days7);
    await cubit.selectPeriod(SellerAnalyticsPeriod.days90);
    verify(() => getSellerDemand()).called(1);
    expect(cubit.state.period, SellerAnalyticsPeriod.days90);
    expect(cubit.state.summary?.periodViews, 90);
    expect(cubit.state.inventoryDemand?.matchingUsers, 11);
    await cubit.close();
  });

  test('dealer with zero active listings does not call demand', () async {
    when(() => getSellerAnalytics(any())).thenAnswer(
      (_) async => Success(
        _snapshot(sellerType: SellerType.dealer, activeCount: 0, soldCount: 1),
      ),
    );
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.demandStatus, SellerDemandLoadStatus.idle);
    verifyNever(() => getSellerDemand());
    await cubit.close();
  });

  test('retryDemand reloads only demand after unavailable', () async {
    when(() => getSellerAnalytics(any())).thenAnswer(
      (_) async => Success(_snapshot(sellerType: SellerType.dealer)),
    );
    when(() => getSellerDemand()).thenAnswer(
      (_) async => const FailureResult(ServerFailure('demand down')),
    );
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state.demandStatus, SellerDemandLoadStatus.unavailable);
    when(
      () => getSellerDemand(),
    ).thenAnswer((_) async => Success(_demand(matchingUsers: 9)));
    await cubit.retryDemand();
    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.demandStatus, SellerDemandLoadStatus.loaded);
    expect(cubit.state.inventoryDemand?.matchingUsers, 9);
    verify(() => getSellerAnalytics(any())).called(1);
    await cubit.close();
  });

  test('stale older demand cannot overwrite newer period', () async {
    final slowerDemand = Completer<Result<SellerDemandSnapshot>>();
    final fasterDemand = Completer<Result<SellerDemandSnapshot>>();
    var demandCalls = 0;
    when(() => getSellerAnalytics(any())).thenAnswer((invocation) async {
      final period =
          invocation.positionalArguments.first as SellerAnalyticsPeriod;
      return Success(
        _snapshot(
          period: period,
          sellerType: SellerType.dealer,
          views: period.days,
        ),
      );
    });
    when(() => getSellerDemand()).thenAnswer((_) {
      demandCalls += 1;
      if (demandCalls == 1) return slowerDemand.future;
      return fasterDemand.future;
    });

    final cubit = buildCubit();
    unawaited(cubit.load());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.demandStatus, SellerDemandLoadStatus.loading);

    unawaited(cubit.selectPeriod(SellerAnalyticsPeriod.days7));
    await Future<void>.delayed(Duration.zero);
    slowerDemand.complete(Success(_demand(matchingUsers: 30)));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.period, SellerAnalyticsPeriod.days7);
    expect(cubit.state.inventoryDemand, isNull);

    fasterDemand.complete(Success(_demand(matchingUsers: 7)));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, SellerAnalyticsStatus.loaded);
    expect(cubit.state.period, SellerAnalyticsPeriod.days7);
    expect(cubit.state.inventoryDemand?.matchingUsers, 7);
    await cubit.close();
  });
}
