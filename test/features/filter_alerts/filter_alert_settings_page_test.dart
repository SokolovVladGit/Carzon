import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/saved_searches_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/delete_saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/list_saved_searches.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/set_saved_search_alerts_enabled.dart';
import 'package:carzon/features/filter_alerts/presentation/cubit/saved_searches_cubit.dart';
import 'package:carzon/features/filter_alerts/presentation/pages/filter_alert_settings_page.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/entities/push_token_platform.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/noop_last_applied_listing_discovery_repository.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockSavedSearchesRepository extends Mock
    implements SavedSearchesRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockPushRegistration extends Mock
    implements PushNotificationRegistrationService {}

NotificationPreferences _defaultNotificationPreferences() {
  return NotificationPreferences(
    userId: 'u1',
    globalEnabled: false,
    messagesEnabled: false,
    filterAlertsEnabled: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
}

SavedSearch _bmwSavedSearch({bool alertsEnabled = false}) {
  return SavedSearch(
    id: 'ss-bmw',
    name: 'BMW 320',
    criteria: const ListingDiscoveryCriteria(
      make: 'BMW',
      model: '320',
      minYear: 2018,
      maxYear: 2024,
      minPrice: 5000,
      maxPrice: 20000,
      priceCurrencyFilter: ListingPriceCurrencyFilter.eur,
      maxMileage: 150000,
      city: 'Тирасполь',
      marketRegion: MarketRegion.transnistria,
      bodyType: ListingBodyType.sedan,
    ),
    alertsEnabled: alertsEnabled,
    createdAt: DateTime.utc(2026, 5, 1),
    updatedAt: DateTime.utc(2026, 5, 2),
  );
}

void _registerSlWithRepository({
  required SavedSearchesRepository repo,
  required NotificationsRepository notificationsRepository,
  required PushNotificationRegistrationService pushRegistration,
}) {
  sl.registerLazySingleton<LastAppliedListingDiscoveryRepository>(
    () => const NoopLastAppliedListingDiscoveryRepository(),
  );
  sl.registerLazySingleton<SavedSearchesRepository>(() => repo);
  sl.registerLazySingleton<NotificationsRepository>(
    () => notificationsRepository,
  );
  sl.registerLazySingleton<PushNotificationRegistrationService>(
    () => pushRegistration,
  );
  sl.registerFactory(() => ListSavedSearches(sl<SavedSearchesRepository>()));
  sl.registerFactory(() => DeleteSavedSearch(sl<SavedSearchesRepository>()));
  sl.registerFactory(
    () => SetSavedSearchAlertsEnabled(sl<SavedSearchesRepository>()),
  );
  sl.registerLazySingleton(
    () => FilterAlertDeliveryOrchestrator(
      notificationsRepository: sl(),
      pushRegistration: sl(),
      setAlertsEnabled: sl(),
    ),
  );
  sl.registerFactory(
    () => SavedSearchesCubit(
      listSavedSearches: sl<ListSavedSearches>(),
      deleteSavedSearch: sl<DeleteSavedSearch>(),
      deliveryOrchestrator: sl(),
    ),
  );
}

class _RecordingGoRouter {
  final List<({String location, Object? extra})> calls = [];
}

Widget _wrappedPage(
  _MockAuthCubit auth, {
  required _RecordingGoRouter recorder,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.filterAlert,
    routes: [
      GoRoute(
        path: AppRoutes.filterAlert,
        builder: (_, _) => BlocProvider<AuthCubit>.value(
          value: auth,
          child: const FilterAlertSettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.listings,
        builder: (context, state) {
          final extra = state.extra;
          recorder.calls.add((location: AppRoutes.listings, extra: extra));
          return const Scaffold(body: Text('catalog_landing_for_test'));
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) =>
            const Scaffold(body: Text('profile_landing_for_test')),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, _) =>
            const Scaffold(body: Text('sign_in_landing_for_test')),
      ),
    ],
  );
  return MaterialApp.router(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  late _MockAuthCubit auth;
  late _MockSavedSearchesRepository repo;
  late _MockNotificationsRepository notificationsRepo;
  late _MockPushRegistration pushRegistration;
  late _RecordingGoRouter routeRecorder;

  setUp(() {
    auth = _MockAuthCubit();
    repo = _MockSavedSearchesRepository();
    notificationsRepo = _MockNotificationsRepository();
    pushRegistration = _MockPushRegistration();
    routeRecorder = _RecordingGoRouter();
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
    );
    registerFallbackValue(PushTokenPlatform.android);
    when(
      () => notificationsRepo.getMyPreferences(),
    ).thenAnswer((_) async => Success(_defaultNotificationPreferences()));
    when(
      () => notificationsRepo.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
      ),
    ).thenAnswer((invocation) async {
      final global = invocation.namedArguments[#globalEnabled] as bool;
      final messages = invocation.namedArguments[#messagesEnabled] as bool;
      final filterAlerts =
          invocation.namedArguments[#filterAlertsEnabled] as bool;
      return Success(
        NotificationPreferences(
          userId: 'u1',
          globalEnabled: global,
          messagesEnabled: messages,
          filterAlertsEnabled: filterAlerts,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      );
    });
    when(
      () => pushRegistration.requestOsNotificationPermission(),
    ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
    when(
      () => pushRegistration.syncTokenWithBackendIfEligible(),
    ).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('empty list: shows empty card and go-to-catalog CTA', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.list()).thenAnswer((_) async => const Success([]));
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(
      repo: repo,
      notificationsRepository: notificationsRepo,
      pushRegistration: pushRegistration,
    );

    final l10n = ruStrings();
    await tester.pumpWidget(_wrappedPage(auth, recorder: routeRecorder));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('saved_searches_empty_card')),
      findsOneWidget,
    );
    expect(find.text(l10n.savedSearchesEmptyTitle), findsOneWidget);
    expect(find.text(l10n.savedSearchesEmptyBody), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('saved_searches_go_to_catalog')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('saved_searches_go_to_catalog')),
    );
    await tester.pumpAndSettle();
    expect(find.text('catalog_landing_for_test'), findsOneWidget);
    expect(routeRecorder.calls, isNotEmpty);
    expect(routeRecorder.calls.first.location, AppRoutes.listings);
  });

  testWidgets('saved searches list: shows summary rows and delete action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(
      () => repo.list(),
    ).thenAnswer((_) async => Success([_bmwSavedSearch()]));
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(
      repo: repo,
      notificationsRepository: notificationsRepo,
      pushRegistration: pushRegistration,
    );

    final l10n = ruStrings();
    await tester.pumpWidget(_wrappedPage(auth, recorder: routeRecorder));
    await tester.pumpAndSettle();

    expect(find.text('BMW 320'), findsOneWidget);
    expect(find.text('BMW'), findsOneWidget);
    expect(find.text('320'), findsOneWidget);
    expect(find.text('2018–2024'), findsOneWidget);
    expect(find.text('Тирасполь'), findsOneWidget);
    expect(find.text(l10n.regionTransnistria), findsOneWidget);
    expect(find.text(l10n.listingBodyTypeSedan), findsOneWidget);
    expect(find.text(l10n.filterMake), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('saved_search_delete_ss-bmw')),
      findsOneWidget,
    );
    expect(find.text(l10n.savedSearchAlertsToggleTitle), findsOneWidget);
  });

  testWidgets('push disabled: toggle is inactive and shows localized notice', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.list()).thenAnswer(
      (_) async => Success([
        SavedSearch(
          id: 'ss-audi',
          name: 'Audi',
          criteria: const ListingDiscoveryCriteria(make: 'Audi'),
          alertsEnabled: false,
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 2),
        ),
      ]),
    );
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(
      repo: repo,
      notificationsRepository: notificationsRepo,
      pushRegistration: pushRegistration,
    );

    final l10n = ruStrings();
    await tester.pumpWidget(_wrappedPage(auth, recorder: routeRecorder));
    await tester.pumpAndSettle();

    expect(find.text(l10n.savedSearchAlertsToggleTitle), findsOneWidget);
    expect(
      find.text(l10n.filterAlertNotificationsPushDisabled),
      findsOneWidget,
    );
    final tileFinder = find.ancestor(
      of: find.text(l10n.savedSearchAlertsToggleTitle),
      matching: find.byType(SwitchListTile),
    );
    expect(tileFinder, findsOneWidget);
    expect(tester.widget<SwitchListTile>(tileFinder).onChanged, isNull);
    verifyNever(() => pushRegistration.requestOsNotificationPermission());
    verifyNever(() => pushRegistration.syncTokenWithBackendIfEligible());
    verifyNever(
      () => notificationsRepo.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
      ),
    );
  });

  testWidgets('delete action: confirm dialog → delete RPC', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    var listCount = 0;
    when(() => repo.list()).thenAnswer((_) async {
      listCount++;
      return Success(listCount == 1 ? [_bmwSavedSearch()] : const []);
    });
    when(() => repo.delete('ss-bmw')).thenAnswer((_) async {
      return const Success(null);
    });
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(
      repo: repo,
      notificationsRepository: notificationsRepo,
      pushRegistration: pushRegistration,
    );

    final l10n = ruStrings();
    await tester.pumpWidget(_wrappedPage(auth, recorder: routeRecorder));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('saved_search_delete_ss-bmw')),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.savedSearchDeleteConfirmTitle), findsOneWidget);
    expect(find.text(l10n.savedSearchDeleteConfirmBody), findsOneWidget);

    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    verifyNever(() => repo.delete(any()));

    await tester.tap(
      find.byKey(const ValueKey<String>('saved_search_delete_ss-bmw')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('saved_search_delete_confirm_cta')),
    );
    await tester.pumpAndSettle();

    verify(() => repo.delete('ss-bmw')).called(1);
    expect(find.text(l10n.savedSearchRemovedSnack), findsOneWidget);
    expect(find.text('BMW 320'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('saved_searches_empty_card')),
      findsOneWidget,
    );
  });

  testWidgets('toggle on: enables alerts via orchestrator path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );

    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(
      () => repo.list(),
    ).thenAnswer((_) async => Success([_bmwSavedSearch()]));
    when(
      () => repo.setAlertsEnabled('ss-bmw', true),
    ).thenAnswer((_) async => Success(_bmwSavedSearch(alertsEnabled: true)));
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(
      repo: repo,
      notificationsRepository: notificationsRepo,
      pushRegistration: pushRegistration,
    );

    await tester.pumpWidget(_wrappedPage(auth, recorder: routeRecorder));
    await tester.pumpAndSettle();

    final switchTile = find.ancestor(
      of: find.text(ruStrings().savedSearchAlertsToggleTitle),
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(switchTile);
    await tester.pumpAndSettle();

    verify(() => repo.setAlertsEnabled('ss-bmw', true)).called(1);
    verifyNever(() => repo.delete(any()));
    expect(find.text('BMW 320'), findsOneWidget);
  });

  testWidgets('load failure: localized message + retry recalls repository', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    var loadCount = 0;
    when(() => repo.list()).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 1) {
        return const FailureResult(NetworkFailure('offline_probe'));
      }
      return const Success([]);
    });
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(
      repo: repo,
      notificationsRepository: notificationsRepo,
      pushRegistration: pushRegistration,
    );

    final l10n = ruStrings();
    await tester.pumpWidget(_wrappedPage(auth, recorder: routeRecorder));
    await tester.pumpAndSettle();

    expect(find.text(l10n.savedSearchesLoadFailed), findsOneWidget);
    expect(find.text('offline_probe'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(
      find.byKey(const ValueKey<String>('saved_searches_empty_card')),
      findsOneWidget,
    );
  });

  testWidgets('load failure: hides PostgREST-style technical payloads', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.list()).thenAnswer(
      (_) async => const FailureResult(
        ServerFailure(
          'PGRST116 {"hint":null,"message":"saved_searches row missing","code":"PGRST"}',
        ),
      ),
    );
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(
      repo: repo,
      notificationsRepository: notificationsRepo,
      pushRegistration: pushRegistration,
    );

    final l10n = ruStrings();
    await tester.pumpWidget(_wrappedPage(auth, recorder: routeRecorder));
    await tester.pumpAndSettle();

    expect(find.text(l10n.savedSearchesLoadFailed), findsOneWidget);
    expect(find.textContaining('PGRST'), findsNothing);
    expect(find.textContaining('saved_searches'), findsNothing);
  });

  testWidgets('unauthenticated: sign-in CTA + repository never called', (
    tester,
  ) async {
    when(() => auth.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await sl.reset();
    _registerSlWithRepository(
      repo: repo,
      notificationsRepository: notificationsRepo,
      pushRegistration: pushRegistration,
    );

    final l10n = ruStrings();
    await tester.pumpWidget(_wrappedPage(auth, recorder: routeRecorder));
    await tester.pumpAndSettle();

    expect(find.text(l10n.savedSearchesSignInRequired), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.commonSignIn),
      findsOneWidget,
    );
    verifyNever(() => repo.list());
  });
}
