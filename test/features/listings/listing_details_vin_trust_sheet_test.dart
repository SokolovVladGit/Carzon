import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/listing_details_self_fetch_stubs.dart';
import '../../helpers/seller_public_profile_test_mocks.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockListingsRepository extends Mock implements ListingsRepository {}

class _MemoryCompareRepository implements CompareRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<CompareItem>> loadItems() async => const [];

  @override
  Future<void> saveItems(List<CompareItem> value) async {}
}

Listing _listing({ListingVinStatus vinStatus = ListingVinStatus.notProvided}) =>
    Listing(
      id: 'l1',
      title: 'Test',
      make: 'Audi',
      model: 'A4',
      year: 2020,
      priceEur: 1000,
      mileageKm: 50000,
      type: ListingType.sale,
      city: 'Chișinău',
      marketRegion: MarketRegion.moldova,
      createdAt: DateTime.utc(2026, 4, 1),
      status: ListingStatus.active,
      sellerId: 's1',
      vinStatus: vinStatus,
    );

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late _MockListingsRepository listingsRepo;
  late CompareCubit compareCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;
  final ru = ruStrings();

  setUpAll(() => registerFallbackValue(''));

  setUp(() async {
    await sl.reset();
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    listingsRepo = _MockListingsRepository();
    compareCubit = CompareCubit(repository: _MemoryCompareRepository());
    sellerProfileUseCase = MockGetSellerPublicProfile();
    stubSellerPublicProfileHidden(sellerProfileUseCase);

    when(() => detailsCubit.load(any())).thenAnswer((_) async {});

    when(() => listingsRepo.fetchBuyerVinReportSources(any())).thenAnswer(
      (_) async => const Success(BuyerListingVinReportLookupResult()),
    );

    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    when(() => favoritesCubit.state).thenReturn(const FavoritesState());
    whenListen(
      favoritesCubit,
      const Stream<FavoritesState>.empty(),
      initialState: const FavoritesState(),
    );

    sl.registerLazySingleton<ListingsRepository>(() => listingsRepo);
    registerListingDetailsSelfFetchStubs(sl);
    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
    sl.registerFactory<GetSellerPublicProfile>(() => sellerProfileUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget app(Listing listing) {
    final initial = ListingDetailsState.success(listing);

    when(() => detailsCubit.state).thenReturn(initial);
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: initial,
    );

    final router = GoRouter(
      initialLocation: '/listings/l1',
      routes: [
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) =>
              ListingDetailsPage(id: state.pathParameters['id']!),
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
        BlocProvider<CompareCubit>.value(value: compareCubit),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('format_valid with decode shows green badge and open hint', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => Success(
        BuyerListingVinReportLookupResult(
          results: [
            BuyerListingVinReportSourceResult(
              sourceId: 'nhtsa_vpic',
              normalizedSummary: {'make': 'Audi'},
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      app(_listing(vinStatus: ListingVinStatus.formatValid)),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.listingVinBadgeIndicated), findsOneWidget);
    expect(find.text(ru.listingVinReportOpenHint), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vin_present_latin_badge_v')),
      findsOneWidget,
    );
    expect(find.text('В'), findsNothing);
    expect(
      find.byKey(const ValueKey('listing_vin_trust_badge_tap')),
      findsOneWidget,
    );
  });

  testWidgets(
    'tap opens buyer VIN report shell (empty public sources, no full VIN)',
    (tester) async {
      await tester.pumpWidget(
        app(_listing(vinStatus: ListingVinStatus.formatValid)),
      );
      await tester.pumpAndSettle();

      final tapTarget = find.byKey(
        const ValueKey('listing_vin_trust_badge_tap'),
      );
      await tester.ensureVisible(tapTarget);
      await tester.pumpAndSettle();

      await tester.tap(tapTarget);
      await tester.pumpAndSettle();

      expect(find.text(ru.listingBuyerVinReportTitle), findsOneWidget);
      expect(
        find.text(ru.listingBuyerVinReportVinAddedBySeller),
        findsOneWidget,
      );
      expect(find.text(ru.listingVinReportNoDataTitle), findsWidgets);
      expect(find.text(ru.listingVinReportNoDataBody), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vin_present_latin_badge_v')),
        findsNothing,
      );
      expect(
        find.textContaining('Полный VIN не показывается публично'),
        findsWidgets,
      );
      for (final phrase in [
        'VIN проверен',
        'официально подтверждён',
        'история проверена',
        'проверено по базе',
        'без ДТП',
        'чистая история',
      ]) {
        expect(find.textContaining(phrase), findsNothing);
      }

      expect(
        find.byKey(const ValueKey('buyer_vin_report_sheet_close')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('buyer_vin_report_sheet_close')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buyer_vin_report_sheet_close')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'buyer report primary close control stays tappable on small screen with long NHTSA body',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final longEngine = List.filled(24, 'VeryLongToken ').join();
      when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
        (_) async => Success(
          BuyerListingVinReportLookupResult(
            results: [
              BuyerListingVinReportSourceResult(
                sourceId: 'nhtsa_vpic',
                visibilityRaw: 'public_summary',
                normalizedSummary: {
                  'make': 'HONDA',
                  'model': 'CIVIC',
                  'year': 2019,
                  'body_type': 'Sedan',
                  'fuel_type': 'Gasoline',
                  'engine': longEngine,
                  'transmission':
                      'Automatic transmission with long descriptive label',
                },
                fetchedAt: DateTime(2026, 5, 16),
                limitationCodes: const ['basic_decode_only'],
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        app(_listing(vinStatus: ListingVinStatus.formatValid)),
      );
      await tester.pumpAndSettle();
      final tapTarget = find.byKey(
        const ValueKey('listing_vin_trust_badge_tap'),
      );
      await tester.ensureVisible(tapTarget);
      await tester.pumpAndSettle();
      await tester.tap(tapTarget);
      await tester.pumpAndSettle();

      final closeBtn = find.byKey(
        const ValueKey('buyer_vin_report_sheet_close'),
      );
      expect(closeBtn, findsOneWidget);
      expect(find.textContaining('16.05.2026'), findsOneWidget);
      expect(find.text('2026-05-16'), findsNothing);
      for (final raw in [
        'basic_decode_only',
        'not_md_pmr_official_verification',
      ]) {
        expect(find.textContaining(raw), findsNothing);
      }
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();
      expect(closeBtn, findsNothing);
    },
  );

  testWidgets(
    'buyer report has one close button and scroll reveals limitations above footer',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
        (_) async => Success(
          BuyerListingVinReportLookupResult(
            results: [
              BuyerListingVinReportSourceResult(
                sourceId: 'nhtsa_vpic',
                visibilityRaw: 'public_summary',
                normalizedSummary: {
                  'make': 'Toyota',
                  'model': 'Camry',
                  'year': 2020,
                  'manufacturer': 'TOYOTA MOTOR CORPORATION',
                  'body_type': '4-Door Sedan',
                  'vehicle_type': 'PASSENGER CAR',
                  'series': 'Camry SE',
                  'fuel_type': 'Gasoline',
                  'engine': '2.5L 4 cyl',
                  'drive_type': 'FWD',
                  'cylinders': 4,
                  'plant_country': 'Japan',
                },
                limitationCodes: const [
                  'basic_decode_only',
                  'not_md_pmr_official_verification',
                  'not_accident_history',
                  'not_ownership_check',
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        app(_listing(vinStatus: ListingVinStatus.formatValid)),
      );
      await tester.pumpAndSettle();
      final tapTarget = find.byKey(
        const ValueKey('listing_vin_trust_badge_tap'),
      );
      await tester.ensureVisible(tapTarget);
      await tester.pumpAndSettle();
      await tester.tap(tapTarget);
      await tester.pumpAndSettle();

      expect(find.text(ru.listingBuyerVinReportClose), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buyer_vin_report_sheet_close')),
        findsOneWidget,
      );
      expect(
        find.text(ru.listingBuyerVinReportNhtsaCatalogSourceLine),
        findsOneWidget,
      );
      expect(
        find.text(ru.listingBuyerVinReportManualSourcesSectionTitle),
        findsNothing,
      );
      expect(
        find.text(ru.listingBuyerVinReportNotVerifiedSectionTitle),
        findsOneWidget,
      );

      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('buyer_vin_report_sheet_scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text(ru.listingBuyerVinReportNotVerifiedSectionTitle),
        120,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(ru.listingBuyerVinReportNotVerifiedSectionTitle),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ru.listingBuyerVinReportLimitationRegistrationMdPmr),
        findsOneWidget,
      );
      expect(
        find.text(ru.listingBuyerVinReportLimitationOwner),
        findsOneWidget,
      );
      expect(
        find.text(ru.listingBuyerVinReportLimitationAccidentHistory),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buyer_vin_manual_card_md_rca_damage')),
        findsNothing,
      );
      for (final phrase in [
        'VIN проверен',
        'Без ДТП',
        'Чистая история',
        'Официально проверено',
        'Ограничений нет',
      ]) {
        expect(find.textContaining(phrase), findsNothing);
      }
    },
  );

  testWidgets(
    'buyer report empty public data omits manual source cards and NHTSA footer',
    (tester) async {
      when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
        (_) async => const Success(BuyerListingVinReportLookupResult()),
      );
      await tester.pumpWidget(
        app(_listing(vinStatus: ListingVinStatus.formatValid)),
      );
      await tester.pumpAndSettle();
      final tapTarget = find.byKey(
        const ValueKey('listing_vin_trust_badge_tap'),
      );
      await tester.ensureVisible(tapTarget);
      await tester.pumpAndSettle();
      await tester.tap(tapTarget);
      await tester.pumpAndSettle();
      expect(
        find.text(ru.listingBuyerVinReportManualSourcesSectionTitle),
        findsNothing,
      );
      expect(
        find.text(ru.listingBuyerVinReportNotVerifiedSectionTitle),
        findsNothing,
      );
      expect(
        find.text(ru.listingBuyerVinReportNhtsaCatalogSourceLine),
        findsNothing,
      );
      expect(find.text(ru.listingVinReportNoDataTitle), findsWidgets);
    },
  );

  testWidgets('buyer report shows unavailable state when RPC fetchFailed', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async =>
          const Success(BuyerListingVinReportLookupResult(fetchFailed: true)),
    );
    await tester.pumpWidget(
      app(_listing(vinStatus: ListingVinStatus.formatValid)),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.listingVinReportUnavailableCta), findsOneWidget);
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingVinReportUnavailableTitle), findsOneWidget);
    expect(find.text(ru.listingVinReportUnavailableBody), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportLoadError), findsNothing);
  });

  testWidgets('buyer report never shows worker cylinders placeholder', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => Success(
        BuyerListingVinReportLookupResult(
          results: [
            BuyerListingVinReportSourceResult(
              sourceId: 'nhtsa_vpic',
              visibilityRaw: 'public_summary',
              normalizedSummary: {
                'make': 'Test',
                'cylinders': r'$n',
                'doors': 4,
              },
              limitationCodes: ['basic_decode_only'],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      app(_listing(vinStatus: ListingVinStatus.formatValid)),
    );
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(r'$n'), findsNothing);
    expect(
      find.text(ru.listingBuyerVinReportNhtsaCylindersLabel),
      findsNothing,
    );
    expect(find.text(ru.listingBuyerVinReportNhtsaDoorsLabel), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('buyer report shows expanded NHTSA summary fields when present', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => Success(
        BuyerListingVinReportLookupResult(
          results: [
            BuyerListingVinReportSourceResult(
              sourceId: 'nhtsa_vpic',
              visibilityRaw: 'public_summary',
              normalizedSummary: {
                'make': 'Toyota',
                'trim': 'LE',
                'plant_country': 'Japan',
                'drive_type': 'FWD',
              },
              limitationCodes: ['basic_decode_only'],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      app(_listing(vinStatus: ListingVinStatus.formatValid)),
    );
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingBuyerVinReportNhtsaTrimLabel), findsOneWidget);
    expect(find.text('LE'), findsOneWidget);
    expect(
      find.text(ru.listingBuyerVinReportNhtsaPlantCountryLabel),
      findsOneWidget,
    );
    expect(find.text('Japan'), findsOneWidget);
    expect(
      find.text(ru.listingBuyerVinReportNhtsaDriveTypeLabel),
      findsOneWidget,
    );
    expect(find.text('FWD'), findsOneWidget);
    expect(
      find.text(ru.listingBuyerVinReportNhtsaCatalogSourceLine),
      findsOneWidget,
    );
  });

  testWidgets(
    'buyer report shows decoded summary when public_summary row returned',
    (tester) async {
      when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
        (_) async => Success(
          BuyerListingVinReportLookupResult(
            results: [
              BuyerListingVinReportSourceResult(
                sourceId: 'nhtsa_vpic',
                visibilityRaw: 'public_summary',
                normalizedSummary: {'make': 'HONDA'},
                fetchedAt: DateTime(2026, 5, 16),
                limitationCodes: ['basic_decode_only'],
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        app(_listing(vinStatus: ListingVinStatus.formatValid)),
      );
      await tester.pumpAndSettle();
      final tapTarget = find.byKey(
        const ValueKey('listing_vin_trust_badge_tap'),
      );
      await tester.ensureVisible(tapTarget);
      await tester.pumpAndSettle();
      await tester.tap(tapTarget);
      await tester.pumpAndSettle();
      expect(
        find.text(ru.listingBuyerVinReportNhtsaGroupCoreIdentity),
        findsOneWidget,
      );
      expect(
        find.text(ru.listingBuyerVinReportNhtsaCatalogSourceLine),
        findsOneWidget,
      );
      expect(
        find.text(ru.listingBuyerVinReportBasicDecodeNotOfficialLine),
        findsOneWidget,
      );
      expect(
        find.text(ru.listingBuyerVinReportNotVerifiedSectionTitle),
        findsOneWidget,
      );

      await tester.tap(
        find.text(ru.listingBuyerVinReportNotVerifiedSectionTitle),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ru.listingBuyerVinReportLimitationOwner),
        findsOneWidget,
      );
      expect(find.text('HONDA'), findsOneWidget);
      expect(find.textContaining('16.05.2026'), findsOneWidget);
      expect(find.text('2026-05-16'), findsNothing);
      expect(
        find.text(ru.listingBuyerVinReportSourcesSectionTitle),
        findsNothing,
      );
      for (final raw in [
        'basic_decode_only',
        'not_md_pmr_official_verification',
        'not_accident_history',
        'not_ownership_check',
        'not_insurance_check',
        'not_mileage_check',
        'not_registration_check',
      ]) {
        expect(find.textContaining(raw), findsNothing);
      }
    },
  );

  testWidgets('buyer report compare match when decode aligns with listing', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => Success(
        BuyerListingVinReportLookupResult(
          results: [
            BuyerListingVinReportSourceResult(
              sourceId: 'nhtsa_vpic',
              visibilityRaw: 'public_summary',
              normalizedSummary: {'make': 'Audi', 'model': 'A4', 'year': 2020},
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      app(_listing(vinStatus: ListingVinStatus.formatValid)),
    );
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingBuyerVinReportCompareMatch), findsOneWidget);
  });

  testWidgets(
    'buyer report compare mismatch when decode differs from listing',
    (tester) async {
      when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
        (_) async => Success(
          BuyerListingVinReportLookupResult(
            results: [
              BuyerListingVinReportSourceResult(
                sourceId: 'nhtsa_vpic',
                visibilityRaw: 'public_summary',
                normalizedSummary: {
                  'make': 'Toyota',
                  'model': 'Camry',
                  'year': 2019,
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        app(_listing(vinStatus: ListingVinStatus.formatValid)),
      );
      await tester.pumpAndSettle();
      final tapTarget = find.byKey(
        const ValueKey('listing_vin_trust_badge_tap'),
      );
      await tester.ensureVisible(tapTarget);
      await tester.pumpAndSettle();
      await tester.tap(tapTarget);
      await tester.pumpAndSettle();
      expect(
        find.text(ru.listingBuyerVinReportCompareMismatch),
        findsOneWidget,
      );
    },
  );

  testWidgets('buyer report shows unavailable state on repository failure', (
    tester,
  ) async {
    when(
      () => listingsRepo.fetchBuyerVinReportSources('l1'),
    ).thenAnswer((_) async => const FailureResult(ServerFailure('network')));
    await tester.pumpWidget(
      app(_listing(vinStatus: ListingVinStatus.formatValid)),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.listingVinReportUnavailableCta), findsOneWidget);
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingVinReportUnavailableTitle), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportLoadError), findsNothing);
  });

  testWidgets('pending report shows pending copy without green badge', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => Success(
        BuyerListingVinReportLookupResult(
          results: [
            BuyerListingVinReportSourceResult(
              sourceId: 'nhtsa_vpic',
              statusRaw: 'processing',
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      app(_listing(vinStatus: ListingVinStatus.formatValid)),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.listingVinReportPendingCta), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vin_present_latin_badge_v')),
      findsNothing,
    );
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingVinReportPendingTitle), findsWidgets);
    expect(find.text(ru.listingVinReportPendingBody), findsOneWidget);
  });

  testWidgets('not_provided shows muted absent state without report tap', (
    tester,
  ) async {
    await tester.pumpWidget(app(_listing()));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingVinNotProvidedTitle), findsOneWidget);
    expect(find.text(ru.listingVinBadgeIndicated), findsNothing);
    expect(
      find.byKey(const ValueKey('listing_vin_trust_badge_tap')),
      findsNothing,
    );
  });
}
