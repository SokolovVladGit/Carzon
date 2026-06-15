import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/l10n/app_localizations.dart';
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

  testWidgets('shows muted VIN absent state when vin_status is not_provided', (
    tester,
  ) async {
    await tester.pumpWidget(app(_listing()));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingVinNotProvidedTitle), findsOneWidget);
    expect(find.text(ru.listingVinNotProvidedHint), findsOneWidget);
    expect(find.text(ru.listingVinBadgeIndicated), findsNothing);
    expect(
      find.byKey(const ValueKey('listing_vin_trust_badge_tap')),
      findsNothing,
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('VIN absent state does not open buyer report sheet on tap', (
    tester,
  ) async {
    await tester.pumpWidget(app(_listing()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('listing_vin_absent_state')));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingBuyerVinReportTitle), findsNothing);
  });

  testWidgets(
    'format_valid without decode shows no-data CTA without green badge',
    (tester) async {
      await tester.pumpWidget(
        app(_listing(vinStatus: ListingVinStatus.formatValid)),
      );
      await tester.pumpAndSettle();

      expect(find.text(ru.listingVinBadgeIndicated), findsOneWidget);
      expect(find.text(ru.listingVinReportNoDataCta), findsOneWidget);
      expect(find.text(ru.listingVinReportOpenHint), findsNothing);
      expect(
        find.byKey(const ValueKey('vin_present_latin_badge_v')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('listing_vin_trust_badge_tap')),
        findsOneWidget,
      );
    },
  );

  testWidgets('format_valid with decode shows open hint and green V badge', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => Success(
        BuyerListingVinReportLookupResult(
          results: [
            BuyerListingVinReportSourceResult(
              sourceId: 'nhtsa_vpic',
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

    expect(find.text(ru.listingVinReportOpenHint), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vin_present_latin_badge_v')),
      findsOneWidget,
    );
  });

  testWidgets('pending report does not show green V badge on listing CTA', (
    tester,
  ) async {
    when(() => listingsRepo.fetchBuyerVinReportSources('l1')).thenAnswer(
      (_) async => Success(
        BuyerListingVinReportLookupResult(
          results: [
            BuyerListingVinReportSourceResult(
              sourceId: 'nhtsa_vpic',
              statusRaw: 'pending',
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
  });
}
