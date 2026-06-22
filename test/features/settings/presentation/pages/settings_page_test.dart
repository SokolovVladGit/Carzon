import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/l10n/app_locale_cubit.dart';
import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/theme/theme_mode_cubit.dart';
import 'package:carzon/core/theme/theme_mode_local_datasource.dart';
import 'package:carzon/core/theme/theme_mode_preference.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/domain/usecases/get_or_create_support_conversation.dart';
import 'package:carzon/features/settings/presentation/pages/settings_page.dart';
import 'package:carzon/features/settings/presentation/widgets/settings_about_section.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

const _settingsTestChangePasswordStubKey = ValueKey<String>(
  'settings_test_change_password_stub',
);

const _settingsTestNotificationSettingsStubKey = ValueKey<String>(
  'settings_test_notification_settings_stub',
);

const _settingsTestFuelPricesStubKey = ValueKey<String>(
  'settings_test_fuel_prices_stub',
);

const _settingsTestLegalStubKey = ValueKey<String>('settings_test_legal_stub');

const _settingsTestFilterAlertStubKey = ValueKey<String>(
  'settings_test_filter_alert_stub',
);

const _settingsTestProfileStubKey = ValueKey<String>(
  'settings_test_profile_stub',
);

const _settingsTestSupportThreadStubKey = ValueKey<String>(
  'settings_test_support_thread_stub',
);

const _settingsTestBlockedUsersStubKey = ValueKey<String>(
  'settings_test_blocked_users_stub',
);

const _settingsTestDeleteAccountStubKey = ValueKey<String>(
  'settings_test_delete_account_stub',
);

const _settingsTestMenuStubKey = ValueKey<String>('settings_test_menu_stub');

const MethodChannel _packageInfoChannel = MethodChannel(
  'dev.fluttercommunity.plus/package_info',
);

final class _InMemoryThemeModeLocalDataSource
    implements ThemeModeLocalDataSource {
  ThemeModePreference _preference = ThemeModePreference.light;

  @override
  Future<ThemeModePreference> loadPreference() async => _preference;

  @override
  Future<void> savePreference(ThemeModePreference preference) async {
    _preference = preference;
  }
}

final class _InMemoryAppLocaleLocalDataSource
    implements AppLocaleLocalDataSource {
  AppLocalePreference _preference = AppLocalePreference.ru;

  @override
  Future<AppLocalePreference> loadPreference() async => _preference;

  @override
  Future<void> savePreference(AppLocalePreference preference) async {
    _preference = preference;
  }
}

