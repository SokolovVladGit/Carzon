import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/catalog/listing_brands.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/pages/listings_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/brands/brand_icon_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';

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
  title: 'VW Golf',
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

Widget _host({required ListingsBloc bloc}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => const ListingsPage())],
  );
  return MaterialApp.router(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ListingsRequested());
    registerFallbackValue(const ListingDiscoveryCriteria());
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
        regionFilter: MarketRegionFilter.transnistria,
        bodyType: null,
        fuelType: null,
        transmissionType: null,
        drivetrain: null,
        priceCurrencyFilter: ListingPriceCurrencyFilter.any,
      ),
    );
  });

  group('kListingBrandFeedQuickFilterCatalog', () {
    test('equals full catalog minus Other', () {
      final expected = kListingBrandCatalog
          .where((b) => b != kListingBrandCatalogOther)
          .toList(growable: false);
      expect(kListingBrandFeedQuickFilterCatalog, expected);
      expect(kListingBrandFeedQuickFilterCatalog, isNot(contains('Other')));
      expect(
        kListingBrandFeedQuickFilterCatalog.length,
        kListingBrandCatalog.length - 1,
      );
    });

    test('preserves canonical catalog spellings', () {
      expect(kListingBrandFeedQuickFilterCatalog, contains('Mercedes-Benz'));
      expect(kListingBrandFeedQuickFilterCatalog, contains('Land Rover'));
    });
  });

  group('feed brand icon / monogram policy', () {
    test('each quick-filter brand has packaged SVG or monogram fallback', () {
      for (final brand in kListingBrandFeedQuickFilterCatalog) {
        final usesMonogram = listingBrandFeedQuickFilterShouldUseMonogram(
          brand,
        );
        final hasPackagedSvg = !isBrandIconDefaultAssetPath(
          getBrandIconPath(brand),
        );
        final forcedMonogram = kListingBrandFeedQuickFilterMonogramFallback
            .contains(brand);

        if (forcedMonogram) {
          expect(usesMonogram, isTrue, reason: '$brand forced monogram');
        } else if (hasPackagedSvg) {
          expect(usesMonogram, isFalse, reason: '$brand has packaged SVG');
        } else {
          expect(usesMonogram, isTrue, reason: '$brand missing SVG monogram');
        }
      }
    });

    test('forced monogram fallback set is empty when all SVGs are enabled', () {
      expect(kListingBrandFeedQuickFilterMonogramFallback, isEmpty);
    });

    test('monogram label helper derives initials from catalog names', () {
      expect(listingBrandFeedQuickFilterMonogram('Ram'), 'RA');
      expect(listingBrandFeedQuickFilterMonogram('GMC'), 'GM');
      expect(listingBrandFeedQuickFilterMonogram('DS Automobiles'), 'DA');
      expect(listingBrandFeedQuickFilterMonogram('Land Rover'), 'LR');
    });

    test('packaged brands use SVG on feed; missing assets use monogram', () {
      expect(listingBrandFeedQuickFilterShouldUseMonogram('BYD'), isFalse);
      expect(listingBrandFeedQuickFilterShouldUseMonogram('Cupra'), isFalse);
      expect(listingBrandFeedQuickFilterShouldUseMonogram('Citroen'), isFalse);
      expect(isBrandIconDefaultAssetPath(getBrandIconPath('BYD')), isFalse);
    });

    test('cleaned packaged brands use SVG not monogram on feed', () {
      for (final brand in [
        'Seres',
        'Voyah',
        'Foton',
        'GMC',
        'Ram',
        'Cadillac',
        'Porsche',
        'Wey',
        'KGM',
        'Li Auto',
        'Fiat',
        'Hyundai',
        'Nissan',
        'MG',
        'Omoda',
        'Daihatsu',
        'Chevrolet',
        'Hongqi',
        'Subaru',
        'Tank',
        'VinFast',
        'DS Automobiles',
        'Bestune',
        'FAW',
      ]) {
        expect(
          listingBrandFeedQuickFilterShouldUseMonogram(brand),
          isFalse,
          reason: brand,
        );
        expect(
          isBrandIconDefaultAssetPath(getBrandIconPath(brand)),
          isFalse,
          reason: brand,
        );
      }
    });

    test('no feed catalog brand uses monogram fallback', () {
      for (final brand in kListingBrandFeedQuickFilterCatalog) {
        expect(
          listingBrandFeedQuickFilterShouldUseMonogram(brand),
          isFalse,
          reason: brand,
        );
      }
    });

    test('newly added brands appear in feed quick-filter catalog', () {
      for (final brand in ['Subaru', 'Cupra', 'BYD', 'Zeekr', 'Li Auto']) {
        expect(kListingBrandFeedQuickFilterCatalog, contains(brand));
      }
    });
  });

  group('feed quick-filter logo optical scale', () {
    test('balanced brands use default scale 1.0', () {
      for (final brand in ['Toyota', 'BMW', 'Volkswagen', 'Ford', 'Honda']) {
        expect(listingBrandFeedQuickFilterLogoScale(brand), 1.0, reason: brand);
      }
    });

    test('undersized marks receive modest optical boost', () {
      const boosted = {
        'Datsun': 1.22,
        'Abarth': 1.15,
        'Cadillac': 1.40,
        'Lancia': 1.12,
        'Acura': 1.20,
        'DS Automobiles': 1.18,
        'Genesis': 1.22,
        'Polestar': 1.12,
        'Jaecoo': 1.30,
        'Omoda': 1.28,
        'UAZ': 1.24,
        'Moskvich': 1.26,
        'Land Rover': 1.46,
        'Mini': 1.40,
        'Fiat': 1.28,
        'Jaguar': 1.30,
        'Hummer': 1.32,
        'Isuzu': 1.30,
        'Ram': 1.30,
        'Haval': 1.30,
      };
      for (final entry in boosted.entries) {
        expect(
          listingBrandFeedQuickFilterLogoScale(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('override map keys match packaged slugs', () {
      for (final slug
          in kListingBrandFeedQuickFilterLogoOpticalScaleBySlug.keys) {
        expect(kPackagedBrandIconSlugs, contains(slug), reason: slug);
      }
    });
  });

  group('listingBrandFeedQuickFilter selection helpers', () {
    test('isSelected matches canonical brand across case/spacing', () {
      expect(
        listingBrandFeedQuickFilterIsSelected('volkswagen', 'Volkswagen'),
        isTrue,
      );
      expect(
        listingBrandFeedQuickFilterIsSelected('mercedes benz', 'Mercedes-Benz'),
        isTrue,
      );
      expect(
        listingBrandFeedQuickFilterIsSelected('MERCEDES-BENZ', 'Mercedes-Benz'),
        isTrue,
      );
      expect(
        listingBrandFeedQuickFilterIsSelected('Toyota', 'Volkswagen'),
        isFalse,
      );
    });

    test('allSelected only when make is empty or unknown to catalog', () {
      expect(listingBrandFeedQuickFilterAllSelected(null), isTrue);
      expect(listingBrandFeedQuickFilterAllSelected(''), isTrue);
      expect(listingBrandFeedQuickFilterAllSelected('   '), isTrue);
      expect(listingBrandFeedQuickFilterAllSelected('Toyota'), isFalse);
      expect(listingBrandFeedQuickFilterAllSelected('Custom Garage'), isFalse);
    });

    test('selectionUnchanged treats equivalent makes as redundant tap', () {
      expect(
        listingBrandFeedQuickFilterSelectionUnchanged(
          'mercedes benz',
          'Mercedes-Benz',
        ),
        isTrue,
      );
      expect(
        listingBrandFeedQuickFilterSelectionUnchanged(
          'volkswagen',
          'Volkswagen',
        ),
        isTrue,
      );
      expect(listingBrandFeedQuickFilterSelectionUnchanged(null, null), isTrue);
      expect(
        listingBrandFeedQuickFilterSelectionUnchanged('Toyota', 'Volkswagen'),
        isFalse,
      );
      expect(
        listingBrandFeedQuickFilterSelectionUnchanged('Toyota', null),
        isFalse,
      );
      expect(
        listingBrandFeedQuickFilterSelectionUnchanged('Custom Garage', null),
        isFalse,
      );
    });
  });

  group('Home brand row widget', () {
    late _MockListingsBloc bloc;
    late _MockAuthCubit auth;
    late _MockFavoritesCubit favs;
    late _MockSellersRepository sellersRepo;
    late _MockMessagingRepository messagingRepo;
    late MockSavedSearchesRepository browseSavedSearchesRepo;
    late MockNotificationsRepository browseNotificationsRepo;
    late MockPushNotificationRegistrationService browsePushRegistration;

    setUp(() async {
      await sl.reset();
      bloc = _MockListingsBloc();
      auth = _MockAuthCubit();
      favs = _MockFavoritesCubit();
      sellersRepo = _MockSellersRepository();
      messagingRepo = _MockMessagingRepository();

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

      when(() => bloc.state).thenReturn(
        const ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
        ),
      );
      whenListen(
        bloc,
        const Stream<ListingsState>.empty(),
        initialState: const ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
        ),
      );

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
      await sl.reset();
    });

    testWidgets('tapping Volkswagen dispatches canonical make filter', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<FavoritesCubit>.value(value: favs),
            BlocProvider(
              create: (_) =>
                  SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
            ),
            BlocProvider(
              create: (_) => MessagingUnreadSummaryCubit(messagingRepo),
            ),
          ],
          child: _host(bloc: bloc),
        ),
      );
      await tester.pump();

      final label = ruStrings().brandFilterBrandSemantics('Volkswagen');
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

    testWidgets(
      'pagination failure keeps current listing visible and exposes retry',
      (tester) async {
        final l10n = ruStrings();
        final compareCubit = newInMemoryCompareCubit();
        addTearDown(compareCubit.close);
        final state = ListingsState(
          status: ListingsStatus.paginationFailure,
          items: [_feedListing('l1')],
          hasReachedEnd: false,
        );
        when(() => bloc.state).thenReturn(state);
        whenListen(
          bloc,
          const Stream<ListingsState>.empty(),
          initialState: state,
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<FavoritesCubit>.value(value: favs),
              BlocProvider<CompareCubit>.value(value: compareCubit),
              BlocProvider(
                create: (_) =>
                    SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
              ),
              BlocProvider(
                create: (_) => MessagingUnreadSummaryCubit(messagingRepo),
              ),
            ],
            child: _host(bloc: bloc),
          ),
        );
        await tester.pump();

        expect(find.text('Volkswagen Golf'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text(l10n.commonRetry),
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pump();
        expect(find.text(l10n.listingsLoadMoreFailed), findsOneWidget);
        clearInteractions(bloc);
        await tester.tap(find.text(l10n.commonRetry));
        await tester.pump();

        verify(
          () => bloc.add(
            any(
              that: predicate<ListingsNextPageRequested>(
                (event) => event.isExplicitRetry,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('loading-more footer shows localized label', (tester) async {
      final l10n = ruStrings();
      final compareCubit = newInMemoryCompareCubit();
      addTearDown(compareCubit.close);
      final state = ListingsState(
        status: ListingsStatus.loadingMore,
        items: [_feedListing('l1')],
        hasReachedEnd: false,
      );
      when(() => bloc.state).thenReturn(state);
      whenListen(
        bloc,
        const Stream<ListingsState>.empty(),
        initialState: state,
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<FavoritesCubit>.value(value: favs),
            BlocProvider<CompareCubit>.value(value: compareCubit),
            BlocProvider(
              create: (_) =>
                  SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
            ),
            BlocProvider(
              create: (_) => MessagingUnreadSummaryCubit(messagingRepo),
            ),
          ],
          child: _host(bloc: bloc),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text(l10n.listingsLoadingMore),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(l10n.listingsLoadingMore), findsOneWidget);
    });
  });
}
