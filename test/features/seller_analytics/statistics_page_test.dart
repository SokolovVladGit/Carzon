import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/core/widgets/auth_required_prompt.dart';
import 'package:carzon/core/widgets/empty_state_view.dart';
import 'package:carzon/core/widgets/error_view.dart';
import 'package:carzon/core/widgets/loading_view.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
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
import 'package:carzon/features/seller_analytics/presentation/pages/statistics_page.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/dealer_statistics_content.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/private_statistics_content.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/statistics_demand_cards.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/statistics_engagement_cards.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/statistics_period_selector.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/statistics_summary_metrics.dart';
import 'package:carzon/features/seller_analytics/presentation/widgets/statistics_views_sparkline.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockGetSellerAnalytics extends Mock implements GetSellerAnalytics {}

class _MockGetSellerEngagement extends Mock implements GetSellerEngagement {}

class _MockGetSellerDemand extends Mock implements GetSellerDemand {}

SellerDemandSnapshot _demand({
  int? matchingUsers = 0,
  bool suppressed = false,
  List<SellerListingDemand>? listings,
}) {
  return SellerDemandSnapshot(
    inventory: SellerInventoryDemand(
      matchingUsers: matchingUsers,
      isSuppressed: suppressed,
    ),
    listings:
        listings ??
        [
          SellerListingDemand(
            listingId: 'listing-active',
            matchingUsers: matchingUsers,
            isSuppressed: suppressed,
          ),
        ],
  );
}

SellerEngagementSnapshot _engagement({
  int impressions = 4,
  int phone = 1,
  int whatsapp = 1,
  int telegram = 0,
  int shares = 2,
}) {
  return SellerEngagementSnapshot(
    summary: SellerEngagementSummary(
      periodImpressions: impressions,
      periodPhoneActions: phone,
      periodWhatsappActions: whatsapp,
      periodTelegramActions: telegram,
      periodShares: shares,
    ),
    listings: [
      SellerListingEngagement(
        listingId: 'listing-active',
        periodImpressions: impressions,
        periodPhoneActions: phone,
        periodWhatsappActions: whatsapp,
        periodTelegramActions: telegram,
        periodShares: shares,
      ),
    ],
  );
}

SellerAnalyticsSnapshot _snapshot({
  SellerType sellerType = SellerType.private,
  int activeCount = 1,
  int soldCount = 1,
  int views = 12,
  int favorites = 3,
  int inquiries = 1,
  double? conversion = 8.3,
  List<SellerListingPerformance>? listings,
}) {
  return SellerAnalyticsSnapshot(
    period: SellerAnalyticsPeriod.days30,
    summary: SellerAnalyticsSummary(
      sellerType: sellerType,
      verifiedDealer: sellerType == SellerType.dealer,
      activeCount: activeCount,
      soldCount: soldCount,
      periodViews: views,
      currentFavorites: favorites,
      periodInquiries: inquiries,
      conversionPercent: conversion,
    ),
    daily: [
      for (var i = 0; i < 7; i++)
        SellerAnalyticsDailyPoint(
          date: DateTime(2026, 9, 1 + i),
          views: views == 0 ? 0 : i,
        ),
    ],
    listings:
        listings ??
        [
          SellerListingPerformance(
            listingId: 'listing-active',
            title: 'BMW 320d, 2018',
            status: ListingStatus.active,
            createdAt: DateTime(2026, 8, 1),
            make: 'BMW',
            model: '320d',
            year: 2018,
            periodViews: views,
            currentFavorites: favorites,
            periodInquiries: inquiries,
          ),
          SellerListingPerformance(
            listingId: 'listing-sold',
            title: 'Mazda 6, 2016',
            status: ListingStatus.sold,
            createdAt: DateTime(2026, 7, 1),
            soldAt: DateTime(2026, 7, 20),
            make: 'Mazda',
            model: '6',
            year: 2016,
            periodViews: views == 0 ? 0 : 2,
            currentFavorites: 0,
            periodInquiries: 0,
          ),
        ],
  );
}

