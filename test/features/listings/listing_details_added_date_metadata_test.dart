import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_view_stats.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_details_metadata_chips.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/compare_cubit_test_helpers.dart';
import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/seller_public_profile_test_mocks.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Listing _listing({int viewCount = 128}) => Listing(
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
  createdAt: DateTime.utc(2026, 5, 16),
  status: ListingStatus.active,
  sellerId: 's1',
  viewCount: viewCount,
);

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late CompareCubit compareCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;

  setUpAll(() async {
    registerFallbackValue('');
    await initializeDateFormatting('ru');
    await initializeDateFormatting('ro');
  });

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

    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
    sl.registerFactory<GetSellerPublicProfile>(() => sellerProfileUseCase);
  });

  tearDown(() async {
    await compareCubit.close();
    await sl.reset();
  });

  Widget app({
    required Locale locale,
    required Listing listing,
    ListingViewStats? viewStats,
  }) {
    final initial = ListingDetailsState.success(listing, viewStats: viewStats);

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
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('metadata renders as chips instead of a single inline line', (
    tester,
  ) async {
    final ru = ruStrings();
    final listing = _listing();

    await tester.pumpWidget(
      app(
        locale: const Locale('ru'),
        listing: listing,
        viewStats: const ListingViewStats(totalViews: 128, todayViews: 12),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListingDetailsMetadataChips), findsOneWidget);
    expect(find.byType(Wrap), findsWidgets);

    final inlineLine = [
      ru.listingDetailsMetadataViews(128),
      ru.listingDetailsMetadataViewsToday(12),
      ru.listingDetailsMetadataAddedOn(
        formatListingAddedDate(ru, listing.createdAt),
      ),
    ].join(' · ');
    expect(find.text(inlineLine), findsNothing);
  });

  testWidgets(
    'header shows RU metadata chips with views, today, and added date',
    (tester) async {
      final ru = ruStrings();
      final listing = _listing();

      await tester.pumpWidget(
        app(
          locale: const Locale('ru'),
          listing: listing,
          viewStats: const ListingViewStats(totalViews: 128, todayViews: 12),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(ru.listingDetailsMetadataViews(128)), findsOneWidget);
      expect(
        find.text(ru.listingDetailsMetadataViewsToday(12)),
        findsOneWidget,
      );
      expect(
        find.text(formatListingAddedDate(ru, listing.createdAt)),
        findsOneWidget,
      );
      expect(find.text(ru.listingFieldPosted), findsNothing);
      expect(find.text(formatDate(listing.createdAt)), findsNothing);
      expect(
        find.text(
          ru.listingDetailsMetadataAddedOn(
            formatListingAddedDate(ru, listing.createdAt),
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'header shows RO metadata chips with views, today, and added date',
    (tester) async {
      final ro = roStrings();
      final listing = _listing();

      await tester.pumpWidget(
        app(
          locale: const Locale('ro'),
          listing: listing,
          viewStats: const ListingViewStats(totalViews: 128, todayViews: 12),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(ro.listingDetailsMetadataViews(128)), findsOneWidget);
      expect(
        find.text(ro.listingDetailsMetadataViewsToday(12)),
        findsOneWidget,
      );
      expect(
        find.text(formatListingAddedDate(ro, listing.createdAt)),
        findsOneWidget,
      );
      expect(find.text(ro.listingFieldPosted), findsNothing);
      expect(ro.listingDetailsMetadataViewsToday(12), 'Astăzi +12');
    },
  );

  testWidgets('total views chip shows even when count is zero', (tester) async {
    final ru = ruStrings();
    final listing = _listing(viewCount: 0);

    await tester.pumpWidget(
      app(
        locale: const Locale('ru'),
        listing: listing,
        viewStats: const ListingViewStats(totalViews: 0, todayViews: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.listingDetailsMetadataViews(0)), findsOneWidget);
  });

  testWidgets('today chip hidden when today count is zero', (tester) async {
    final ru = ruStrings();
    final listing = _listing(viewCount: 5);

    await tester.pumpWidget(
      app(
        locale: const Locale('ru'),
        listing: listing,
        viewStats: const ListingViewStats(totalViews: 5, todayViews: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.listingDetailsMetadataViews(5)), findsOneWidget);
    expect(find.textContaining('Сегодня'), findsNothing);
    expect(find.textContaining('сегодня'), findsNothing);
  });

  testWidgets('today chip hidden when today count is unavailable', (
    tester,
  ) async {
    final ru = ruStrings();
    final listing = _listing(viewCount: 5);

    await tester.pumpWidget(app(locale: const Locale('ru'), listing: listing));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingDetailsMetadataViews(5)), findsOneWidget);
    expect(find.textContaining('Сегодня'), findsNothing);
  });

  testWidgets('today chip uses localized live copy when count is positive', (
    tester,
  ) async {
    final ru = ruStrings();
    final listing = _listing();

    await tester.pumpWidget(
      app(
        locale: const Locale('ru'),
        listing: listing,
        viewStats: const ListingViewStats(totalViews: 1, todayViews: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сегодня +1'), findsOneWidget);
    expect(ru.listingDetailsMetadataViewsToday(1), 'Сегодня +1');
  });
}
