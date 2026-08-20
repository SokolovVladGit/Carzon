import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/app.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/l10n/app_locale_cubit.dart';
import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/theme/theme_mode_cubit.dart';
import 'package:carzon/core/theme/theme_mode_local_datasource.dart';
import 'package:carzon/core/theme/theme_mode_preference.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_state.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_feedback_controller.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_state.dart';
import 'package:carzon/features/notifications/services/message_foreground_notification_presenter.dart';
import 'package:carzon/features/notifications/services/message_push_tap_handler.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/carzon_app_widget_test_stubs.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockCompareCubit extends MockCubit<CompareState>
    implements CompareCubit {}

class _MockSelfSellerVisualCubit extends MockCubit<SelfSellerVisualState>
    implements SelfSellerVisualCubit {}

class _MockMessagingUnreadSummaryCubit
    extends MockCubit<MessagingUnreadSummaryState>
    implements MessagingUnreadSummaryCubit {}

class _MockBrowseCatalogFilterAlertsCubit
    extends MockCubit<BrowseCatalogFilterAlertsState>
    implements BrowseCatalogFilterAlertsCubit {}

class _MockPushNotificationRegistrationService extends Mock
    implements PushNotificationRegistrationService {}

class _MockMessagePushTapHandler extends Mock
    implements MessagePushTapHandler {}

class _MockMessageForegroundNotificationPresenter extends Mock
    implements MessageForegroundNotificationPresenter {}

final class _InMemoryThemeModeLocalDataSource
    implements ThemeModeLocalDataSource {
  _InMemoryThemeModeLocalDataSource(this.preference);

  final ThemeModePreference preference;

  @override
  Future<ThemeModePreference> loadPreference() async => preference;

  @override
  Future<void> savePreference(ThemeModePreference preference) async {}
}

final class _InMemoryAppLocaleLocalDataSource
    implements AppLocaleLocalDataSource {
  @override
  Future<AppLocalePreference> loadPreference() async => AppLocalePreference.ru;

  @override
  Future<void> savePreference(AppLocalePreference preference) async {}
}