SellerListingPerformance _listing({
  required String id,
  String title = 'Car',
  ListingStatus status = ListingStatus.active,
  int views = 1,
  int favorites = 0,
  int inquiries = 0,
  DateTime? soldAt,
}) {
  return SellerListingPerformance(
    listingId: id,
    title: title,
    status: status,
    createdAt: DateTime(2026, 8, 1),
    soldAt: soldAt,
    make: 'BMW',
    model: title,
    year: 2018,
    periodViews: views,
    currentFavorites: favorites,
    periodInquiries: inquiries,
  );
}

SellerAnalyticsCubit _cubit(
  _MockGetSellerAnalytics useCase,
  _MockGetSellerEngagement engagement,
  _MockGetSellerDemand demand, {
  Result<SellerAnalyticsSnapshot>? result,
  Result<SellerEngagementSnapshot>? engagementResult,
  Result<SellerDemandSnapshot>? demandResult,
}) {
  when(
    () => useCase(any()),
  ).thenAnswer((_) async => result ?? Success(_snapshot()));
  when(
    () => engagement(any()),
  ).thenAnswer((_) async => engagementResult ?? Success(_engagement()));
  when(
    () => demand(),
  ).thenAnswer((_) async => demandResult ?? Success(_demand()));
  return SellerAnalyticsCubit(
    getSellerAnalytics: useCase,
    getSellerEngagement: engagement,
    getSellerDemand: demand,
  )..load();
}

SellerAnalyticsCubit _makeCubit(
  _MockGetSellerAnalytics useCase,
  _MockGetSellerEngagement engagement,
  _MockGetSellerDemand demand,
) {
  return SellerAnalyticsCubit(
    getSellerAnalytics: useCase,
    getSellerEngagement: engagement,
    getSellerDemand: demand,
  );
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrapChrome(
  SellerAnalyticsCubit cubit, {
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    locale: const Locale('ru'),
    themeMode: themeMode,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: statisticsTestHarness(cubit: cubit, child: const StatisticsChrome()),
  );
}

Widget _wrapSignedOut(AuthCubit auth) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: auth,
      child: const StatisticsPage(),
    ),
  );
}