GoRouter _settingsTestRouter({
  required AuthCubit authCubit,
  required ThemeModeCubit themeModeCubit,
  required AppLocaleCubit appLocaleCubit,
}) {
  return GoRouter(
    initialLocation: AppRoutes.settings,
    routes: [
      GoRoute(
        path: AppRoutes.menu,
        builder: (_, _) => const Scaffold(key: _settingsTestMenuStubKey),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<ThemeModeCubit>.value(value: themeModeCubit),
            BlocProvider<AppLocaleCubit>.value(value: appLocaleCubit),
          ],
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, _) => const Scaffold(
          key: _settingsTestChangePasswordStubKey,
          body: Text('change_password_stub'),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (_, _) => const Scaffold(
          key: _settingsTestNotificationSettingsStubKey,
          body: Text('notification_settings_stub'),
        ),
      ),
      GoRoute(
        path: AppRoutes.filterAlert,
        builder: (_, _) => const Scaffold(
          key: _settingsTestFilterAlertStubKey,
          body: Text('filter_alert_stub'),
        ),
      ),
      GoRoute(
        path: AppRoutes.fuelPrices,
        builder: (_, _) => const Scaffold(
          key: _settingsTestFuelPricesStubKey,
          body: Text('fuel_prices_stub'),
        ),
      ),
      GoRoute(
        path: AppRoutes.legal,
        builder: (_, _) => const Scaffold(
          key: _settingsTestLegalStubKey,
          body: Text('legal_stub'),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const Scaffold(
          key: _settingsTestProfileStubKey,
          body: Text('profile_stub'),
        ),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (_, state) => Scaffold(
          key: _settingsTestSupportThreadStubKey,
          body: Text('thread:${state.pathParameters['conversationId']}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        builder: (_, _) => const Scaffold(
          key: _settingsTestBlockedUsersStubKey,
          body: Text('blocked_users_stub'),
        ),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (_, _) => const Scaffold(
          key: _settingsTestDeleteAccountStubKey,
          body: Text('delete_account_stub'),
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, _) => const Scaffold(body: Text('sign_in_stub')),
      ),
    ],
  );
}

Widget _settingsTestApp({
  required AuthCubit authCubit,
  required ThemeModeCubit themeModeCubit,
  required AppLocaleCubit appLocaleCubit,
  Locale locale = const Locale('ru'),
}) {
  return MaterialApp.router(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: _settingsTestRouter(
      authCubit: authCubit,
      themeModeCubit: themeModeCubit,
      appLocaleCubit: appLocaleCubit,
    ),
  );
}

Future<void> _scrollToSettingsRow(WidgetTester tester, Key rowKey) async {
  await tester.scrollUntilVisible(
    find.byKey(rowKey),
    80,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockAuthCubit authCubit;
  late ThemeModeCubit themeModeCubit;
  late AppLocaleCubit appLocaleCubit;
  late _MockMessagingRepository messagingRepo;
  final l10n = ruStrings();

  const testUser = AuthUser(
    id: 'user-1',
    email: 'seller@example.com',
    fullName: 'Test Seller',
  );

  setUpAll(() {
    registerFallbackValue('');
    TestWidgetsFlutterBinding.ensureInitialized();
    _packageInfoChannel.setMockMethodCallHandler((call) async {
      if (call.method == 'getAll') {
        return {
          'appName': 'Carzon',
          'packageName': 'com.carzon.app',
          'version': '0.1.0',
          'buildNumber': '1',
          'buildSignature': '',
          'installerStore': '',
        };
      }
      return null;
    });
  });

  tearDownAll(() {
    _packageInfoChannel.setMockMethodCallHandler(null);
  });

  setUp(() {
    authCubit = _MockAuthCubit();
    themeModeCubit = ThemeModeCubit(
      localDataSource: _InMemoryThemeModeLocalDataSource(),
    );
    appLocaleCubit = AppLocaleCubit(
      localDataSource: _InMemoryAppLocaleLocalDataSource(),
    );
    messagingRepo = _MockMessagingRepository();

    when(() => authCubit.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: testUser),
    );
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => authCubit.signOut()).thenAnswer((_) async {});

    if (sl.isRegistered<GetOrCreateSupportConversation>()) {
      sl.unregister<GetOrCreateSupportConversation>();
    }
    sl.registerLazySingleton<GetOrCreateSupportConversation>(
      () => GetOrCreateSupportConversation(messagingRepo),
    );
  });

  tearDown(() async {
    await themeModeCubit.close();
    await appLocaleCubit.close();
    if (sl.isRegistered<GetOrCreateSupportConversation>()) {
      sl.unregister<GetOrCreateSupportConversation>();
    }
  });

  testWidgets('Settings page renders main sections when authenticated', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsTitle), findsOneWidget);
    expect(find.text(l10n.settingsIntro), findsNothing);
    expect(find.text(l10n.settingsSectionAccount), findsOneWidget);
    expect(find.text(l10n.settingsSectionPreferences), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('settings_notifications_row')),
      findsOneWidget,
    );
    expect(find.text(l10n.settingsSectionPrivacySafety), findsOneWidget);
    expect(find.text(l10n.settingsSectionSupportLegal), findsOneWidget);
    expect(find.text(l10n.settingsSectionAbout), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('settings_account_profile_row')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('formatSettingsVersionLabel uses localized template', () {
    expect(
      formatSettingsVersionLabel(l10n, version: '0.1.0', build: '1'),
      l10n.settingsAboutVersion('0.1.0', '1'),
    );
  });

  testWidgets('Settings displays About version after package info loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_about_version_label'),
    );

    expect(find.text(l10n.settingsAboutAppName), findsOneWidget);
    expect(find.text(l10n.settingsAboutVersion('0.1.0', '1')), findsOneWidget);
  });

  testWidgets('Settings sign out row calls AuthCubit.signOut', (tester) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_sign_out_row'),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings_sign_out_row')),
    );
    await tester.pumpAndSettle();

    verify(() => authCubit.signOut()).called(1);
  });

  testWidgets('Settings navigates to profile from account section', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('settings_account_profile_row')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_settingsTestProfileStubKey), findsOneWidget);
  });

  testWidgets('Settings shows blocked users row when authenticated', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_blocked_users_row'),
    );

    expect(find.text(l10n.messagingSafetyBlockedUsersTitle), findsOneWidget);
    expect(find.text(l10n.settingsBlockedUsersSubtitle), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('settings_blocked_users_row')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_settingsTestBlockedUsersStubKey), findsOneWidget);
  });

  testWidgets('Settings omits duplicate privacy legal row', (tester) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('settings_privacy_legal_row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('settings_legal_row')),
      findsOneWidget,
    );
  });

  testWidgets('Settings renders on narrow width without overflow', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(320, 800);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(binding.window.clearPhysicalSizeTestValue);
    addTearDown(binding.window.clearDevicePixelRatioTestValue);

    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings renders in RO locale without exceptions', (
    tester,
  ) async {
    final roL10n = roStrings();

    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
        locale: const Locale('ro'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(roL10n.settingsTitle), findsOneWidget);
    expect(find.text(roL10n.settingsSectionAbout), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings navigates to change password', (tester) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_change_password_row'),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings_change_password_row')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_settingsTestChangePasswordStubKey), findsOneWidget);
  });

  testWidgets('Settings navigates to notification settings', (tester) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_notifications_row'),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings_notifications_row')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(_settingsTestNotificationSettingsStubKey),
      findsOneWidget,
    );
  });

  testWidgets('Settings navigates to filter alerts when authenticated', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_filter_alerts_row'),
    );
    expect(find.text(l10n.savedSearchesSettingsTitle), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('settings_filter_alerts_row')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_settingsTestFilterAlertStubKey), findsOneWidget);
  });

  testWidgets('Settings navigates to fuel prices from support section', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_fuel_prices_row'),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings_fuel_prices_row')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_settingsTestFuelPricesStubKey), findsOneWidget);
  });

  testWidgets('Settings navigates to legal from support section', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_legal_row'),
    );
    await tester.tap(find.byKey(const ValueKey<String>('settings_legal_row')));
    await tester.pumpAndSettle();
    expect(find.byKey(_settingsTestLegalStubKey), findsOneWidget);
  });

  testWidgets('Settings opens support conversation when authenticated', (
    tester,
  ) async {
    when(
      () => messagingRepo.getOrCreateSupportConversation(),
    ).thenAnswer((_) async => const Success('support-conv-1'));

    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_support_row'),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings_support_row')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_settingsTestSupportThreadStubKey), findsOneWidget);
    expect(find.text('thread:support-conv-1'), findsOneWidget);
  });

  testWidgets('Settings dark theme switch toggles theme mode', (tester) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(themeModeCubit.state.themeMode, ThemeMode.light);

    await tester.tap(
      find.byKey(const ValueKey<String>('settings_dark_theme_switch')),
    );
    await tester.pumpAndSettle();

    expect(themeModeCubit.state.themeMode, ThemeMode.dark);
  });

  testWidgets('Settings language sheet switches locale to RO', (tester) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_language_row')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_language_option_ro')));
    await tester.pumpAndSettle();

    expect(appLocaleCubit.state.preference, AppLocalePreference.ro);
  });

  testWidgets('Settings page renders in dark theme without exceptions', (
    tester,
  ) async {
    await themeModeCubit.setDarkEnabled(true);

    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings shows sign-in row when unauthenticated', (
    tester,
  ) async {
    when(
      () => authCubit.state,
    ).thenReturn(const AuthState(status: AuthStatus.unauthenticated));

    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('settings_sign_in_row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings_sign_out_row')),
      findsNothing,
    );
    expect(find.text(l10n.settingsSectionPrivacySafety), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('settings_change_password_row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('settings_filter_alerts_row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('settings_delete_account_row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('settings_legal_row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings_support_row')),
      findsNothing,
    );
  });

  testWidgets('Settings legal row subtitle mentions safety tips', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_legal_row'),
    );
    expect(find.text(l10n.settingsLegalLinkSubtitle), findsOneWidget);
    expect(find.textContaining('безопасности'), findsOneWidget);
  });

  testWidgets('Settings shows delete account row when authenticated', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('settings_delete_account_row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings_request_data_row')),
      findsOneWidget,
    );
  });

  testWidgets('Settings navigates to delete account page', (tester) async {
    await tester.pumpWidget(
      _settingsTestApp(
        authCubit: authCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: appLocaleCubit,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToSettingsRow(
      tester,
      const ValueKey<String>('settings_delete_account_row'),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings_delete_account_row')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_settingsTestDeleteAccountStubKey), findsOneWidget);
  });
}
