import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
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
import '../../helpers/compare_cubit_test_helpers.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Listing _listing({String? variant}) => Listing(
  id: 'l1',
  title: 'Test',
  make: 'BMW',
  model: '3 Series',
  variant: variant,
  year: 2022,
  priceEur: 1000,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Chișinău',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: 's1',
);

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
    compareCubit = newInMemoryCompareCubit();
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
    await compareCubit.close();
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

  testWidgets('variant row is visible when set', (tester) async {
    await tester.pumpWidget(app(_listing(variant: 'M340i')));
    await tester.pumpAndSettle();
    expect(find.text(ru.listingVariantLabel), findsOneWidget);
    expect(find.text('M340i'), findsOneWidget);
  });

  testWidgets('variant row is absent when null', (tester) async {
    await tester.pumpWidget(app(_listing()));
    await tester.pumpAndSettle();
    expect(find.text(ru.listingVariantLabel), findsNothing);
  });
}
