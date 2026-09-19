import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/core/widgets/floating_capsule_nav.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/utils/discovery_feed_chip_labels.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/pages/listings_page.dart';
import 'package:carzon/features/listings/presentation/widgets/category_chip.dart';
import 'package:carzon/features/listings/presentation/widgets/listings_active_discovery_summary_strip.dart';
import 'package:carzon/features/listings/presentation/widgets/listings_brand_filter_row.dart';
import 'package:carzon/features/listings/presentation/widgets/listings_catalog_header.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/browse_catalog_filter_alerts_sl.dart';
import '../../helpers/compare_cubit_test_helpers.dart';
import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/noop_last_applied_listing_discovery_repository.dart';

class _MockListingsBloc extends MockBloc<ListingsEvent, ListingsState>
    implements ListingsBloc {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockSellersRepository extends Mock implements SellersRepository {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

Listing _feedListing(String id) => Listing(
  id: id,
  title: 'VW Golf $id',
  make: 'Volkswagen',
  model: 'Golf',
  year: 2018,
  priceEur: 9000,
  mileageKm: 100000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
);

List<Listing> _feedItems() => [for (var i = 0; i < 6; i++) _feedListing('l$i')];

const _mastheadKey = ValueKey<String>('listingsCatalogMasthead');
const _brandRailKey = ValueKey<String>('listingsHomeBrandRail');
const _bodyRailKey = ValueKey<String>('listingsHomeBodyRail');
const _summaryStripKey = ValueKey<String>(
  'listingsActiveDiscoverySummaryStrip',
);

Widget _host({
  required ListingsBloc bloc,
  required AuthCubit auth,
  required FavoritesCubit favorites,
  required SellersRepository sellersRepo,
  required MessagingRepository messagingRepo,
  required CompareCubit compare,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => const ListingsPage())],
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: auth),
      BlocProvider<FavoritesCubit>.value(value: favorites),
      BlocProvider<CompareCubit>.value(value: compare),
      BlocProvider(
        create: (_) => SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
      ),
      BlocProvider(create: (_) => MessagingUnreadSummaryCubit(messagingRepo)),
    ],
    child: MaterialApp.router(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ListingsRequested());
    registerFallbackValue(const ListingDiscoveryCriteria());
    registerFallbackValue(
      const ListingsBodyTypeFilterChanged(ListingBodyType.suv),
    );
    registerFallbackValue(
      const ListingsDiscoveryFilterRemoved(ListingsDiscoveryChipKind.make),
    );
    registerFallbackValue(
      const ListingsFiltersApplied(
        make: 'Volkswagen',
        model: null,
        minYear: null,
        maxYear: null,
        minPrice: null,
        maxPrice: null,
        maxMileage: null,
        city: null,
        typeFilter: ListingTypeFilter.any,
        sort: ListingSortOption.newestFirst,
        regionFilter: MarketRegionFilter.both,
        bodyType: null,
        fuelType: null,
        transmissionType: null,
        drivetrain: null,
        priceCurrencyFilter: ListingPriceCurrencyFilter.any,
      ),
    );
    registerFallbackValue('');
  });

  late _MockListingsBloc bloc;
  late _MockAuthCubit auth;
  late _MockFavoritesCubit favs;
  late _MockSellersRepository sellersRepo;
  late _MockMessagingRepository messagingRepo;
  late CompareCubit compare;
  late MockSavedSearchesRepository browseSavedSearchesRepo;
  late MockNotificationsRepository browseNotificationsRepo;
  late MockPushNotificationRegistrationService browsePushRegistration;
  final l10n = ruStrings();

  ListingsState feedState({
    String? make,
    ListingBodyType? bodyType,
    List<Listing>? items,
  }) {
    return ListingsState(
      status: ListingsStatus.success,
      items: items ?? _feedItems(),
      hasReachedEnd: true,
      make: make,
      bodyTypeFilter: bodyType,
    );
  }

  void stubBloc(ListingsState state, {Stream<ListingsState>? stream}) {
    when(() => bloc.state).thenReturn(state);
    whenListen(
      bloc,
      stream ?? const Stream<ListingsState>.empty(),
      initialState: state,
    );
  }

  setUp(() async {
    await sl.reset();
    bloc = _MockListingsBloc();
    auth = _MockAuthCubit();
    favs = _MockFavoritesCubit();
    sellersRepo = _MockSellersRepository();
    messagingRepo = _MockMessagingRepository();
    compare = newInMemoryCompareCubit();

    when(
      () => sellersRepo.getSellerPublicProfile(any()),
    ).thenAnswer((_) async => const Success(null));
    when(() => sellersRepo.getMySellerProfile()).thenAnswer(
      (_) async => Success(
        MySellerProfileModel(
          displayName: 'S',
          avatarUrl: null,
          avatarPath: null,
          memberSince: DateTime.utc(2026, 4, 1),
          publicVisibility: true,
        ),
      ),
    );
    when(
      () => messagingRepo.getUnreadConversationCount(),
    ).thenAnswer((_) async => const Success(0));

    when(() => auth.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
    when(() => favs.state).thenReturn(const FavoritesState());
    whenListen(
      favs,
      const Stream<FavoritesState>.empty(),
      initialState: const FavoritesState(),
    );

    sl.registerLazySingleton<LastAppliedListingDiscoveryRepository>(
      () => const NoopLastAppliedListingDiscoveryRepository(),
    );
    browseSavedSearchesRepo = MockSavedSearchesRepository();
    browseNotificationsRepo = MockNotificationsRepository();
    browsePushRegistration = MockPushNotificationRegistrationService();
    primeListingBrowseFilterAlertsDeps(
      sl,
      savedSearchesRepo: browseSavedSearchesRepo,
      notificationsRepo: browseNotificationsRepo,
      pushRegistration: browsePushRegistration,
    );
    sl.registerFactory<ListingsBloc>(() => bloc);
  });

  tearDown(() async {
    await compare.close();
    await sl.reset();
  });

  Future<void> pumpHome(WidgetTester tester, ListingsState state) async {
    stubBloc(state);
    await tester.pumpWidget(
      _host(
        bloc: bloc,
        auth: auth,
        favorites: favs,
        sellersRepo: sellersRepo,
        messagingRepo: messagingRepo,
        compare: compare,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> scrollFeedAway(WidgetTester tester) async {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
  }

  Finder verticalScrollable() => find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axis == Axis.vertical,
  );

  group('Home discovery header scroll composition', () {
    testWidgets('uses one vertical CustomScrollView', (tester) async {
      await pumpHome(tester, feedState());

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(verticalScrollable(), findsOneWidget);
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('brand and body rails scroll away; masthead stays pinned', (
      tester,
    ) async {
      await pumpHome(tester, feedState());

      expect(find.byKey(_mastheadKey).hitTestable(), findsOneWidget);
      expect(find.byType(ListingsCatalogHeader).hitTestable(), findsOneWidget);
      expect(find.byKey(_brandRailKey).hitTestable(), findsOneWidget);
      expect(find.byKey(_bodyRailKey).hitTestable(), findsOneWidget);
      expect(find.byType(ListingsBrandFilterRow).hitTestable(), findsOneWidget);
      expect(find.byType(CategoryChipsRow).hitTestable(), findsOneWidget);

      await scrollFeedAway(tester);

      expect(find.byKey(_mastheadKey).hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('listingsHeaderCarzonLogo')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(_brandRailKey).hitTestable(), findsNothing);
      expect(find.byKey(_bodyRailKey).hitTestable(), findsNothing);
      expect(find.byType(ListingsBrandFilterRow).hitTestable(), findsNothing);
      expect(find.byType(CategoryChipsRow).hitTestable(), findsNothing);
    });

    testWidgets('no reserved sticky strip space when discovery is vanilla', (
      tester,
    ) async {
      await pumpHome(tester, feedState());

      expect(find.byType(ListingsActiveDiscoverySummaryStrip), findsNothing);
      expect(find.byKey(_summaryStripKey), findsNothing);

      final masthead = tester.getRect(find.byKey(_mastheadKey));
      final brand = tester.getRect(find.byKey(_brandRailKey));
      expect(brand.top, closeTo(masthead.bottom, 0.5));
    });

    testWidgets(
      'active discovery strip pins below masthead after rails scroll away',
      (tester) async {
        await pumpHome(tester, feedState(make: 'Toyota'));

        expect(
          find.byType(ListingsActiveDiscoverySummaryStrip),
          findsOneWidget,
        );
        expect(find.text(l10n.filterMake), findsOneWidget);
        expect(find.text('Toyota'), findsWidgets);

        await scrollFeedAway(tester);

        expect(find.byKey(_mastheadKey).hitTestable(), findsOneWidget);
        expect(find.byKey(_summaryStripKey).hitTestable(), findsOneWidget);
        expect(
          find.byType(ListingsActiveDiscoverySummaryStrip).hitTestable(),
          findsOneWidget,
        );
        expect(find.byKey(_brandRailKey).hitTestable(), findsNothing);
        expect(find.byKey(_bodyRailKey).hitTestable(), findsNothing);

        final masthead = tester.getRect(find.byKey(_mastheadKey));
        final strip = tester.getRect(find.byKey(_summaryStripKey));
        expect(strip.top, closeTo(masthead.bottom, 0.5));
      },
    );

    testWidgets('body-only filter pins the same discovery strip', (
      tester,
    ) async {
      await pumpHome(tester, feedState(bodyType: ListingBodyType.suv));

      expect(find.byType(ListingsActiveDiscoverySummaryStrip), findsOneWidget);

      await scrollFeedAway(tester);

      expect(find.byKey(_summaryStripKey).hitTestable(), findsOneWidget);
      expect(find.byKey(_brandRailKey).hitTestable(), findsNothing);
      final masthead = tester.getRect(find.byKey(_mastheadKey));
      final strip = tester.getRect(find.byKey(_summaryStripKey));
      expect(strip.top, closeTo(masthead.bottom, 0.5));
    });

    testWidgets('removing the final chip collapses the sticky strip', (
      tester,
    ) async {
      final withMake = feedState(make: 'Toyota');
      final vanilla = feedState();
      final states = StreamController<ListingsState>.broadcast();
      addTearDown(states.close);
      when(() => bloc.state).thenReturn(withMake);
      whenListen(bloc, states.stream, initialState: withMake);

      await tester.pumpWidget(
        _host(
          bloc: bloc,
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
          compare: compare,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await scrollFeedAway(tester);
      expect(find.byKey(_summaryStripKey).hitTestable(), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('discovery-chip-remove-make')),
      );
      await tester.pump();
      verify(
        () => bloc.add(
          const ListingsDiscoveryFilterRemoved(ListingsDiscoveryChipKind.make),
        ),
      ).called(1);

      when(() => bloc.state).thenReturn(vanilla);
      states.add(vanilla);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ListingsActiveDiscoverySummaryStrip), findsNothing);
      expect(find.byKey(_summaryStripKey), findsNothing);
      expect(find.byKey(_mastheadKey).hitTestable(), findsOneWidget);
    });

    testWidgets('removing one of several chips keeps the sticky strip', (
      tester,
    ) async {
      final both = feedState(make: 'Toyota', bodyType: ListingBodyType.suv);
      final bodyOnly = feedState(bodyType: ListingBodyType.suv);
      final states = StreamController<ListingsState>.broadcast();
      addTearDown(states.close);
      when(() => bloc.state).thenReturn(both);
      whenListen(bloc, states.stream, initialState: both);

      await tester.pumpWidget(
        _host(
          bloc: bloc,
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
          compare: compare,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      await scrollFeedAway(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('discovery-chip-remove-make')),
      );
      await tester.pump();

      when(() => bloc.state).thenReturn(bodyOnly);
      states.add(bodyOnly);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(_summaryStripKey).hitTestable(), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('discovery-chip-remove-bodyType')),
        findsOneWidget,
      );
    });

    testWidgets('brand rail still dispatches ListingsFiltersApplied', (
      tester,
    ) async {
      await pumpHome(tester, feedState());

      final label = l10n.brandFilterBrandSemantics('Volkswagen');
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pump();

      verify(
        () => bloc.add(
          any(
            that: predicate<ListingsEvent>(
              (e) => e is ListingsFiltersApplied && e.make == 'Volkswagen',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('body rail still dispatches ListingsBodyTypeFilterChanged', (
      tester,
    ) async {
      await pumpHome(tester, feedState());

      await tester.scrollUntilVisible(
        find.bySemanticsLabel(l10n.listingBodyTypeSuv),
        80,
        scrollable: find.descendant(
          of: find.byKey(_bodyRailKey),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.bySemanticsLabel(l10n.listingBodyTypeSuv));
      await tester.pumpAndSettle();

      verify(
        () =>
            bloc.add(const ListingsBodyTypeFilterChanged(ListingBodyType.suv)),
      ).called(1);
    });

    testWidgets('feed keeps floating-nav bottom clearance', (tester) async {
      await pumpHome(tester, feedState());

      final padding = tester.widget<SliverPadding>(
        find.byKey(const ValueKey<String>('listingsFeedSliverPadding')),
      );
      expect(
        (padding.padding as EdgeInsets).bottom,
        kFloatingCapsuleNavClearance,
      );
      expect(find.byType(FloatingCapsuleNav), findsOneWidget);
    });
  });
}