void main() {
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late _MockCompareCubit compareCubit;
  late _MockSelfSellerVisualCubit selfSellerVisualCubit;
  late _MockMessagingUnreadSummaryCubit messagingUnreadSummaryCubit;
  late _MockBrowseCatalogFilterAlertsCubit browseFilterAlertsCubit;
  late _MockPushNotificationRegistrationService pushRegistration;
  late _MockMessagePushTapHandler pushTapHandler;
  late _MockMessageForegroundNotificationPresenter foregroundPresenter;
  late StreamController<AuthState> authStates;
  late List<AuthState> browseAuthSynchronizations;
  late bool pushTapStarted;
  late bool foregroundPresenterStarted;
  late bool foregroundDisplayReady;

  setUpAll(() {
    registerFallbackValue(const AuthState.unauthenticated());
    registerFallbackValue(const AuthUser(id: 'u1', email: 'test@example.com'));
  });

  setUp(() async {
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    compareCubit = _MockCompareCubit();
    selfSellerVisualCubit = _MockSelfSellerVisualCubit();
    messagingUnreadSummaryCubit = _MockMessagingUnreadSummaryCubit();
    browseFilterAlertsCubit = _MockBrowseCatalogFilterAlertsCubit();
    pushRegistration = _MockPushNotificationRegistrationService();
    pushTapHandler = _MockMessagePushTapHandler();
    foregroundPresenter = _MockMessageForegroundNotificationPresenter();
    authStates = StreamController<AuthState>();
    browseAuthSynchronizations = [];
    pushTapStarted = false;
    foregroundPresenterStarted = false;
    foregroundDisplayReady = false;
    await sl.reset();
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
    );

    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      authCubit,
      authStates.stream,
      initialState: const AuthState.unauthenticated(),
    );
    when(() => favoritesCubit.state).thenReturn(const FavoritesState());
    whenListen(
      favoritesCubit,
      const Stream<FavoritesState>.empty(),
      initialState: const FavoritesState(),
    );
    when(() => compareCubit.state).thenReturn(const CompareState());
    whenListen(
      compareCubit,
      const Stream<CompareState>.empty(),
      initialState: const CompareState(),
    );
    when(
      () => selfSellerVisualCubit.state,
    ).thenReturn(const SelfSellerVisualState());
    whenListen(
      selfSellerVisualCubit,
      const Stream<SelfSellerVisualState>.empty(),
      initialState: const SelfSellerVisualState(),
    );
    when(() => messagingUnreadSummaryCubit.state).thenReturn(
      const MessagingUnreadSummaryState(
        phase: MessagingUnreadSummaryPhase.initial,
      ),
    );
    whenListen(
      messagingUnreadSummaryCubit,
      const Stream<MessagingUnreadSummaryState>.empty(),
      initialState: const MessagingUnreadSummaryState(
        phase: MessagingUnreadSummaryPhase.initial,
      ),
    );
    when(
      () => favoritesCubit.syncWithAuth(any<AuthUser?>()),
    ).thenAnswer((_) async {});
    when(
      () => selfSellerVisualCubit.prime(any<AuthState>()),
    ).thenAnswer((_) async {});
    when(
      () => messagingUnreadSummaryCubit.sync(any<AuthState>()),
    ).thenAnswer((_) async {});
    when(
      () => browseFilterAlertsCubit.onAuthChanged(any<AuthState>()),
    ).thenAnswer((invocation) async {
      browseAuthSynchronizations.add(
        invocation.positionalArguments.first as AuthState,
      );
    });
    when(
      () => pushRegistration.syncTokenWithBackendIfEligible(),
    ).thenAnswer((_) async {});
    when(() => pushTapHandler.isStarted).thenAnswer((_) => pushTapStarted);
    when(() => pushTapHandler.start()).thenAnswer((_) async {
      pushTapStarted = true;
    });
    when(
      () => foregroundPresenter.isStarted,
    ).thenAnswer((_) => foregroundPresenterStarted);
    when(
      () => foregroundPresenter.isDisplayReady,
    ).thenAnswer((_) => foregroundDisplayReady);
    when(() => foregroundPresenter.start()).thenAnswer((_) async {
      foregroundPresenterStarted = true;
      foregroundDisplayReady = true;
    });

    sl.registerSingleton<AuthCubit>(authCubit);
    sl.registerSingleton<FavoritesCubit>(favoritesCubit);
    sl.registerSingleton<CompareCubit>(compareCubit);
    sl.registerSingleton<CompareFlyToTrayController>(
      CompareFlyToTrayController(),
    );
    sl.registerSingleton<CompareTrayFeedbackController>(
      CompareTrayFeedbackController(),
    );
    sl.registerSingleton<SelfSellerVisualCubit>(selfSellerVisualCubit);
    sl.registerSingleton<MessagingUnreadSummaryCubit>(
      messagingUnreadSummaryCubit,
    );
    sl.registerSingleton<BrowseCatalogFilterAlertsCubit>(
      browseFilterAlertsCubit,
    );
    sl.registerSingleton<PushNotificationRegistrationService>(pushRegistration);
    sl.registerSingleton<MessagePushTapHandler>(pushTapHandler);
    sl.registerSingleton<MessageForegroundNotificationPresenter>(
      foregroundPresenter,
    );
    registerCarzonAppLocalHistoryCubitStubs(sl);
    sl.registerLazySingleton<ThemeModeLocalDataSource>(
      () => _InMemoryThemeModeLocalDataSource(ThemeModePreference.light),
    );
    sl.registerLazySingleton<AppLocaleLocalDataSource>(
      () => _InMemoryAppLocaleLocalDataSource(),
    );
    sl.registerSingleton(
      ThemeModeCubit(localDataSource: sl<ThemeModeLocalDataSource>()),
    );
    sl.registerSingleton(
      AppLocaleCubit(localDataSource: sl<AppLocaleLocalDataSource>()),
    );
    sl.registerSingleton<GoRouter>(
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        ],
      ),
    );
  });

  tearDown(() async {
    await authStates.close();
    await sl.reset();
    dotenv.testLoad(fileInput: '');
  });

  testWidgets('applies dark theme mode from ThemeModeCubit', (tester) async {
    await sl<ThemeModeCubit>().setDarkEnabled(true);
    await sl<AppLocaleCubit>().load();

    await tester.pumpWidget(const CarzonApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('applies light theme mode from ThemeModeCubit', (tester) async {
    await sl<ThemeModeCubit>().setDarkEnabled(false);
    await sl<AppLocaleCubit>().load();

    await tester.pumpWidget(const CarzonApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });

  testWidgets(
    'auth transitions synchronize every global user-bound state owner',
    (tester) async {
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();
      await tester.pumpWidget(const CarzonApp());
      await tester.pump();

      const userA = AuthUser(id: 'user-a', email: 'a@example.com');
      const authenticatedA = AuthState.authenticated(userA);
      authStates.add(authenticatedA);
      await tester.pump();

      verify(() => favoritesCubit.syncWithAuth(userA)).called(1);
      verify(() => selfSellerVisualCubit.prime(authenticatedA)).called(1);
      verify(() => messagingUnreadSummaryCubit.sync(authenticatedA)).called(1);
      verify(
        () => browseFilterAlertsCubit.onAuthChanged(authenticatedA),
      ).called(1);
      expect(browseAuthSynchronizations, [authenticatedA]);

      authStates.add(authenticatedA);
      await tester.pump();
      expect(browseAuthSynchronizations, [authenticatedA]);

      const userB = AuthUser(id: 'user-b', email: 'b@example.com');
      const authenticatedB = AuthState.authenticated(userB);
      authStates.add(authenticatedB);
      await tester.pump();
      expect(browseAuthSynchronizations, [authenticatedA, authenticatedB]);

      const signedOut = AuthState.unauthenticated();
      authStates.add(signedOut);
      await tester.pump();

      verify(() => favoritesCubit.syncWithAuth(null)).called(1);
      verify(() => selfSellerVisualCubit.prime(signedOut)).called(1);
      verify(() => messagingUnreadSummaryCubit.sync(signedOut)).called(1);
      verify(() => browseFilterAlertsCubit.onAuthChanged(signedOut)).called(1);
      expect(browseAuthSynchronizations, [
        authenticatedA,
        authenticatedB,
        signedOut,
      ]);
    },
  );

  group('push initialization lifecycle', () {
    setUp(() {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
    });

    testWidgets('mounted app starts both push listener services once', (
      tester,
    ) async {
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();

      await tester.pumpWidget(const CarzonApp());
      await tester.pump();

      verify(() => pushTapHandler.start()).called(1);
      verify(() => foregroundPresenter.start()).called(1);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('resume retries only service whose initial start failed', (
      tester,
    ) async {
      var tapAttempts = 0;
      when(() => pushTapHandler.start()).thenAnswer((_) async {
        tapAttempts++;
        if (tapAttempts == 1) {
          throw StateError('temporary tap startup failure');
        }
        pushTapStarted = true;
      });
      when(
        () => pushRegistration.syncTokenWithBackendIfEligible(),
      ).thenThrow(StateError('temporary registration failure'));
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();

      await tester.pumpWidget(const CarzonApp());
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tapAttempts, 1);
      expect(foregroundPresenterStarted, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(tapAttempts, 2);
      verify(() => foregroundPresenter.start()).called(1);
      verify(() => pushRegistration.syncTokenWithBackendIfEligible()).called(1);
    });

    testWidgets('successful services are not restarted on resume', (
      tester,
    ) async {
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();
      await tester.pumpWidget(const CarzonApp());
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verify(() => pushTapHandler.start()).called(1);
      verify(() => foregroundPresenter.start()).called(1);
      verifyNever(() => messagingUnreadSummaryCubit.sync(any<AuthState>()));
    });

    testWidgets('resume retries unavailable display without restarting tap', (
      tester,
    ) async {
      foregroundPresenterStarted = true;
      foregroundDisplayReady = false;
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();
      await tester.pumpWidget(const CarzonApp());
      await tester.pump();

      verify(() => foregroundPresenter.start()).called(1);
      verify(() => pushTapHandler.start()).called(1);
      clearInteractions(foregroundPresenter);
      clearInteractions(pushTapHandler);

      foregroundDisplayReady = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verify(() => foregroundPresenter.start()).called(1);
      verifyNever(() => pushTapHandler.start());
    });

    testWidgets('rapid resumes share a pending listener startup', (
      tester,
    ) async {
      final startGate = Completer<void>();
      when(() => pushTapHandler.start()).thenAnswer((_) async {
        await startGate.future;
        pushTapStarted = true;
      });
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();
      await tester.pumpWidget(const CarzonApp());
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verify(() => pushTapHandler.start()).called(1);
      startGate.complete();
      await tester.pump();
      expect(pushTapStarted, isTrue);
    });

    testWidgets('push-disabled app never starts listener services', (
      tester,
    ) async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
      );
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();

      await tester.pumpWidget(const CarzonApp());
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verifyNever(() => pushTapHandler.start());
      verifyNever(() => foregroundPresenter.start());
      verifyNever(() => pushRegistration.syncTokenWithBackendIfEligible());
      verifyNever(() => messagingUnreadSummaryCubit.sync(any<AuthState>()));
    });
  });

  group('global unread polling lifecycle', () {
    const authenticated = AuthState.authenticated(
      AuthUser(id: 'poll-user', email: 'poll@example.com'),
    );

    Future<void> mountAuthenticated(WidgetTester tester) async {
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();
      await tester.pumpWidget(const CarzonApp());
      await tester.pump();
      authStates.add(authenticated);
      await tester.pump();
    }

    testWidgets('foreground polling runs every 15 seconds with push disabled', (
      tester,
    ) async {
      await mountAuthenticated(tester);
      clearInteractions(messagingUnreadSummaryCubit);

      await tester.pump(const Duration(seconds: 30));

      verify(() => messagingUnreadSummaryCubit.sync(authenticated)).called(2);
      verifyNever(() => foregroundPresenter.start());
      verifyNever(() => pushTapHandler.start());
    });

    testWidgets('polling stops while backgrounded and resumes immediately', (
      tester,
    ) async {
      await mountAuthenticated(tester);
      clearInteractions(messagingUnreadSummaryCubit);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      verifyNever(() => messagingUnreadSummaryCubit.sync(any<AuthState>()));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      verify(() => messagingUnreadSummaryCubit.sync(authenticated)).called(1);
    });

    testWidgets('sign-out cancels foreground polling', (tester) async {
      await mountAuthenticated(tester);
      authStates.add(const AuthState.unauthenticated());
      await tester.pump();
      clearInteractions(messagingUnreadSummaryCubit);

      await tester.pump(const Duration(seconds: 30));

      verifyNever(() => messagingUnreadSummaryCubit.sync(any<AuthState>()));
    });

    testWidgets('same-session polling does not overlap an active sync', (
      tester,
    ) async {
      final gate = Completer<void>();
      when(
        () => messagingUnreadSummaryCubit.sync(authenticated),
      ).thenAnswer((_) => gate.future);

      await mountAuthenticated(tester);
      await tester.pump(const Duration(seconds: 30));

      verify(() => messagingUnreadSummaryCubit.sync(authenticated)).called(1);
      gate.complete();
      await tester.pump();
    });

    testWidgets('account switch reaches generation-safe cubit immediately', (
      tester,
    ) async {
      final gate = Completer<void>();
      when(
        () => messagingUnreadSummaryCubit.sync(authenticated),
      ).thenAnswer((_) => gate.future);
      await mountAuthenticated(tester);

      const switched = AuthState.authenticated(
        AuthUser(id: 'other-user', email: 'other@example.com'),
      );
      authStates.add(switched);
      await tester.pump();

      verify(() => messagingUnreadSummaryCubit.sync(switched)).called(1);
      gate.complete();
      await tester.pump();
    });
  });
}
