import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/browse_state_for_alert_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_filter_alert_ui_constants.dart';
import 'package:carzon/features/listings/presentation/pages/listings_page.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/browse_catalog_filter_alerts_sl.dart';
import '../../helpers/noop_last_applied_listing_discovery_repository.dart';

class _MockListingsBloc extends MockBloc<ListingsEvent, ListingsState>
    implements ListingsBloc {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockSellersRepository extends Mock implements SellersRepository {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

MySellerProfileModel _stubSellerSelf({
  String? displayName,
  String? avatarUrl,
}) => MySellerProfileModel(
  displayName: displayName,
  avatarUrl: avatarUrl,
  avatarPath: null,
  memberSince: DateTime.utc(2026, 4, 1),
  publicVisibility: true,
);

/// Builds a host that mounts [ListingsPage] behind a GoRouter with the
/// same top-level route path as the production router so the shared
/// bottom nav is free to render.
Widget _host({
  required ListingsBloc bloc,
  required AuthCubit auth,
  required FavoritesCubit favorites,
  required SellersRepository sellersRepo,
  required MessagingRepository messagingRepo,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ListingsPage()),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => Scaffold(body: Text(ruStrings().profileTitle)),
      ),
    ],
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: auth),
      BlocProvider<FavoritesCubit>.value(value: favorites),
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

