import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_details_fullscreen_gallery.dart';
import 'package:carzon/features/sellers/domain/entities/seller_public_profile.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
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

class _MemoryCompareRepository implements CompareRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<CompareItem>> loadItems() async => const [];

  @override
  Future<void> saveItems(List<CompareItem> value) async {}
}

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late CompareCubit compareCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;
  final ru = ruStrings();

  setUpAll(() => registerFallbackValue(''));

  setUp(() async {
    await sl.reset();
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    compareCubit = CompareCubit(repository: _MemoryCompareRepository());
    sellerProfileUseCase = MockGetSellerPublicProfile();
    stubSellerPublicProfileHidden(sellerProfileUseCase);

    when(() => detailsCubit.load(any())).thenAnswer((_) async {});

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

    registerListingDetailsSelfFetchStubs(sl);
    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
    sl.registerFactory<GetSellerPublicProfile>(() => sellerProfileUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  Listing listing() => Listing(
    id: 'l1',
    title: 'Audi A4 Premium',
    make: 'Audi',
    model: 'A4',
    year: 2020,
    priceEur: 18500,
    mileageKm: 72000,
    type: ListingType.sale,
    city: 'Chișinău',
    marketRegion: MarketRegion.moldova,
    createdAt: DateTime.utc(2026, 4, 1),
    status: ListingStatus.active,
    sellerId: 's1',
    contactPhone: '+37360000000',
  );

  SellerPublicProfile sellerProfile() => SellerPublicProfile(
    userId: 's1',
    displayName: 'Trusted Seller',
    avatarUrl: null,
    memberSince: DateTime.utc(2026, 3, 1),
    sellerType: SellerType.private,
    activeListingsCount: 2,
    ratingAverage: null,
    ratingCount: 0,
    reviewCount: 0,
    verifiedPhone: false,
    verifiedEmail: false,
    verifiedDealer: false,
  );

  Future<void> pumpDetails(
    WidgetTester tester,
    ListingDetailsState state, {
    bool settle = true,
  }) async {
    when(() => detailsCubit.state).thenReturn(state);
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: state,
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
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
          BlocProvider<CompareCubit>.value(value: compareCubit),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('listing details renders key chrome in dark theme', (
    tester,
  ) async {
    await pumpDetails(tester, ListingDetailsState.success(listing()));

    expect(find.text('Audi A4 Premium'), findsOneWidget);
    expect(find.text(ru.chatLabel), findsOneWidget);
    expect(find.text(ru.listingDetailsSpecs), findsOneWidget);
    expect(find.byType(AppBackButton), findsOneWidget);
  });

  testWidgets('seller trust section renders in dark theme', (tester) async {
    when(
      () => sellerProfileUseCase(any()),
    ).thenAnswer((_) async => Success(sellerProfile()));

    await pumpDetails(tester, ListingDetailsState.success(listing()));

    expect(find.text(ru.sellerSectionTitle), findsOneWidget);
    expect(find.text('Trusted Seller'), findsOneWidget);
  });

  testWidgets('loading below hero renders in dark theme', (tester) async {
    await pumpDetails(
      tester,
      const ListingDetailsState.loading(),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AppBackButton), findsOneWidget);
  });

  testWidgets('failure below hero renders retry in dark theme', (tester) async {
    await pumpDetails(
      tester,
      ListingDetailsState.failure(const AuthFailure('session')),
    );

    expect(find.text(ru.listingDetailsLoadFailed), findsOneWidget);
    expect(find.text(ru.commonRetry), findsOneWidget);
  });

  testWidgets('fullscreen gallery close chrome renders in dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: ListingDetailsFullscreenGalleryPage(
          listingId: 'l1',
          urls: const [
            'https://cdn.example/a.jpg',
            'https://cdn.example/b.jpg',
          ],
          initialIndex: 0,
          heroFlightSourceTopRadius: 0,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('listing-fullscreen-gallery')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