void main() {
  late _MockGetSellerAnalytics useCase;
  late _MockGetSellerEngagement engagement;
  late _MockGetSellerDemand demand;
  final l10n = ruStrings();

  setUpAll(() {
    registerFallbackValue(SellerAnalyticsPeriod.days30);
  });

  setUp(() {
    useCase = _MockGetSellerAnalytics();
    engagement = _MockGetSellerEngagement();
    demand = _MockGetSellerDemand();
    when(
      () => engagement(any()),
    ).thenAnswer((_) async => Success(_engagement()));
    when(() => demand()).thenAnswer((_) async => Success(_demand()));
  });

  testWidgets('unauthenticated page shows AuthRequiredPrompt', (tester) async {
    final auth = _MockAuthCubit();
    when(() => auth.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await tester.pumpWidget(_wrapSignedOut(auth));
    await tester.pump();

    expect(find.byType(AuthRequiredPrompt), findsOneWidget);
    expect(find.text(l10n.statisticsSignInRequired), findsOneWidget);
    expect(find.text(l10n.commonSignIn), findsOneWidget);
    expect(find.byType(StatisticsSummaryMetrics), findsNothing);
  });

  testWidgets('loading state', (tester) async {
    when(
      () => useCase(any()),
    ).thenAnswer((_) => Completer<Result<SellerAnalyticsSnapshot>>().future);
    final cubit = _makeCubit(useCase, engagement, demand)..load();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
    await cubit.close();
  });

  testWidgets('error + retry reloads selected period', (tester) async {
    when(
      () => useCase(any()),
    ).thenAnswer((_) async => const FailureResult(ServerFailure('nope')));
    final cubit = _makeCubit(useCase, engagement, demand);
    await cubit.load(period: SellerAnalyticsPeriod.days7);
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(l10n.statisticsLoadFailed), findsOneWidget);

    await tester.tap(find.text(l10n.commonRetry));
    await tester.pump();

    verify(() => useCase(SellerAnalyticsPeriod.days7)).called(2);
    await cubit.close();
  });

  testWidgets('seller with no listings shows empty state', (tester) async {
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(
        _snapshot(activeCount: 0, soldCount: 0, listings: const []),
      ),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text(l10n.statisticsEmptyTitle), findsOneWidget);
    expect(find.text(l10n.statisticsEmptyCta), findsOneWidget);
    expect(find.byType(StatisticsSummaryMetrics), findsNothing);
    expect(find.byType(DealerStatisticsContent), findsNothing);
    await cubit.close();
  });

  testWidgets('dealer with no listings reuses empty state', (tester) async {
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(
        _snapshot(
          sellerType: SellerType.dealer,
          activeCount: 0,
          soldCount: 0,
          listings: const [],
        ),
      ),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.byType(DealerStatisticsContent), findsNothing);
    await cubit.close();
  });

  testWidgets('listings + zero engagement still show the dashboard', (
    tester,
  ) async {
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(
        _snapshot(
          views: 0,
          favorites: 0,
          inquiries: 0,
          conversion: null,
          soldCount: 0,
        ),
      ),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyStateView), findsNothing);
    expect(find.byType(StatisticsSummaryMetrics), findsOneWidget);
    expect(find.byType(StatisticsViewsSparkline), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text(l10n.statisticsValueUnavailable), findsOneWidget);
    await cubit.close();
  });

  testWidgets('metrics, conversion, inventory and listing rows render', (
    tester,
  ) async {
    final cubit = _cubit(useCase, engagement, demand);
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.statisticsMetricViews), findsOneWidget);
    expect(find.text(l10n.statisticsMetricFavorites), findsOneWidget);
    expect(find.text(l10n.statisticsMetricInquiries), findsOneWidget);
    expect(find.text(l10n.statisticsMetricConversion), findsOneWidget);
    expect(find.text('12'), findsWidgets);
    expect(find.text('8.3%'), findsOneWidget);
    expect(find.textContaining(l10n.statisticsActiveListings), findsOneWidget);
    expect(find.textContaining(l10n.statisticsSoldListings), findsOneWidget);
    expect(find.text('BMW 320d, 2018'), findsOneWidget);
    expect(find.text('Mazda 6, 2016'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('statistics_listing_listing-active')),
      findsOneWidget,
    );
    expect(find.text(l10n.statusActive), findsOneWidget);
    expect(find.text(l10n.statusSold), findsOneWidget);
    await cubit.close();
  });

  testWidgets('NULL conversion shows em dash, not 0%', (tester) async {
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(views: 0, conversion: null)),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.statisticsValueUnavailable), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    await cubit.close();
  });

  testWidgets('period selector is present and tappable', (tester) async {
    when(() => useCase(any())).thenAnswer((invocation) async {
      final period =
          invocation.positionalArguments.first as SellerAnalyticsPeriod;
      return Success(_snapshot(views: period.days));
    });
    final cubit = _makeCubit(useCase, engagement, demand)..load();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.statisticsPeriod7), findsOneWidget);
    expect(find.text(l10n.statisticsPeriod30), findsOneWidget);
    expect(find.text(l10n.statisticsPeriod90), findsOneWidget);

    await tester.tap(find.byKey(StatisticsPeriodSelector.days7Key));
    await tester.pumpAndSettle();
    verify(() => useCase(SellerAnalyticsPeriod.days7)).called(1);

    await tester.tap(find.byKey(StatisticsPeriodSelector.days90Key));
    await tester.pumpAndSettle();
    verify(() => useCase(SellerAnalyticsPeriod.days90)).called(1);
    await cubit.close();
  });

  testWidgets('private seller keeps compact layout', (tester) async {
    final cubit = _cubit(useCase, engagement, demand);
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(PrivateStatisticsContent), findsOneWidget);
    expect(find.byType(DealerStatisticsContent), findsNothing);
    expect(find.byType(StatisticsInterestFunnelCard), findsNothing);
    expect(find.byType(StatisticsContactActionsCard), findsNothing);
    expect(find.byKey(StatisticsDemandCard.rootKey), findsNothing);
    expect(find.text(l10n.statisticsDemandTitle), findsNothing);
    verifyNever(() => demand());
    await cubit.close();
  });

  testWidgets('dealer seller renders professional layout', (tester) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();

    expect(find.byType(DealerStatisticsContent), findsOneWidget);
    expect(find.byType(PrivateStatisticsContent), findsNothing);
    expect(find.text(l10n.statisticsProfessionalLabel), findsOneWidget);
    expect(find.text(l10n.statisticsInterestFunnel), findsOneWidget);
    expect(find.byType(StatisticsInterestFunnelCard), findsOneWidget);
    expect(find.byType(StatisticsContactActionsCard), findsOneWidget);
    expect(find.text(l10n.statisticsFunnelImpressions), findsOneWidget);
    expect(find.text(l10n.statisticsContactActions), findsWidgets);
    expect(find.text(l10n.statisticsMetricPhone), findsOneWidget);
    expect(find.text(l10n.statisticsMetricWhatsapp), findsOneWidget);
    expect(find.text(l10n.statisticsMetricTelegram), findsOneWidget);
    expect(find.text(l10n.statisticsMetricShares), findsOneWidget);
    expect(find.text(l10n.statisticsTopListings), findsOneWidget);
    expect(find.text(l10n.statisticsInventoryPerformance), findsOneWidget);
    expect(find.text(l10n.statisticsInventoryTotal), findsOneWidget);
    expect(find.byType(EmptyStateView), findsNothing);
    verify(() => useCase(any())).called(1);
    await cubit.close();
  });

  testWidgets('dealer zero engagement does not fabricate top listings', (
    tester,
  ) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(
        _snapshot(
          sellerType: SellerType.dealer,
          views: 0,
          favorites: 0,
          inquiries: 0,
          conversion: null,
        ),
      ),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(DealerStatisticsContent), findsOneWidget);
    expect(find.text(l10n.statisticsTopListingsEmpty), findsOneWidget);
    expect(find.text(l10n.statisticsValueUnavailable), findsOneWidget);
    await cubit.close();
  });

  testWidgets('dealer inventory filter is local', (tester) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('statistics_filter_sold')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('statistics_filter_sold')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(DealerStatisticsContent.inventoryKey),
        matching: find.text('Mazda 6, 2016'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(DealerStatisticsContent.inventoryKey),
        matching: find.text('BMW 320d, 2018'),
      ),
      findsNothing,
    );
    verify(() => useCase(any())).called(1);
    await cubit.close();
  });

  testWidgets('later load with new seller type switches composition', (
    tester,
  ) async {
    when(() => useCase(any())).thenAnswer((_) async => Success(_snapshot()));
    final cubit = _makeCubit(useCase, engagement, demand)..load();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(PrivateStatisticsContent), findsOneWidget);

    when(() => useCase(any())).thenAnswer(
      (_) async => Success(_snapshot(sellerType: SellerType.dealer)),
    );
    await cubit.load();
    await tester.pumpAndSettle();
    expect(find.byType(DealerStatisticsContent), findsOneWidget);
    expect(find.byType(PrivateStatisticsContent), findsNothing);
    await cubit.close();
  });

  testWidgets('dealer period selector still loads 7/30/90', (tester) async {
    when(() => useCase(any())).thenAnswer((invocation) async {
      final period =
          invocation.positionalArguments.first as SellerAnalyticsPeriod;
      return Success(
        _snapshot(sellerType: SellerType.dealer, views: period.days),
      );
    });
    final cubit = _makeCubit(useCase, engagement, demand)..load();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(DealerStatisticsContent), findsOneWidget);
    await tester.tap(find.byKey(StatisticsPeriodSelector.days7Key));
    await tester.pumpAndSettle();
    verify(() => useCase(SellerAnalyticsPeriod.days7)).called(1);
    await tester.tap(find.byKey(StatisticsPeriodSelector.days90Key));
    await tester.pumpAndSettle();
    verify(() => useCase(SellerAnalyticsPeriod.days90)).called(1);
    await cubit.close();
  });

  testWidgets('dealer dark theme paints without exception', (tester) async {
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
    );
    await tester.pumpWidget(_wrapChrome(cubit, themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DealerStatisticsContent), findsOneWidget);
    await cubit.close();
  });

  testWidgets('dark theme paints dashboard without exception', (tester) async {
    final cubit = _cubit(useCase, engagement, demand);
    await tester.pumpWidget(_wrapChrome(cubit, themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(StatisticsViewsSparkline), findsOneWidget);
    await cubit.close();
  });

  testWidgets(
    'dealer funnel renders views > impressions and zero impressions',
    (tester) async {
      _useTallSurface(tester);
      final cubit = _cubit(
        useCase,
        engagement,
        demand,
        result: Success(
          _snapshot(sellerType: SellerType.dealer, views: 12, inquiries: 1),
        ),
        engagementResult: Success(_engagement(impressions: 3)),
      );
      await tester.pumpWidget(_wrapChrome(cubit));
      await tester.pumpAndSettle();
      expect(find.byKey(StatisticsInterestFunnelCard.rootKey), findsOneWidget);
      expect(
        find.byKey(StatisticsInterestFunnelCard.impressionsKey),
        findsOneWidget,
      );
      expect(find.byKey(StatisticsInterestFunnelCard.viewsKey), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cubit.close();

      final zero = _cubit(
        useCase,
        engagement,
        demand,
        result: Success(
          _snapshot(
            sellerType: SellerType.dealer,
            views: 5,
            inquiries: 0,
            conversion: null,
          ),
        ),
        engagementResult: Success(
          _engagement(impressions: 0, phone: 0, whatsapp: 0, shares: 0),
        ),
      );
      await tester.pumpWidget(_wrapChrome(zero));
      await tester.pumpAndSettle();
      expect(find.byKey(StatisticsInterestFunnelCard.rootKey), findsOneWidget);
      expect(tester.takeException(), isNull);
      await zero.close();
    },
  );

  testWidgets('dealer zero-engagement professional state still shows funnel', (
    tester,
  ) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(
        _snapshot(
          sellerType: SellerType.dealer,
          views: 0,
          favorites: 0,
          inquiries: 0,
          conversion: null,
        ),
      ),
      engagementResult: Success(
        _engagement(
          impressions: 0,
          phone: 0,
          whatsapp: 0,
          telegram: 0,
          shares: 0,
        ),
      ),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(DealerStatisticsContent), findsOneWidget);
    expect(find.byType(StatisticsInterestFunnelCard), findsOneWidget);
    expect(find.byType(StatisticsContactActionsCard), findsOneWidget);
    expect(find.text(l10n.statisticsTopListingsEmpty), findsOneWidget);
    await cubit.close();
  });

  testWidgets('RO professional funnel copy is present', (tester) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ro'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: statisticsTestHarness(
          cubit: cubit,
          child: const StatisticsChrome(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ro = roStrings();
    expect(find.text(ro.statisticsInterestFunnel), findsOneWidget);
    expect(find.text(ro.statisticsContactActions), findsWidgets);
    expect(find.text(ro.statisticsDemandTitle), findsOneWidget);
    await cubit.close();
  });

  testWidgets('dealer visible demand shows the exact count', (tester) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
      demandResult: Success(_demand(matchingUsers: 18)),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byKey(StatisticsDemandCard.rootKey), findsOneWidget);
    expect(find.text(l10n.statisticsDemandTitle), findsOneWidget);
    expect(find.text(l10n.statisticsDemandExplanation), findsOneWidget);
    final value = tester.widget<Text>(
      find.byKey(StatisticsDemandCard.valueKey),
    );
    expect(value.data, '18');
    expect(find.text(l10n.statisticsDemandMatchingUsers), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('statistics_listing_demand_listing-active'),
      ),
      findsWidgets,
    );
    expect(
      find.byKey(
        const ValueKey<String>('statistics_listing_demand_listing-sold'),
      ),
      findsNothing,
    );
    await cubit.close();
  });

  testWidgets('dealer zero demand shows exact zero, not failure', (
    tester,
  ) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer, soldCount: 0)),
      demandResult: Success(_demand(matchingUsers: 0)),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    final value = tester.widget<Text>(
      find.byKey(StatisticsDemandCard.valueKey),
    );
    expect(value.data, '0');
    expect(find.text(l10n.statisticsDemandZeroBody), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    await cubit.close();
  });

  testWidgets('dealer suppressed demand never leaks a low count', (
    tester,
  ) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
      demandResult: Success(_demand(matchingUsers: null, suppressed: true)),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    final value = tester.widget<Text>(
      find.byKey(StatisticsDemandCard.valueKey),
    );
    expect(value.data, l10n.statisticsDemandInsufficient);
    expect(value.data, isNot(contains('1')));
    expect(value.data, isNot(contains('2')));
    expect(value.data, isNot(contains('3')));
    expect(value.data, isNot(contains('4')));
    expect(value.data, isNot(contains('<5')));
    expect(find.text(l10n.statisticsDemandPrivacyBody), findsOneWidget);
    final listingDemand = tester.widget<Text>(
      find
          .byKey(
            const ValueKey<String>('statistics_listing_demand_listing-active'),
          )
          .first,
    );
    expect(listingDemand.data, l10n.statisticsListingDemandSuppressed);
    expect(listingDemand.data, isNot(contains('1')));
    expect(listingDemand.data, isNot(contains('<5')));
    await cubit.close();
  });

  testWidgets('dealer with only sold inventory hides buyer demand', (
    tester,
  ) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(
        _snapshot(
          sellerType: SellerType.dealer,
          activeCount: 0,
          soldCount: 1,
          listings: [
            _listing(
              id: 'listing-sold',
              title: 'Mazda 6',
              status: ListingStatus.sold,
              soldAt: DateTime(2026, 7, 20),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(DealerStatisticsContent), findsOneWidget);
    expect(find.byKey(StatisticsDemandCard.rootKey), findsNothing);
    expect(find.text(l10n.statisticsDemandTitle), findsNothing);
    verifyNever(() => demand());
    await cubit.close();
  });

  testWidgets('demand RPC failure keeps the professional dashboard', (
    tester,
  ) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
      demandResult: const FailureResult(ServerFailure('demand rpc')),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.byType(StatisticsSummaryMetrics), findsOneWidget);
    expect(find.byType(StatisticsInterestFunnelCard), findsOneWidget);
    expect(find.byType(StatisticsContactActionsCard), findsOneWidget);
    expect(find.byType(StatisticsViewsSparkline), findsOneWidget);
    expect(find.byKey(DealerStatisticsContent.inventoryKey), findsOneWidget);
    expect(find.text(l10n.statisticsDemandUnavailable), findsOneWidget);
    expect(find.byKey(StatisticsDemandCard.valueKey), findsNothing);
    await cubit.close();
  });

  testWidgets('top demand ranks visible listings only, max 3', (tester) async {
    _useTallSurface(tester);
    final listings = [
      _listing(id: 'd', title: 'Delta', inquiries: 9, views: 3),
      _listing(id: 'a', title: 'Alpha', inquiries: 1),
      _listing(id: 'b', title: 'Bravo', inquiries: 1),
      _listing(id: 'c', title: 'Charlie', inquiries: 1),
      _listing(id: 'e', title: 'Echo', inquiries: 1),
      _listing(id: 'zero', title: 'Zero', inquiries: 0),
      _listing(id: 'hidden', title: 'Hidden', inquiries: 0),
      _listing(
        id: 'sold',
        title: 'Sold',
        status: ListingStatus.sold,
        soldAt: DateTime(2026, 7, 20),
        inquiries: 4,
      ),
    ];
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(
        _snapshot(
          sellerType: SellerType.dealer,
          activeCount: 7,
          soldCount: 1,
          listings: listings,
        ),
      ),
      demandResult: Success(
        _demand(
          matchingUsers: 40,
          listings: const [
            SellerListingDemand(
              listingId: 'a',
              matchingUsers: 20,
              isSuppressed: false,
            ),
            SellerListingDemand(
              listingId: 'b',
              matchingUsers: 20,
              isSuppressed: false,
            ),
            SellerListingDemand(
              listingId: 'c',
              matchingUsers: 12,
              isSuppressed: false,
            ),
            SellerListingDemand(
              listingId: 'e',
              matchingUsers: 9,
              isSuppressed: false,
            ),
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
              listingId: 'sold',
              matchingUsers: 99,
              isSuppressed: false,
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();

    expect(find.byKey(StatisticsTopDemandCard.rootKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(StatisticsTopDemandCard.rootKey),
        matching: find.text('BMW Alpha, 2018'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(StatisticsTopDemandCard.rootKey),
        matching: find.text('BMW Bravo, 2018'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(StatisticsTopDemandCard.rootKey),
        matching: find.text('BMW Charlie, 2018'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(StatisticsTopDemandCard.rootKey),
        matching: find.text('BMW Echo, 2018'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(StatisticsTopDemandCard.rootKey),
        matching: find.text('BMW Hidden, 2018'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(StatisticsTopDemandCard.rootKey),
        matching: find.text('BMW Zero, 2018'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(StatisticsTopDemandCard.rootKey),
        matching: find.text('BMW Sold, 2018'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(DealerStatisticsContent.topListingsKey),
        matching: find.text('BMW Delta, 2018'),
      ),
      findsOneWidget,
    );
    await cubit.close();
  });

  testWidgets('top demand is omitted when only zero or suppressed', (
    tester,
  ) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
      demandResult: Success(_demand(matchingUsers: null, suppressed: true)),
    );
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byKey(StatisticsDemandCard.rootKey), findsOneWidget);
    expect(find.byKey(StatisticsTopDemandCard.rootKey), findsNothing);
    await cubit.close();
  });

  testWidgets('dealer period switch keeps demand and reloads analytics', (
    tester,
  ) async {
    _useTallSurface(tester);
    when(() => useCase(any())).thenAnswer((invocation) async {
      final period =
          invocation.positionalArguments.first as SellerAnalyticsPeriod;
      return Success(
        _snapshot(sellerType: SellerType.dealer, views: period.days),
      );
    });
    when(
      () => demand(),
    ).thenAnswer((_) async => Success(_demand(matchingUsers: 18)));
    final cubit = _makeCubit(useCase, engagement, demand)..load();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(StatisticsDemandCard.valueKey)).data,
      '18',
    );
    await tester.tap(find.byKey(StatisticsPeriodSelector.days7Key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(StatisticsPeriodSelector.days90Key));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(StatisticsDemandCard.valueKey)).data,
      '18',
    );
    verify(() => demand()).called(1);
    verify(() => useCase(SellerAnalyticsPeriod.days7)).called(1);
    verify(() => useCase(SellerAnalyticsPeriod.days90)).called(1);
    await cubit.close();
  });

  testWidgets('dealer demand dark theme paints without exception', (
    tester,
  ) async {
    _useTallSurface(tester);
    final cubit = _cubit(
      useCase,
      engagement,
      demand,
      result: Success(_snapshot(sellerType: SellerType.dealer)),
      demandResult: Success(_demand(matchingUsers: 5)),
    );
    await tester.pumpWidget(_wrapChrome(cubit, themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(StatisticsDemandCard.rootKey), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(StatisticsDemandCard.valueKey)).data,
      '5',
    );
    await cubit.close();
  });
}
