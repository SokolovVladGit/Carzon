import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/pages/listings_page.dart';
import 'package:carzon/features/listings/presentation/pages/listings_search_page.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';
import 'package:carzon/features/listings/presentation/widgets/listings_search_filter_bar.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/browse_catalog_filter_alerts_sl.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockSellersRepository extends Mock implements SellersRepository {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

class _SeededLastApplied implements LastAppliedListingDiscoveryRepository {
  _SeededLastApplied(this.snapshot);

  ListingDiscoveryCriteria? snapshot;
  ListingDiscoveryCriteria? lastPersisted;

  @override
  Future<ListingDiscoveryCriteria?> load() async => snapshot;

  @override
  Future<void> persistIfNeeded(ListingDiscoveryCriteria next) async {
    lastPersisted = next;
  }
}

MySellerProfileModel _stubSellerSelf() => MySellerProfileModel(
  displayName: 'S',
  avatarUrl: null,
  avatarPath: null,
  memberSince: DateTime.utc(2026, 4, 1),
  publicVisibility: true,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  late _MockAuthCubit auth;
  late _MockFavoritesCubit favs;
  late _MockSellersRepository sellersRepo;
  late _MockMessagingRepository messagingRepo;
  late _SeededLastApplied lastApplied;
  late ListingsFeedLaunch? capturedLaunch;

  setUp(() async {
    await sl.reset();
    auth = _MockAuthCubit();
    favs = _MockFavoritesCubit();
    sellersRepo = _MockSellersRepository();
    messagingRepo = _MockMessagingRepository();
    lastApplied = _SeededLastApplied(
      const ListingDiscoveryCriteria(search: 'golf', make: 'Volkswagen'),
    );
    capturedLaunch = null;

    when(
      () => sellersRepo.getMySellerProfile(),
    ).thenAnswer((_) async => Success(_stubSellerSelf()));
    when(
      () => messagingRepo.getUnreadConversationCount(),
    ).thenAnswer((_) async => const Success(0));
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
      () => lastApplied,
    );
    primeListingBrowseFilterAlertsDeps(
      sl,
      savedSearchesRepo: MockSavedSearchesRepository(),
      notificationsRepo: MockNotificationsRepository(),
      pushRegistration: MockPushNotificationRegistrationService(),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget host({String initial = AppRoutes.search}) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, state) {
            final extra = state.extra;
            if (extra is ListingsFeedLaunch) capturedLaunch = extra;
            return const Scaffold(body: Text('home-feed'));
          },
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (_, _) => const ListingsSearchPage(),
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: auth),
        BlocProvider<FavoritesCubit>.value(value: favs),
        BlocProvider(
          create: (_) => SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
        ),
        BlocProvider(create: (_) => MessagingUnreadSummaryCubit(messagingRepo)),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('Search page renders text search and filter form, not a feed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byType(ListingsSearchPage), findsOneWidget);
    expect(find.byType(ListingsFilterForm), findsOneWidget);
    expect(
      find.byKey(const ValueKey('listings_filter_search_field')),
      findsOneWidget,
    );
    expect(find.byType(ListingsSearchFilterBar), findsNothing);
    expect(find.byType(ListingsPage), findsNothing);
    expect(find.text('golf'), findsOneWidget);
  });

  testWidgets('dismiss returns Home without ListingsFeedLaunch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(ruStrings().filtersDismissTooltip));
    await tester.pumpAndSettle();

    expect(find.text('home-feed'), findsOneWidget);
    expect(capturedLaunch, isNull);
    expect(lastApplied.lastPersisted, isNull);
  });

  testWidgets('apply includes search and structured filters and goes Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('listings_filter_search_field')),
      'passat',
    );
    await tester.pump();

    await tester.tap(
      find.widgetWithText(FilledButton, ruStrings().filterShowCars),
    );
    await tester.pumpAndSettle();

    expect(find.text('home-feed'), findsOneWidget);
    expect(capturedLaunch, isNotNull);
    expect(capturedLaunch!.snapshot.search, 'passat');
    expect(capturedLaunch!.snapshot.make, 'Volkswagen');
  });

  testWidgets(
    'Search seed reflects newest LastApplied without a listings fetch',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      lastApplied.snapshot = const ListingDiscoveryCriteria(
        search: 'celica',
        make: 'Toyota',
      );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.byType(ListingsSearchPage), findsOneWidget);
      expect(find.text('celica'), findsOneWidget);
      expect(find.text('Toyota'), findsOneWidget);
    },
  );
}
