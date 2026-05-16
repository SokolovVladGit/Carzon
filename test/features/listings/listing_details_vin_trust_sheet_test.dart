import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
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
import '../../helpers/seller_public_profile_test_mocks.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockListingsRepository extends Mock implements ListingsRepository {}

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
  late MockGetSellerPublicProfile sellerProfileUseCase;
  final ru = ruStrings();

  setUpAll(() => registerFallbackValue(''));

  setUp(() async {
    await sl.reset();
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    listingsRepo = _MockListingsRepository();
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
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('format_valid shows tappable VIN badge affordance', (
    tester,
  ) async {
    await tester.pumpWidget(app(_listing(vinStatus: ListingVinStatus.formatValid)));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingVinBadgeIndicated), findsOneWidget);
    expect(find.byKey(const ValueKey('listing_vin_trust_badge_tap')), findsOneWidget);
  });

  testWidgets('tap opens buyer VIN report shell (empty public sources, no full VIN)', (
    tester,
  ) async {
    await tester.pumpWidget(app(_listing(vinStatus: ListingVinStatus.formatValid)));
    await tester.pumpAndSettle();

    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();

    await tester.tap(tapTarget);
    await tester.pumpAndSettle();

    expect(find.text(ru.listingBuyerVinReportTitle), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportVinAddedBySeller), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportPublicDataUnavailable), findsOneWidget);
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

    expect(find.byKey(const ValueKey('buyer_vin_report_sheet_close')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buyer_vin_report_sheet_close')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buyer_vin_report_sheet_close')),
      findsNothing,
    );
  });

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
                'transmission': 'Automatic transmission with long descriptive label',
              },
              fetchedAt: DateTime(2026, 5, 16),
              limitationCodes: const ['basic_decode_only'],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(app(_listing(vinStatus: ListingVinStatus.formatValid)));
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();

    final closeBtn = find.byKey(const ValueKey('buyer_vin_report_sheet_close'));
    expect(closeBtn, findsOneWidget);
    expect(find.text('16.05.2026'), findsOneWidget);
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
  });

  testWidgets('buyer report shows error when RPC returns fetchFailed', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => const Success(
        BuyerListingVinReportLookupResult(fetchFailed: true),
      ),
    );
    await tester.pumpWidget(app(_listing(vinStatus: ListingVinStatus.formatValid)));
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingBuyerVinReportLoadError), findsOneWidget);
  });

  testWidgets('buyer report shows decoded summary when public_summary row returned', (
    tester,
  ) async {
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
    await tester.pumpWidget(app(_listing(vinStatus: ListingVinStatus.formatValid)));
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.editListingVinReportBasicInfoHeading), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportNhtsaCatalogSourceLine), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportBasicDecodeCatalogLine), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportBasicDecodeNotOfficialLine), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportNotVerifiedSectionTitle), findsOneWidget);
    expect(find.text(ru.listingBuyerVinReportLimitationOwner), findsOneWidget);
    expect(find.text('HONDA'), findsOneWidget);
    expect(find.text('16.05.2026'), findsOneWidget);
    expect(find.text('2026-05-16'), findsNothing);
    expect(find.text(ru.listingBuyerVinReportSourcesSectionTitle), findsNothing);
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
  });

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
              normalizedSummary: {
                'make': 'Audi',
                'model': 'A4',
                'year': 2020,
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(app(_listing(vinStatus: ListingVinStatus.formatValid)));
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingBuyerVinReportCompareMatch), findsOneWidget);
  });

  testWidgets('buyer report compare mismatch when decode differs from listing', (
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
                'model': 'Camry',
                'year': 2019,
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(app(_listing(vinStatus: ListingVinStatus.formatValid)));
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingBuyerVinReportCompareMismatch), findsOneWidget);
  });

  testWidgets('buyer report shows error on repository failure', (tester) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => const FailureResult(ServerFailure('network')),
    );
    await tester.pumpWidget(app(_listing(vinStatus: ListingVinStatus.formatValid)));
    await tester.pumpAndSettle();
    final tapTarget = find.byKey(const ValueKey('listing_vin_trust_badge_tap'));
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    expect(find.text(ru.listingBuyerVinReportLoadError), findsOneWidget);
  });

  testWidgets('not_provided hides VIN badge and tap target', (tester) async {
    await tester.pumpWidget(app(_listing()));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingVinBadgeIndicated), findsNothing);
    expect(find.byKey(const ValueKey('listing_vin_trust_badge_tap')), findsNothing);
  });
}
