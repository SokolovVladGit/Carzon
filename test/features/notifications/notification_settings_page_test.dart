import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/entities/push_token_platform.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:carzon/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:carzon/features/notifications/services/push_auth_gate.dart';
import 'package:carzon/features/notifications/services/push_messaging_client.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _FakePushMessagingClient implements PushMessagingClient {
  int permissionRequestCalls = 0;

  @override
  Future<bool> initializeFirebase() async => true;

  @override
  Future<PushMessagingPermissionStatus> getPermissionStatus() async =>
      PushMessagingPermissionStatus.authorized;

  @override
  Future<PushMessagingPermissionStatus> requestPermission() async {
    permissionRequestCalls++;
    return PushMessagingPermissionStatus.authorized;
  }

  @override
  Future<String?> getFcmToken() async => 'token';

  @override
  Stream<String> watchTokenRefresh() => const Stream.empty();

  @override
  Future<void> deleteFcmToken() async {}
}

class _FakeAuthGate implements PushAuthGate {
  const _FakeAuthGate();

  @override
  bool get hasAuthenticatedUser => true;
}

NotificationPreferences _prefs({
  bool global = false,
  bool messages = false,
  bool filterAlerts = false,
  bool priceDrops = false,
}) {
  return NotificationPreferences(
    userId: 'u1',
    globalEnabled: global,
    messagesEnabled: messages,
    filterAlertsEnabled: filterAlerts,
    priceDropsEnabled: priceDrops,
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: DateTime.utc(2024, 1, 2),
  );
}