void main() {
  setUpAll(() {
    registerFallbackValue(const ListingsRequested());
    registerFallbackValue(const ListingDiscoveryCriteria());
    registerFallbackValue(
      const ListingsRegionFilterChanged(MarketRegionFilter.both),
    );
    registerFallbackValue(
      const ListingsBodyTypeFilterChanged(ListingBodyType.suv),
    );
    registerFallbackValue('');
  });

  late _MockListingsBloc bloc;
  late _MockAuthCubit auth;
  late _MockFavoritesCubit favs;
  late _MockSellersRepository sellersRepo;
  late _MockMessagingRepository messagingRepo;

  late MockSavedSearchesRepository browseSavedSearchesRepo;
  late MockNotificationsRepository browseNotificationsRepo;
  late MockPushNotificationRegistrationService browsePushRegistration;

  final l10n = ruStrings();

  setUp(() async {
    await sl.reset();
    bloc = _MockListingsBloc();
    auth = _MockAuthCubit();
    favs = _MockFavoritesCubit();
    sellersRepo = _MockSellersRepository();
    messagingRepo = _MockMessagingRepository();

    when(
      () => sellersRepo.getSellerPublicProfile(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => sellersRepo.getMySellerProfile(),
    ).thenAnswer((_) async => Success(_stubSellerSelf(displayName: 'S')));
    when(
      () => messagingRepo.getUnreadConversationCount(),
    ).thenAnswer((_) async => const Success(0));

    when(() => bloc.state).thenReturn(
      const ListingsState(
        status: ListingsStatus.success,
        items: [],
        hasReachedEnd: true,
      ),
    );
    whenListen(
      bloc,
      const Stream<ListingsState>.empty(),
      initialState: const ListingsState(
        status: ListingsStatus.success,
        items: [],
        hasReachedEnd: true,
      ),
    );

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
      () => const NoopLastAppliedListingDiscoveryRepository(),
    );

    browseSavedSearchesRepo = MockSavedSearchesRepository();
    browseNotificationsRepo = MockNotificationsRepository();
    browsePushRegistration = MockPushNotificationRegistrationService();
    primeListingBrowseFilterAlertsDeps(
      sl,
      savedSearchesRepo: browseSavedSearchesRepo,
      notificationsRepo: browseNotificationsRepo,
      pushRegistration: browsePushRegistration,
    );

    sl.registerFactory<ListingsBloc>(() => bloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Listings feed editorial header', () {
    testWidgets('renders the Carzon logo as the sole header identity, with '
        'no large catalog title and no marketing subtitle', (tester) async {
      await tester.pumpWidget(
        _host(
          bloc: bloc,
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('listingsHeaderCarzonLogo')), findsOneWidget);
      expect(find.text('CARZON'), findsNothing);
      expect(find.text(l10n.catalogTitle), findsNothing);
      expect(find.text(l10n.catalogSubtitle), findsNothing);
    });

    testWidgets('keeps the localized search hint', (tester) async {
      await tester.pumpWidget(
        _host(
          bloc: bloc,
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
        ),
      );
      await tester.pump();

      expect(find.text(l10n.listingsSearchHint), findsOneWidget);
    });

    testWidgets(
      'does NOT render region chips on the home surface — region lives '
      'in the filters sheet in Pass 1.3',
      (tester) async {
        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pump();

        // Assert on the widget type, not raw text: the region label
        // "Все" collides with the body-category chip "Все" that now
        // lives on the home surface. The invariant we actually care
        // about is "no region SegmentedButton on the home feed".
        expect(find.byType(SegmentedButton<MarketRegionFilter>), findsNothing);
        // The two region-specific labels do not collide with any
        // other UI string, so the strict text check is preserved.
        expect(find.text(l10n.regionTransnistria), findsNothing);
        expect(find.text(l10n.regionMoldova), findsNothing);
      },
    );

    testWidgets('filter control is icon-only on the home surface — tooltip + '
        'semantics still expose it, but no visible "Фильтры" label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          bloc: bloc,
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
        ),
      );
      await tester.pump();

      // Pass 1.4 drops the text label to stop the filter button
      // competing with the editorial headline. The localized label
      // must only live in a Tooltip (hover/long-press) and in a
      // Semantics node so a11y/tests can still reach it.
      expect(find.text(l10n.filtersTitle), findsNothing);
      expect(find.byTooltip(l10n.listingsFiltersTooltip), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.listingsFiltersTooltip), findsWidgets);
    });

    testWidgets(
      'filter button inactive shows no numeric badge nor check atop filter icon',
      (tester) async {
        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();
        final filterScope = find.byTooltip(l10n.listingsFiltersTooltip);
        expect(
          find.descendant(of: filterScope, matching: find.byIcon(Icons.check)),
          findsNothing,
        );
        expect(
          find.descendant(of: filterScope, matching: find.text('1')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'filter button active shows check badge and chips; filter scope has no digits',
      (tester) async {
        const withMake = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Dacia',
        );
        when(() => bloc.state).thenReturn(withMake);
        whenListen(
          bloc,
          const Stream<ListingsState>.empty(),
          initialState: withMake,
        );
        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();
        final filterScope = find.byTooltip(l10n.listingsFiltersTooltip);
        expect(
          find.descendant(of: filterScope, matching: find.byIcon(Icons.check)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: filterScope, matching: find.text('1')),
          findsNothing,
        );
        expect(find.textContaining('Dacia'), findsWidgets);
      },
    );

    testWidgets(
      'body type chips are icon-only with semantics labels; tapping SUV '
      'dispatches ListingsBodyTypeFilterChanged(suv)',
      (tester) async {
        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel(l10n.listingBodyTypeSuv), findsOneWidget);
        expect(find.text(l10n.listingBodyTypeSuv), findsNothing);
        expect(find.bySemanticsLabel(l10n.listingsBodyChipAll), findsOneWidget);
        expect(find.text(l10n.listingsBodyChipAll), findsNothing);

        await tester.tap(find.bySemanticsLabel(l10n.listingBodyTypeSuv));
        await tester.pump();

        verify(
          () => bloc.add(
            const ListingsBodyTypeFilterChanged(ListingBodyType.suv),
          ),
        ).called(1);
      },
    );

    testWidgets('masthead includes account avatar control key', (tester) async {
      await tester.pumpWidget(
        _host(
          bloc: bloc,
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('feed_home_account_avatar_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping account avatar navigates toward profile route', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          bloc: bloc,
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('feed_home_account_avatar_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.profileTitle), findsOneWidget);
    });

    testWidgets('masthead unread badge avoids showing message count digits', (
      tester,
    ) async {
      when(
        () => messagingRepo.getUnreadConversationCount(),
      ).thenAnswer((_) async => const Success(14));
      when(() => auth.state).thenReturn(
        const AuthState.authenticated(
          AuthUser(id: 'u', email: 'u@example.com'),
        ),
      );
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(
          AuthUser(id: 'u', email: 'u@example.com'),
        ),
      );

      await tester.pumpWidget(
        _host(
          bloc: bloc,
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('feed_home_unread_indicator_dot')),
        findsOneWidget,
      );
      expect(find.text('14'), findsNothing);
      expect(find.text('1'), findsNothing);
    });

    testWidgets(
      'masthead unread dot is hidden when unread summary RPC fails with no prior count',
      (tester) async {
        when(() => messagingRepo.getUnreadConversationCount()).thenAnswer(
          (_) async => const FailureResult(NetworkFailure('temporary')),
        );
        when(() => auth.state).thenReturn(
          const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );
        whenListen(
          auth,
          const Stream<AuthState>.empty(),
          initialState: const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );

        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('feed_home_unread_indicator_dot')),
          findsNothing,
        );
      },
    );
  });

  group('Catalog discovery filter FAB filter-alert ornament', () {
    NotificationPreferences browsePrefsDeliveriesFullyOn() =>
        NotificationPreferences(
          userId: 'browse-fab-test',
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: true,
          priceDropsEnabled: false,
          createdAt: DateTime.utc(2026, 6, 1),
          updatedAt: DateTime.utc(2026, 6, 2),
        );

    SavedSearch enabledToyotaSavedRow(ListingDiscoveryCriteria crit) =>
        SavedSearch(
          id: 'ss-toyota-enabled',
          name: 'Toyota',
          criteria: crit,
          alertsEnabled: true,
          createdAt: DateTime.utc(2026, 6, 4),
          updatedAt: DateTime.utc(2026, 6, 5),
        );

    testWidgets(
      'shows amber bell ornament when deliveries are on AND saved Toyota criteria '
      'matches applied browse Toyota feed',
      (tester) async {
        const toyotaApplied = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Toyota',
        );
        final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
          toyotaApplied,
        );
        final savedRow = enabledToyotaSavedRow(critToyota);

        when(
          () => browseNotificationsRepo.getMyPreferences(),
        ).thenAnswer((_) async => Success(browsePrefsDeliveriesFullyOn()));
        when(
          () => browseSavedSearchesRepo.list(),
        ).thenAnswer((_) async => Success([savedRow]));

        when(() => auth.state).thenReturn(
          const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );
        whenListen(
          auth,
          const Stream<AuthState>.empty(),
          initialState: const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );

        when(() => bloc.state).thenReturn(toyotaApplied);
        whenListen(
          bloc,
          const Stream<ListingsState>.empty(),
          initialState: toyotaApplied,
        );
        await sl<BrowseCatalogFilterAlertsCubit>().onAuthChanged(auth.state);

        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.discoveryFilterFABAlertBellKey),
          findsOneWidget,
        );
        verify(() => browseNotificationsRepo.getMyPreferences()).called(1);
        verify(() => browseSavedSearchesRepo.list()).called(1);
      },
    );

    testWidgets(
      'does not adorn filter chip when deliveries are on yet applied discovery '
      'differs from the saved Toyota row',
      (tester) async {
        const toyotaCritFeed = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Toyota',
        );
        final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
          toyotaCritFeed,
        );
        final savedRow = enabledToyotaSavedRow(critToyota);

        when(
          () => browseNotificationsRepo.getMyPreferences(),
        ).thenAnswer((_) async => Success(browsePrefsDeliveriesFullyOn()));
        when(
          () => browseSavedSearchesRepo.list(),
        ).thenAnswer((_) async => Success([savedRow]));

        when(() => auth.state).thenReturn(
          const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );
        whenListen(
          auth,
          const Stream<AuthState>.empty(),
          initialState: const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );

        const mismatchFeed = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Skoda',
        );
        when(() => bloc.state).thenReturn(mismatchFeed);
        whenListen(
          bloc,
          const Stream<ListingsState>.empty(),
          initialState: mismatchFeed,
        );

        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.discoveryFilterFABAlertBellKey),
          findsNothing,
        );
      },
    );

    SavedSearch disabledToyotaSavedRow(ListingDiscoveryCriteria crit) =>
        SavedSearch(
          id: 'ss-toyota-disabled',
          name: 'Toyota',
          criteria: crit,
          alertsEnabled: false,
          createdAt: DateTime.utc(2026, 6, 4),
          updatedAt: DateTime.utc(2026, 6, 5),
        );

    testWidgets(
      'does not show active notification ornament when saved Toyota row matches '
      'applied Toyota feed but alerts_enabled is false',
      (tester) async {
        const toyotaApplied = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Toyota',
        );
        final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
          toyotaApplied,
        );
        final savedRow = disabledToyotaSavedRow(critToyota);

        when(
          () => browseNotificationsRepo.getMyPreferences(),
        ).thenAnswer((_) async => Success(browsePrefsDeliveriesFullyOn()));
        when(
          () => browseSavedSearchesRepo.list(),
        ).thenAnswer((_) async => Success([savedRow]));

        when(() => auth.state).thenReturn(
          const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );
        whenListen(
          auth,
          const Stream<AuthState>.empty(),
          initialState: const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );

        when(() => bloc.state).thenReturn(toyotaApplied);
        whenListen(
          bloc,
          const Stream<ListingsState>.empty(),
          initialState: toyotaApplied,
        );
        await sl<BrowseCatalogFilterAlertsCubit>().onAuthChanged(auth.state);

        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.discoveryFilterFABAlertBellKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'shows active notification ornament only when delivery fully enabled',
      (tester) async {
        const toyotaApplied = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Toyota',
        );
        final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
          toyotaApplied,
        );
        final savedRow = enabledToyotaSavedRow(critToyota);

        when(
          () => browseNotificationsRepo.getMyPreferences(),
        ).thenAnswer((_) async => Success(browsePrefsDeliveriesFullyOn()));
        when(
          () => browseSavedSearchesRepo.list(),
        ).thenAnswer((_) async => Success([savedRow]));

        when(() => auth.state).thenReturn(
          const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );
        whenListen(
          auth,
          const Stream<AuthState>.empty(),
          initialState: const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );

        when(() => bloc.state).thenReturn(toyotaApplied);
        whenListen(
          bloc,
          const Stream<ListingsState>.empty(),
          initialState: toyotaApplied,
        );
        await sl<BrowseCatalogFilterAlertsCubit>().onAuthChanged(auth.state);

        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.discoveryFilterFABAlertBellKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'active notification ornament absent when applied feed differs from saved row',
      (tester) async {
        const toyotaCritFeed = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Toyota',
        );
        final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
          toyotaCritFeed,
        );
        final savedRow = disabledToyotaSavedRow(critToyota);

        when(
          () => browseNotificationsRepo.getMyPreferences(),
        ).thenAnswer((_) async => Success(browsePrefsDeliveriesFullyOn()));
        when(
          () => browseSavedSearchesRepo.list(),
        ).thenAnswer((_) async => Success([savedRow]));

        when(() => auth.state).thenReturn(
          const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );
        whenListen(
          auth,
          const Stream<AuthState>.empty(),
          initialState: const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );

        const mismatchFeed = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Skoda',
        );
        when(() => bloc.state).thenReturn(mismatchFeed);
        whenListen(
          bloc,
          const Stream<ListingsState>.empty(),
          initialState: mismatchFeed,
        );

        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.discoveryFilterFABAlertBellKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'does not adorn filter chip for sort-only applied discovery versus saved Toyota',
      (tester) async {
        const toyotaCritFeed = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          make: 'Toyota',
        );
        final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
          toyotaCritFeed,
        );
        final savedRow = enabledToyotaSavedRow(critToyota);

        when(
          () => browseNotificationsRepo.getMyPreferences(),
        ).thenAnswer((_) async => Success(browsePrefsDeliveriesFullyOn()));
        when(
          () => browseSavedSearchesRepo.list(),
        ).thenAnswer((_) async => Success([savedRow]));

        when(() => auth.state).thenReturn(
          const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );
        whenListen(
          auth,
          const Stream<AuthState>.empty(),
          initialState: const AuthState.authenticated(
            AuthUser(id: 'u', email: 'u@example.com'),
          ),
        );

        const sortOnlyFeed = ListingsState(
          status: ListingsStatus.success,
          items: [],
          hasReachedEnd: true,
          sortOption: ListingSortOption.priceLowToHigh,
        );
        when(() => bloc.state).thenReturn(sortOnlyFeed);
        whenListen(
          bloc,
          const Stream<ListingsState>.empty(),
          initialState: sortOnlyFeed,
        );

        await tester.pumpWidget(
          _host(
            bloc: bloc,
            auth: auth,
            favorites: favs,
            sellersRepo: sellersRepo,
            messagingRepo: messagingRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.discoveryFilterFABAlertBellKey),
          findsNothing,
        );
      },
    );
  });
}
