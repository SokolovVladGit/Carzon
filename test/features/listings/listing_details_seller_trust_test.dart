import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/sellers/domain/entities/seller_public_profile.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/seller_public_profile_test_mocks.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;

  final ru = ruStrings();

  final listing = Listing(
    id: 'l1',
    title: 'Car',
    make: 'M',
    model: 'X',
    year: 2020,
    priceEur: 1,
    mileageKm: 1,
    type: ListingType.sale,
    city: 'Chișinău',
    marketRegion: MarketRegion.moldova,
    createdAt: DateTime.utc(2026, 4, 1),
    status: ListingStatus.active,
    sellerId: 'seller-uuid',
  );

  SellerPublicProfile profile() => SellerPublicProfile(
    userId: 'seller-uuid',
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

  setUp(() async {
    await sl.reset();
    registerFallbackValue('');
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    sellerProfileUseCase = MockGetSellerPublicProfile();

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

    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
    sl.registerFactory<GetSellerPublicProfile>(() => sellerProfileUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('seller trust section appears when profile resolves', (
    tester,
  ) async {
    when(
      () => sellerProfileUseCase(any()),
    ).thenAnswer((_) async => Success(profile()));

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

    await tester.pumpWidget(
      MultiBlocProvider(
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
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(ru.sellerSectionTitle), findsOneWidget);
    expect(find.text('Trusted Seller'), findsOneWidget);
    verify(() => sellerProfileUseCase('seller-uuid')).called(1);
  });

  testWidgets('no seller card when sellerId is null — does not crash', (
    tester,
  ) async {
    stubSellerPublicProfileHidden(sellerProfileUseCase);

    final listingNoSeller = Listing(
      id: 'l2',
      title: 'Car',
      make: 'M',
      model: 'X',
      year: 2020,
      priceEur: 1,
      mileageKm: 1,
      type: ListingType.sale,
      city: 'Chișinău',
      marketRegion: MarketRegion.moldova,
      createdAt: DateTime.utc(2026, 4, 1),
      status: ListingStatus.active,
      sellerId: null,
    );

    final initial = ListingDetailsState.success(listingNoSeller);
    when(() => detailsCubit.state).thenReturn(initial);
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: initial,
    );

    final router = GoRouter(
      initialLocation: '/listings/l2',
      routes: [
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) =>
              ListingDetailsPage(id: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
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
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(ru.sellerSectionTitle), findsNothing);
    verifyNever(() => sellerProfileUseCase(any()));
  });
}
