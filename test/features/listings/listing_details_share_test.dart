import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/listings/presentation/utils/listing_share_launcher.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_share_button.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/ui/carzon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/compare_cubit_test_helpers.dart';
import '../../helpers/listing_details_self_fetch_stubs.dart';
import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/seller_public_profile_test_mocks.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Listing _seed() => Listing(
  id: 'listing-007',
  title: 'Skoda Octavia 1.8 TSI',
  make: 'Skoda',
  model: 'Octavia',
  year: 2017,
  priceEur: 10800,
  mileageKm: 132000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: 's1',
  contactPhone: '+373 000 000 001',
  telegramUsername: 'carzon_demo_01',
  whatsappEnabled: true,
);

void main() {
  final l10n = ruStrings();

  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late CompareCubit compareCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;

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

    final seeded = _seed();
    when(
      () => detailsCubit.state,
    ).thenReturn(ListingDetailsState.success(seeded));
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: ListingDetailsState.success(seeded),
    );
  });

  tearDown(() async {
    await compareCubit.close();
    await sl.reset();
  });

  Widget wrap({
    ListingShareLauncher? shareLauncher,
    ListingDetailsState? initialState,
  }) {
    if (initialState != null) {
      when(() => detailsCubit.state).thenReturn(initialState);
      whenListen(
        detailsCubit,
        const Stream<ListingDetailsState>.empty(),
        initialState: initialState,
      );
    }

    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
          BlocProvider<CompareCubit>.value(value: compareCubit),
        ],
        child: ListingDetailsPage(
          id: 'listing-007',
          shareLauncher: shareLauncher,
        ),
      ),
    );
  }

  testWidgets('share button visible on loaded listing details success', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byIcon(CarzonIcons.share), findsOneWidget);
    expect(find.byTooltip(l10n.listingShareAction), findsOneWidget);
  });

  testWidgets('share button hidden on unavailable listing failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        initialState: ListingDetailsState.failure(
          const NetworkFailure('offline'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(CarzonIcons.share), findsNothing);
    expect(find.byTooltip(l10n.listingShareAction), findsNothing);
  });

  testWidgets('tapping share invokes injected launcher with formatted text', (
    tester,
  ) async {
    String? sharedText;

    Future<void> launcher(String text) async {
      sharedText = text;
    }

    await tester.pumpWidget(wrap(shareLauncher: launcher));
    await tester.pump();

    await tester.tap(find.byTooltip(l10n.listingShareAction));
    await tester.pumpAndSettle();

    expect(sharedText, isNotNull);
    expect(sharedText!, contains(l10n.listingShareIntro));
    expect(sharedText!, contains('Skoda Octavia 1.8 TSI'));
    expect(sharedText!, contains('€10 800'));
    expect(sharedText!, contains('Tiraspol'));
    expect(sharedText!, contains(l10n.listingShareFallbackLine('listing-007')));
    expect(sharedText!, isNot(contains('+373')));
  });

  testWidgets('share failure shows localized snackbar', (tester) async {
    Future<void> launcher(String _) async =>
        throw const ListingShareUnavailableException();

    await tester.pumpWidget(wrap(shareLauncher: launcher));
    await tester.pump();

    await tester.tap(find.byTooltip(l10n.listingShareAction));
    await tester.pump();

    expect(find.text(l10n.listingShareFailed), findsOneWidget);
  });

  testWidgets('hero share controls fit on narrow width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(CarzonIcons.share), findsOneWidget);
  });

  testWidgets('share button uses injected shareUrlBuilder when provided', (
    tester,
  ) async {
    String? sharedText;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingShareButton(
          listing: _seed(),
          shareLauncher: (text) async {
            sharedText = text;
          },
          shareUrlBuilder: (_) => 'https://carzon.example/listings/listing-007',
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip(l10n.listingShareAction));
    await tester.pumpAndSettle();

    expect(sharedText, contains('https://carzon.example/listings/listing-007'));
  });
}