void main() {
  late _MockAuthCubit authCubit;
  late _MockNotificationsRepository repo;
  late _FakePushMessagingClient pushClient;
  late NotificationSettingsCubit settingsCubit;
  final l10n = ruStrings();

  const user = AuthUser(id: 'u1', email: 'a@test.com');

  Widget buildApp({ThemeData? theme}) {
    final router = GoRouter(
      initialLocation: AppRoutes.notificationSettings,
      routes: [
        GoRoute(
          path: AppRoutes.notificationSettings,
          builder: (context, state) => notificationSettingsTestHarness(
            authCubit: authCubit,
            settingsCubit: settingsCubit,
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    return MaterialApp.router(
      theme: theme,
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  Future<void> pumpUntilContent(WidgetTester tester, {ThemeData? theme}) async {
    await settingsCubit.load();
    await tester.pumpWidget(buildApp(theme: theme));
    await tester.pump();

    final messagesKey = find.byKey(
      const ValueKey<String>('notification_settings_messages_card'),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(deadline)) {
      if (messagesKey.evaluate().isNotEmpty) {
        await tester.pump();
        return;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    fail('Notification settings content did not appear');
  }

  setUp(() {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    authCubit = _MockAuthCubit();
    repo = _MockNotificationsRepository();
    pushClient = _FakePushMessagingClient();

    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    registerFallbackValue(PushTokenPlatform.android);

    when(
      () => repo.getMyPreferences(),
    ).thenAnswer((_) async => Success(_prefs(global: true, messages: true)));
    when(
      () => repo.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        priceDropsEnabled: any(named: 'priceDropsEnabled'),
      ),
    ).thenAnswer((inv) async {
      return Success(
        _prefs(
          global: inv.namedArguments[#globalEnabled] as bool,
          messages: inv.namedArguments[#messagesEnabled] as bool,
          filterAlerts: inv.namedArguments[#filterAlertsEnabled] as bool,
          priceDrops: inv.namedArguments[#priceDropsEnabled] as bool,
        ),
      );
    });
    when(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => const Success<void>(null));
    when(
      () => repo.deactivateMyPushTokens(),
    ).thenAnswer((_) async => const Success<void>(null));

    final pushRegistration = PushNotificationRegistrationService(
      messagingClient: pushClient,
      notificationsRepository: repo,
      authGate: const _FakeAuthGate(),
      readAuthenticatedUserId: () => 'user-1',
      readLocalePreference: () => AppLocalePreference.ru,
    );

    settingsCubit = NotificationSettingsCubit(
      notificationsRepository: repo,
      pushRegistration: pushRegistration,
    );
  });

  tearDown(() async {
    await settingsCubit.close();
  });

  testWidgets('renders messages and price-drop notification cards', (
    tester,
  ) async {
    await pumpUntilContent(tester);

    expect(
      find.byKey(const ValueKey<String>('notification_settings_messages_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('notification_settings_price_drops_card'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('notification_settings_status_card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('notification_settings_master_card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('notification_settings_filter_card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('notification_settings_delivery_card')),
      findsNothing,
    );
    expect(find.text(l10n.notificationSettingsPageIntro), findsNothing);
    expect(find.text(l10n.notificationSettingsFilterAlertsTitle), findsNothing);
    expect(find.text(l10n.notificationSettingsComingSoonBadge), findsNothing);
    expect(find.text(l10n.notificationSettingsPriceDropsTitle), findsOneWidget);
    expect(
      find.text(l10n.notificationSettingsPriceDropsSubtitle),
      findsOneWidget,
    );
    expect(find.textContaining('PUSH_NOTIFICATIONS'), findsNothing);
    expect(
      find.text(l10n.notificationSettingsMessagesSubtitle),
      findsOneWidget,
    );
    expect(
      find.text(l10n.notificationSettingsSavedSearchAlertsNote),
      findsOneWidget,
    );
  });

  testWidgets('load does not request OS permission', (tester) async {
    pushClient.permissionRequestCalls = 0;
    await pumpUntilContent(tester);
    expect(pushClient.permissionRequestCalls, 0);
  });

  testWidgets('dark theme renders messages and price-drop cards', (
    tester,
  ) async {
    await pumpUntilContent(tester, theme: ThemeData.dark(useMaterial3: true));

    expect(
      find.byKey(const ValueKey<String>('notification_settings_messages_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('notification_settings_price_drops_card'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('toggling price-drop switch calls setPriceDropsEnabled', (
    tester,
  ) async {
    when(
      () => repo.getMyPreferences(),
    ).thenAnswer((_) async => Success(_prefs(global: true, priceDrops: false)));

    await pumpUntilContent(tester);

    final priceDropSwitch = find.descendant(
      of: find.byKey(
        const ValueKey<String>('notification_settings_price_drops_card'),
      ),
      matching: find.byType(Switch),
    );
    expect(priceDropSwitch, findsOneWidget);

    await tester.tap(priceDropSwitch);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => repo.updateMyPreferences(
        globalEnabled: true,
        messagesEnabled: false,
        filterAlertsEnabled: false,
        priceDropsEnabled: true,
      ),
    ).called(1);
  });

  testWidgets(
    'push enabled build keeps message and price-drop toggles active',
    (tester) async {
      await pumpUntilContent(tester);

      final messagesSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('notification_settings_messages_card'),
          ),
          matching: find.byType(Switch),
        ),
      );
      expect(messagesSwitch.onChanged, isNotNull);

      final priceDropsSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('notification_settings_price_drops_card'),
          ),
          matching: find.byType(Switch),
        ),
      );
      expect(priceDropsSwitch.onChanged, isNotNull);
    },
  );

  testWidgets('push-disabled build disables toggles without technical copy', (
    tester,
  ) async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
    );

    await pumpUntilContent(tester);

    expect(find.textContaining('PUSH_NOTIFICATIONS'), findsNothing);
    expect(
      find.text(l10n.notificationSettingsPushBuildDisabledBanner),
      findsNothing,
    );

    final messagesSwitch = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('notification_settings_messages_card'),
        ),
        matching: find.byType(Switch),
      ),
    );
    expect(messagesSwitch.onChanged, isNull);

    final priceDropsSwitch = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('notification_settings_price_drops_card'),
        ),
        matching: find.byType(Switch),
      ),
    );
    expect(priceDropsSwitch.onChanged, isNull);
  });

  testWidgets('renders on narrow width without overflow', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(320, 800);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(binding.window.clearPhysicalSizeTestValue);
    addTearDown(binding.window.clearDevicePixelRatioTestValue);

    await pumpUntilContent(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('notification_settings_messages_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('notification_settings_price_drops_card'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
