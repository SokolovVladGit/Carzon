import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/filter_alerts/domain/entities/filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/filter_alerts_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/clear_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/get_filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/save_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/set_filter_alert_notifications_enabled.dart';
import 'package:carzon/features/filter_alerts/presentation/cubit/filter_alert_settings_cubit.dart';
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

class _MockFilterAlertsRepository extends Mock
    implements FilterAlertsRepository {}

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

void _registerSlWithRepository({
  required FilterAlertsRepository repo,
  required NotificationsRepository notificationsRepository,
  required PushNotificationRegistrationService pushRegistration,
}) {
  sl.registerLazySingleton<LastAppliedListingDiscoveryRepository>(
    () => const NoopLastAppliedListingDiscoveryRepository(),
  );
  sl.registerLazySingleton<FilterAlertsRepository>(() => repo);
  sl.registerLazySingleton<NotificationsRepository>(
    () => notificationsRepository,
  );
  sl.registerLazySingleton<PushNotificationRegistrationService>(
    () => pushRegistration,
  );
  sl.registerFactory(
    () => GetFilterAlertSettings(sl<FilterAlertsRepository>()),
  );
  sl.registerFactory(
    () => SaveFilterAlertCriteria(sl<FilterAlertsRepository>()),
  );
  sl.registerFactory(
    () => ClearFilterAlertCriteria(sl<FilterAlertsRepository>()),
  );
  sl.registerFactory(
    () => SetFilterAlertNotificationsEnabled(sl<FilterAlertsRepository>()),
  );
  sl.registerLazySingleton(
    () => FilterAlertDeliveryOrchestrator(
      notificationsRepository: sl(),
      pushRegistration: sl(),
      setNotificationsEnabled: sl(),
    ),
  );
  sl.registerFactory(
    () => FilterAlertSettingsCubit(
      getSettings: sl<GetFilterAlertSettings>(),
      saveCriteria: sl<SaveFilterAlertCriteria>(),
      clearCriteria: sl<ClearFilterAlertCriteria>(),
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
          return const Scaffold(
            body: Text('catalog_landing_for_test'),
          );
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
  late _MockFilterAlertsRepository repo;
  late _MockNotificationsRepository notificationsRepo;
  late _MockPushRegistration pushRegistration;
  late _RecordingGoRouter routeRecorder;

  setUp(() {
    auth = _MockAuthCubit();
    repo = _MockFilterAlertsRepository();
    notificationsRepo = _MockNotificationsRepository();
    pushRegistration = _MockPushRegistration();
    routeRecorder = _RecordingGoRouter();
    // Default to **push disabled** so tests verify the no-permission /
    // no-FirebaseMessaging baseline. Individual tests override when they
    // need push semantics on.
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
    );
    registerFallbackValue(PushTokenPlatform.android);
    when(() => notificationsRepo.getMyPreferences()).thenAnswer(
      (_) async => Success(_defaultNotificationPreferences()),
    );
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
    // Default permission stub. Tests that should NEVER reach this path
    // verify with `verifyNever`.
    when(
      () => pushRegistration.requestOsNotificationPermission(),
    ).thenAnswer(
      (_) async => PushMessagingPermissionStatus.authorized,
    );
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

  testWidgets('empty alert: shows empty card and go-to-catalog CTA',
      (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.loadMine()).thenAnswer((_) async => const Success(null));
    when(() => auth.state)
        .thenReturn(const AuthState.authenticated(user));
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
      find.byKey(const ValueKey<String>('filter_alert_management_empty_card')),
      findsOneWidget,
    );
    expect(find.text(l10n.filterAlertManagementEmptyTitle), findsOneWidget);
    expect(find.text(l10n.filterAlertManagementEmptyBody), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('filter_alert_management_go_to_catalog'),
      ),
      findsOneWidget,
    );
    // No criteria summary card and no editor sheet on this screen.
    expect(
      find.byKey(
        const ValueKey<String>('filter_alert_management_summary_card'),
      ),
      findsNothing,
    );

    // Tapping the CTA navigates to the catalog.
    await tester.tap(
      find.byKey(
        const ValueKey<String>('filter_alert_management_go_to_catalog'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('catalog_landing_for_test'), findsOneWidget);
    expect(routeRecorder.calls, isNotEmpty);
    expect(routeRecorder.calls.first.location, AppRoutes.listings);
    expect(routeRecorder.calls.first.extra, isNull);
  });

  testWidgets('saved alert: shows summary rows and management actions',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    final settings = FilterAlertSettings(
      userId: 'u1',
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
      notificationsEnabled: false,
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 2),
    );
    when(() => repo.loadMine()).thenAnswer((_) async => Success(settings));
    when(() => auth.state)
        .thenReturn(const AuthState.authenticated(user));
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
      find.byKey(
        const ValueKey<String>('filter_alert_management_summary_card'),
      ),
      findsOneWidget,
    );
    expect(find.text('BMW'), findsOneWidget);
    expect(find.text('320'), findsOneWidget);
    expect(find.text('2018–2024'), findsOneWidget);
    expect(find.text('Тирасполь'), findsOneWidget);
    expect(find.text(l10n.regionTransnistria), findsOneWidget);
    expect(find.text(l10n.listingBodyTypeSedan), findsOneWidget);
    expect(find.text(l10n.filterMake), findsOneWidget);

    expect(
      find.byKey(const ValueKey<String>('filter_alert_management_edit_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('filter_alert_management_clear_action'),
      ),
      findsOneWidget,
    );
    // Delivery is off → no disable button.
    expect(
      find.byKey(
        const ValueKey<String>('filter_alert_management_disable_action'),
      ),
      findsNothing,
    );

    // Old editor surface is gone.
    expect(find.text(l10n.filterAlertSaveFilterAction), findsNothing);
  });

  testWidgets('push disabled: toggle is inactive and shows localized notice',
      (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    final settings = FilterAlertSettings(
      userId: 'u1',
      criteria: const ListingDiscoveryCriteria(make: 'Audi'),
      notificationsEnabled: false,
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 2),
    );
    when(() => repo.loadMine()).thenAnswer((_) async => Success(settings));
    when(() => auth.state)
        .thenReturn(const AuthState.authenticated(user));
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
      find.text(l10n.filterAlertNotificationsToggleTitle),
      findsOneWidget,
    );
    expect(
      find.text(l10n.filterAlertNotificationsPushDisabled),
      findsOneWidget,
    );
    final tileFinder = find.ancestor(
      of: find.text(l10n.filterAlertNotificationsToggleTitle),
      matching: find.byType(SwitchListTile),
    );
    expect(tileFinder, findsOneWidget);
    expect(tester.widget<SwitchListTile>(tileFinder).onChanged, isNull);
    // FirebaseMessaging / OS permission never reached.
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

  testWidgets(
    'edit action: navigates to catalog seeded with saved criteria '
    'and openFilterSheetOnEntry=true',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      const user = AuthUser(id: 'u1', email: 'a@b.com');
      final settings = FilterAlertSettings(
        userId: 'u1',
        criteria: const ListingDiscoveryCriteria(
          make: 'Toyota',
          marketRegion: MarketRegion.transnistria,
        ),
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 2),
      );
      when(() => repo.loadMine()).thenAnswer((_) async => Success(settings));
      when(() => auth.state)
          .thenReturn(const AuthState.authenticated(user));
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

      await tester.tap(
        find.byKey(
          const ValueKey<String>('filter_alert_management_edit_action'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('catalog_landing_for_test'), findsOneWidget);
      expect(routeRecorder.calls, isNotEmpty);
      final extra = routeRecorder.calls.last.extra;
      expect(extra, isA<ListingsFeedLaunch>());
      final launch = extra! as ListingsFeedLaunch;
      expect(launch.snapshot.make, 'Toyota');
      expect(launch.openFilterSheetOnEntry, isTrue);
    },
  );

  testWidgets('clear action: confirm dialog → clearPersistedCriteria',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    var loadCount = 0;
    final audi = FilterAlertSettings(
      userId: 'u1',
      criteria: const ListingDiscoveryCriteria(make: 'Audi'),
      notificationsEnabled: false,
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 2),
    );
    final cleared = FilterAlertSettings(
      userId: 'u1',
      criteria: null,
      notificationsEnabled: false,
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 3),
    );
    when(() => repo.loadMine()).thenAnswer((_) async {
      loadCount++;
      return Success(loadCount == 1 ? audi : cleared);
    });
    when(() => repo.clearPersistedCriteria())
        .thenAnswer((_) async => Success(cleared));
    when(() => auth.state)
        .thenReturn(const AuthState.authenticated(user));
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
      find.byKey(
        const ValueKey<String>('filter_alert_management_clear_action'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.filterAlertManagementClearConfirmTitle), findsOneWidget);
    expect(find.text(l10n.filterAlertManagementClearConfirmBody), findsOneWidget);

    // Cancel first to verify no-op semantics.
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    verifyNever(() => repo.clearPersistedCriteria());

    // Tap clear, confirm.
    await tester.tap(
      find.byKey(
        const ValueKey<String>('filter_alert_management_clear_action'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('filter_alert_management_clear_confirm_cta'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => repo.clearPersistedCriteria()).called(1);
    verifyNever(
      () => repo.saveCriteria(
        any(),
        notificationsEnabled: any(named: 'notificationsEnabled'),
      ),
    );
    expect(find.text(l10n.filterAlertManagementClearedSnack), findsOneWidget);
    expect(find.text('Audi'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('filter_alert_management_empty_card')),
      findsOneWidget,
    );
  });

  testWidgets(
    'disable action: keeps criteria but disables delivery',
    (tester) async {
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
      final delivered = FilterAlertSettings(
        userId: 'u1',
        criteria: const ListingDiscoveryCriteria(make: 'BMW'),
        notificationsEnabled: true,
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 2),
      );
      final disabledRow = FilterAlertSettings(
        userId: 'u1',
        criteria: const ListingDiscoveryCriteria(make: 'BMW'),
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 3),
      );
      when(() => notificationsRepo.getMyPreferences()).thenAnswer(
        (_) async => Success(
          NotificationPreferences(
            userId: 'u1',
            globalEnabled: true,
            messagesEnabled: false,
            filterAlertsEnabled: true,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
        ),
      );
      when(() => repo.loadMine()).thenAnswer((_) async => Success(delivered));
      when(() => repo.setNotificationsEnabled(false))
          .thenAnswer((_) async => Success(disabledRow));
      when(() => auth.state)
          .thenReturn(const AuthState.authenticated(user));
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

      // Delivery on → disable button is visible.
      expect(
        find.byKey(
          const ValueKey<String>('filter_alert_management_disable_action'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('filter_alert_management_disable_action'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repo.setNotificationsEnabled(false)).called(1);
      verifyNever(() => repo.clearPersistedCriteria());
      verifyNever(
        () => repo.saveCriteria(
          any(),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
      expect(
        find.text(l10n.filterAlertManagementDeliveryDisabledSnack),
        findsOneWidget,
      );
      // Criteria summary still rendered (BMW still saved).
      expect(find.text('BMW'), findsOneWidget);
    },
  );

  testWidgets('load failure: localized message + retry recalls repository',
      (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    var loadCount = 0;
    when(() => repo.loadMine()).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 1) {
        return const FailureResult(NetworkFailure('offline_probe'));
      }
      return const Success(null);
    });
    when(() => auth.state)
        .thenReturn(const AuthState.authenticated(user));
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

    expect(find.text(l10n.filterAlertLoadFailed), findsOneWidget);
    expect(find.text('offline_probe'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(
      find.byKey(const ValueKey<String>('filter_alert_management_empty_card')),
      findsOneWidget,
    );
  });

  testWidgets('load failure: hides PostgREST-style technical payloads',
      (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.loadMine()).thenAnswer(
      (_) async => const FailureResult(
        ServerFailure(
          'PGRST116 {"hint":null,"message":"filter_alert_settings row missing","code":"PGRST"}',
        ),
      ),
    );
    when(() => auth.state)
        .thenReturn(const AuthState.authenticated(user));
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

    expect(find.text(l10n.filterAlertLoadFailed), findsOneWidget);
    expect(find.textContaining('PGRST'), findsNothing);
    expect(find.textContaining('filter_alert'), findsNothing);
  });

  testWidgets('unauthenticated: sign-in CTA + repository never called',
      (tester) async {
    when(() => auth.state)
        .thenReturn(const AuthState.unauthenticated());
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

    expect(find.text(l10n.filterAlertSignInRequired), findsOneWidget);
    expect(find.widgetWithText(FilledButton, l10n.commonSignIn), findsOneWidget);
    verifyNever(() => repo.loadMine());
  });
}
