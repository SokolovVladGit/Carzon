import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
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
import '../../helpers/seller_public_profile_test_mocks.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Listing _listing({
  ListingFuelType? fuel,
  double? liters,
  int? hp,
  ListingDrivetrain? drivetrain,
  String? registration,
  String? description,
  String city = 'Chișinău',
}) => Listing(
  id: 'l1',
  title: 'Test',
  make: 'Audi',
  model: 'A4',
  year: 2020,
  priceEur: 1000,
  mileageKm: 50000,
  type: ListingType.sale,
  city: city,
  marketRegion: MarketRegion.moldova,
  fuelType: fuel,
  engineDisplacementLiters: liters,
  enginePowerHp: hp,
  drivetrain: drivetrain,
  registration: registration,
  description: description,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: 's1',
);

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;
  final ru = ruStrings();

  setUpAll(() => registerFallbackValue(''));

  setUp(() async {
    await sl.reset();
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
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

  testWidgets('characteristics omit legacy marketplace Region row', (
    tester,
  ) async {
    await tester.pumpWidget(app(_listing()));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingFieldRegion), findsNothing);
  });

  testWidgets(
    'characteristics surfaces fuel, drivetrain, registration, displacement, power',
    (tester) async {
      await tester.pumpWidget(
        app(
          _listing(
            fuel: ListingFuelType.petrol,
            liters: 2,
            hp: 190,
            drivetrain: ListingDrivetrain.awd,
            registration: 'Chișinău',
            city: 'Tiraspol',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(ru.listingFuelTypePetrol), findsOneWidget);
      expect(find.text(ru.listingDrivetrainAwd), findsOneWidget);
      expect(find.text('190 ${ru.listingEnginePowerHpSuffix}'), findsOneWidget);
      expect(
        find.text('2 ${ru.listingEngineDisplacementLitersSuffix}'),
        findsOneWidget,
      );
      expect(find.text('Chișinău'), findsOneWidget);
    },
  );

  testWidgets('description section is hidden when description empty', (
    tester,
  ) async {
    await tester.pumpWidget(app(_listing(description: null)));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingDetailsDescriptionSection), findsNothing);
  });

  testWidgets('description section shows trimmed body when description set', (
    tester,
  ) async {
    await tester.pumpWidget(app(_listing(description: '  Unique paint  ')));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingDetailsDescriptionSection), findsOneWidget);
    expect(find.text('Unique paint'), findsOneWidget);
  });
}
