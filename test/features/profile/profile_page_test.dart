import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/l10n/app_locale_cubit.dart';
import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/theme/theme_mode_cubit.dart';
import 'package:carzon/core/theme/theme_mode_local_datasource.dart';
import 'package:carzon/core/theme/theme_mode_preference.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/core/widgets/floating_capsule_nav.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/domain/usecases/get_or_create_support_conversation.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/profile/presentation/pages/profile_page.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/seller_display_name_constraints.dart';
import 'package:carzon/features/sellers/domain/usecases/clear_seller_avatar.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/domain/usecases/update_my_seller_display_name.dart';
import 'package:carzon/features/sellers/domain/usecases/upload_seller_avatar.dart';
import 'package:carzon/features/sellers/presentation/bloc/public_seller_identity_cubit.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/ui/carzon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockSellersRepository extends Mock implements SellersRepository {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

const _menuStubKey = ValueKey<String>('profile_test_menu_route_stub');

const _profileTestMessagesStubKey = ValueKey<String>(
  'profile_test_messages_stub',
);

const _profileTestNotificationSettingsStubKey = ValueKey<String>(
  'profile_test_notification_settings_stub',
);

const _profileTestChangePasswordStubKey = ValueKey<String>(
  'profile_test_change_password_stub',
);

const _profileTestSettingsStubKey = ValueKey<String>(
  'profile_test_settings_stub',
);

const _profileTestSupportThreadStubKey = ValueKey<String>(
  'profile_test_support_thread_stub',
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

GoRouter _profileTestGoRouter({
  required AuthCubit cubit,
  required MessagingUnreadSummaryCubit messagingUnread,
  required ThemeModeCubit themeModeCubit,
  required AppLocaleCubit appLocaleCubit,
}) {
  return GoRouter(
    initialLocation: AppRoutes.profile,
    routes: [
      GoRoute(
        path: AppRoutes.menu,
        builder: (context, _) => BlocProvider<AuthCubit>.value(
          value: cubit,
          child: Scaffold(key: _menuStubKey, body: const SizedBox.expand()),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, _) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: cubit),
            BlocProvider<MessagingUnreadSummaryCubit>.value(
              value: messagingUnread,
            ),
            BlocProvider<ThemeModeCubit>.value(value: themeModeCubit),
            BlocProvider<AppLocaleCubit>.value(value: appLocaleCubit),
          ],
          child: const ProfilePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (_, _) => const Scaffold(
          key: _profileTestMessagesStubKey,
          body: Text('profile_test_messages_placeholder'),
        ),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, _) => const Scaffold(
          key: _profileTestChangePasswordStubKey,
          body: Text('profile_test_change_password_placeholder'),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (_, _) => const Scaffold(
          key: _profileTestNotificationSettingsStubKey,
          body: Text('profile_test_notification_settings_placeholder'),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const Scaffold(
          key: _profileTestSettingsStubKey,
          body: Text('profile_test_settings_placeholder'),
        ),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (_, state) => Scaffold(
          key: _profileTestSupportThreadStubKey,
          body: Text('thread:${state.pathParameters['conversationId']}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.listings,
        builder: (context, _) => BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const Scaffold(body: Text('feed')), // coverage for listeners
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, _) => BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const Scaffold(body: Text('sign-in')),
        ),
      ),
    ],
  );
}

Widget _profileTestMaterial(GoRouter router) {
  return MaterialApp.router(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

/// [ProfilePage] uses `GoRouterExtension` APIs; tests must host it under GoRouter.
Widget _profileTestApp({
  required AuthCubit cubit,
  required MessagingUnreadSummaryCubit messagingUnread,
  ThemeModeCubit? themeModeCubit,
  AppLocaleCubit? appLocaleCubit,
}) {
  final resolvedThemeModeCubit =
      themeModeCubit ??
      ThemeModeCubit(localDataSource: _InMemoryThemeModeLocalDataSource());
  final resolvedAppLocaleCubit =
      appLocaleCubit ??
      AppLocaleCubit(localDataSource: _InMemoryAppLocaleLocalDataSource());
  return _profileTestMaterial(
    _profileTestGoRouter(
      cubit: cubit,
      messagingUnread: messagingUnread,
      themeModeCubit: resolvedThemeModeCubit,
      appLocaleCubit: resolvedAppLocaleCubit,
    ),
  );
}

MySellerProfileModel _myProfile({
  String? displayName,
  String? avatarUrl,
  String? avatarPath,
}) => MySellerProfileModel(
  displayName: displayName,
  avatarUrl: avatarUrl,
  avatarPath: avatarPath,
  memberSince: DateTime.utc(2026, 4, 1),
  publicVisibility: true,
);

void main() {
  late _MockAuthCubit cubit;
  late _MockSellersRepository sellersRepo;
  late _MockMessagingRepository messagingRepo;
  late MessagingUnreadSummaryCubit unreadSummaryCubit;
  final l10n = ruStrings();

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() async {
    cubit = _MockAuthCubit();
    sellersRepo = _MockSellersRepository();
    messagingRepo = _MockMessagingRepository();
    await sl.reset();

    when(
      () => sellersRepo.getSellerPublicProfile(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => sellersRepo.getMySellerProfile(),
    ).thenAnswer((_) async => Success(_myProfile(displayName: 'Saved Shop')));
    when(() => sellersRepo.updateMySellerDisplayName(any())).thenAnswer(
      (inv) async => Success(
        _myProfile(displayName: inv.positionalArguments[0] as String?),
      ),
    );
    when(
      () => sellersRepo.uploadSellerAvatar(
        bytes: any(named: 'bytes'),
        contentType: any(named: 'contentType'),
        previousAvatarStoragePath: any(named: 'previousAvatarStoragePath'),
      ),
    ).thenAnswer((_) async => Success(_myProfile(displayName: 'Saved Shop')));
    when(
      () => sellersRepo.clearSellerAvatar(
        previousAvatarStoragePath: any(named: 'previousAvatarStoragePath'),
      ),
    ).thenAnswer((_) async => Success(_myProfile(displayName: 'Saved Shop')));

    when(
      () => messagingRepo.getUnreadConversationCount(),
    ).thenAnswer((_) async => const Success(0));
    unreadSummaryCubit = MessagingUnreadSummaryCubit(messagingRepo);
    sl.registerLazySingleton<SellersRepository>(() => sellersRepo);
    sl.registerFactory(() => GetMySellerProfile(sl<SellersRepository>()));
    sl.registerFactory(
      () => UpdateMySellerDisplayName(sl<SellersRepository>()),
    );
    sl.registerFactory(() => UploadSellerAvatar(sl<SellersRepository>()));
    sl.registerFactory(() => ClearSellerAvatar(sl<SellersRepository>()));
    sl.registerFactory(
      () => PublicSellerIdentityCubit(
        getMySellerProfile: sl<GetMySellerProfile>(),
        updateMySellerDisplayName: sl<UpdateMySellerDisplayName>(),
        uploadSellerAvatar: sl<UploadSellerAvatar>(),
        clearSellerAvatar: sl<ClearSellerAvatar>(),
      ),
    );
    sl.registerLazySingleton<MessagingRepository>(() => messagingRepo);
    sl.registerFactory(
      () => GetOrCreateSupportConversation(sl<MessagingRepository>()),
    );
  });

  tearDown(() async {
    await unreadSummaryCubit.close();
    await sl.reset();
  });

  testWidgets('unauthenticated: sign-in prompt, back button, no capsule nav', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileSignInRequired), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.commonSignIn),
      findsOneWidget,
    );
    expect(find.text(l10n.profileSignOut), findsNothing);
    expect(find.text(l10n.profileMyListings), findsNothing);

    expect(find.byType(AppBackButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProfilePage),
        matching: find.byType(FloatingCapsuleNav),
      ),
      findsNothing,
    );
  });

  testWidgets('AppBackButton goes to menu when profile is sole stack entry', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(_menuStubKey), findsOneWidget);
  });

  testWidgets(
    'authenticated: seller identity editing, sign-out; no shortcuts',
    (tester) async {
      const user = AuthUser(
        id: 'u1',
        email: 'seller@example.com',
        fullName: 'Ana Popescu',
      );
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Popescu'), findsOneWidget);
      expect(find.text('seller@example.com'), findsOneWidget);
      expect(
        find.text(l10n.profilePublicSellerBuyerPreviewCaption),
        findsOneWidget,
      );
      expect(
        find.text(l10n.profilePublicSellerProfileSectionTitle),
        findsOneWidget,
      );
      expect(
        find.text(l10n.profilePublicSellerProfileSectionSubtitle),
        findsOneWidget,
      );
      expect(find.text(l10n.profileSettingsSectionTitle), findsOneWidget);
      expect(find.text(l10n.profileOpenSettingsTitle), findsOneWidget);
      expect(find.text(l10n.profileOpenSettingsSubtitle), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('profile_open_settings_row')),
        findsOneWidget,
      );
      expect(find.text(l10n.profileLanguageTitle), findsNothing);
      expect(find.text(l10n.profileNotificationsTitle), findsNothing);
      expect(find.text(l10n.profileChangePasswordTitle), findsNothing);
      expect(find.text(l10n.profileListingAlertsTitle), findsNothing);
      expect(find.text(l10n.profileDarkThemeTitle), findsNothing);
      expect(find.text(l10n.profileDarkThemeSubtitle), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('settings_dark_theme_switch')),
        findsNothing,
      );
      expect(find.text(l10n.filterAlertProfileRowSubtitle), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('settings_change_password_row')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('profile_filter_alert_row')),
        findsNothing,
      );

      expect(find.text(l10n.commonComingSoon), findsNothing);
      expect(find.text(l10n.contactSupport), findsNothing);

      expect(find.text('Saved Shop'), findsWidgets);
      expect(
        find.text(l10n.profilePublicSellerAvatarChangePhoto),
        findsOneWidget,
      );

      expect(find.byType(AppBackButton), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ProfilePage),
          matching: find.byType(FloatingCapsuleNav),
        ),
        findsNothing,
      );

      expect(find.text(l10n.profileMyListings), findsNothing);
      expect(find.text(l10n.profileFavorites), findsNothing);
      expect(find.text(l10n.profileCreateListing), findsNothing);
      expect(find.text(l10n.profileLegal), findsNothing);

      expect(
        find.byKey(const ValueKey('profileSignOutButton')),
        findsOneWidget,
      );
      expect(find.text(l10n.profileSignOut), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('profileSignOutButton')),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('authenticated: open settings row navigates to /settings', (
    tester,
  ) async {
    const user = AuthUser(
      id: 'u1',
      email: 'seller@example.com',
      fullName: 'Ana Popescu',
    );
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(
      const ValueKey<String>('profile_open_settings_row'),
    );
    await tester.scrollUntilVisible(
      row,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byKey(_profileTestSettingsStubKey), findsOneWidget);
  });

  testWidgets(
    'authenticated: open settings row is a single navigation target (chevron)',
    (tester) async {
      const user = AuthUser(
        id: 'u1',
        email: 'seller@example.com',
        fullName: 'Ana Popescu',
      );
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      final row = find.byKey(
        const ValueKey<String>('profile_open_settings_row'),
      );
      await tester.scrollUntilVisible(
        row,
        80,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(CarzonIcons.chevronRight),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byType(Switch)),
        findsNothing,
      );
    },
  );

  testWidgets('authenticated without full name: falls back to showing email', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    expect(find.text('seller@example.com'), findsOneWidget);
  });

  testWidgets('save posts trimmed display name', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com', fullName: 'T');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  New Name  ');
    final savePosts = find.widgetWithText(
      FilledButton,
      l10n.profilePublicSellerNameSave,
    );
    await tester.scrollUntilVisible(
      savePosts,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(savePosts);
    await tester.pumpAndSettle();

    verify(() => sellersRepo.updateMySellerDisplayName('New Name')).called(1);
    expect(find.text(l10n.profilePublicSellerNameSaved), findsOneWidget);
  });

  testWidgets(
    'text field enforces max length (cannot exceed backend limit via UI)',
    (tester) async {
      const user = AuthUser(id: 'u1', email: 'a@b.com');
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      final maxPlusOne = List.filled(
        SellerDisplayNameConstraints.maxLength + 1,
        'z',
      ).join();
      await tester.enterText(find.byType(TextField), maxPlusOne);
      final saveMax = find.widgetWithText(
        FilledButton,
        l10n.profilePublicSellerNameSave,
      );
      await tester.scrollUntilVisible(
        saveMax,
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(saveMax);
      await tester.pumpAndSettle();

      final atMostMax = List.filled(
        SellerDisplayNameConstraints.maxLength,
        'z',
      ).join();
      verify(() => sellersRepo.updateMySellerDisplayName(atMostMax)).called(1);
      expect(find.text(l10n.profilePublicSellerNameSaved), findsOneWidget);
    },
  );

  testWidgets('validation blocks email-shaped name', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'buyer@shop.md');
    final saveVal = find.widgetWithText(
      FilledButton,
      l10n.profilePublicSellerNameSave,
    );
    await tester.scrollUntilVisible(
      saveVal,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveVal);
    await tester.pumpAndSettle();

    verifyNever(() => sellersRepo.updateMySellerDisplayName(any()));
    expect(
      find.text(l10n.profilePublicSellerNameLooksLikeEmail),
      findsOneWidget,
    );
  });

  testWidgets('clearing field saves null display name', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '');
    final saveClear = find.widgetWithText(
      FilledButton,
      l10n.profilePublicSellerNameSave,
    );
    await tester.scrollUntilVisible(
      saveClear,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveClear);
    await tester.pumpAndSettle();

    verify(() => sellersRepo.updateMySellerDisplayName(null)).called(1);
  });

  testWidgets('Sign out button calls AuthCubit.signOut', (tester) async {
    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    when(() => cubit.signOut()).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('profileSignOutButton')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profileSignOutButton')));
    await tester.pump();

    verify(() => cubit.signOut()).called(1);
  });

  testWidgets('without avatar: remove photo control is absent', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(
      () => sellersRepo.getMySellerProfile(),
    ).thenAnswer((_) async => Success(_myProfile(displayName: 'N')));
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.profilePublicSellerAvatarRemovePhoto), findsNothing);
  });

  testWidgets('with avatar URL: remove photo control is visible', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => sellersRepo.getMySellerProfile()).thenAnswer(
      (_) async => Success(
        _myProfile(
          displayName: 'N',
          avatarUrl: 'https://example.com/a.jpg',
          avatarPath: 'avatars/u1/a.jpg',
        ),
      ),
    );
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.coverChangePhoto), findsOneWidget);
    expect(find.text(l10n.profilePublicSellerAvatarChangePhoto), findsNothing);
    expect(
      find.text(l10n.profilePublicSellerAvatarRemovePhoto),
      findsOneWidget,
    );
  });

  testWidgets(
    'authenticated: activity section surfaces Messages preview string',
    (tester) async {
      const user = AuthUser(id: 'u1', email: 'seller@example.com');
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.profileActivitySectionTitle), findsOneWidget);
      expect(find.text(l10n.profileMessagesNoUnreadStatus), findsOneWidget);
      expect(find.text(l10n.profileMessagesUnreadStatus), findsNothing);
      expect(
        find.byKey(const ValueKey('profile_messages_unread_count_badge')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'authenticated: Activity Messages row pushes route so stack returns to Account',
    (tester) async {
      final themeModeCubit = ThemeModeCubit(
        localDataSource: _InMemoryThemeModeLocalDataSource(),
      );
      addTearDown(themeModeCubit.close);
      final router = _profileTestGoRouter(
        cubit: cubit,
        messagingUnread: unreadSummaryCubit,
        themeModeCubit: themeModeCubit,
        appLocaleCubit: AppLocaleCubit(
          localDataSource: _InMemoryAppLocaleLocalDataSource(),
        ),
      );
      const user = AuthUser(id: 'u1', email: 'seller@example.com');
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(_profileTestMaterial(router));
      await tester.pumpAndSettle();

      expect(router.canPop(), isFalse);

      final messagesTitle = find.text(l10n.messagingTitle);
      await tester.scrollUntilVisible(
        messagesTitle.first,
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(messagesTitle.first);
      await tester.pumpAndSettle();

      expect(find.byKey(_profileTestMessagesStubKey), findsOneWidget);
      expect(router.canPop(), isTrue);

      router.pop();
      await tester.pumpAndSettle();

      expect(find.text(l10n.profileTitle), findsOneWidget);
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets(
    'authenticated: Activity Messages trailing shows unread count badge when unread > 0',
    (tester) async {
      await unreadSummaryCubit.close();
      when(
        () => messagingRepo.getUnreadConversationCount(),
      ).thenAnswer((_) async => const Success(2));
      unreadSummaryCubit = MessagingUnreadSummaryCubit(messagingRepo);

      const user = AuthUser(id: 'u1', email: 'seller@example.com');
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      final badge = find.byKey(
        const ValueKey('profile_messages_unread_count_badge'),
      );
      expect(badge, findsOneWidget);
      expect(find.text(l10n.profileMessagesUnreadStatus), findsOneWidget);
      expect(
        find.descendant(of: badge, matching: find.text('2')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'authenticated: Activity Messages badge shows 1 for single unread conversation',
    (tester) async {
      await unreadSummaryCubit.close();
      when(
        () => messagingRepo.getUnreadConversationCount(),
      ).thenAnswer((_) async => const Success(1));
      unreadSummaryCubit = MessagingUnreadSummaryCubit(messagingRepo);

      const user = AuthUser(id: 'u1', email: 'seller@example.com');
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      final badge = find.byKey(
        const ValueKey('profile_messages_unread_count_badge'),
      );
      expect(
        find.descendant(of: badge, matching: find.text('1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'authenticated: Activity Messages badge shows overflow label when count >= 100',
    (tester) async {
      await unreadSummaryCubit.close();
      when(
        () => messagingRepo.getUnreadConversationCount(),
      ).thenAnswer((_) async => const Success(100));
      unreadSummaryCubit = MessagingUnreadSummaryCubit(messagingRepo);

      const user = AuthUser(id: 'u1', email: 'seller@example.com');
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      final badge = find.byKey(
        const ValueKey('profile_messages_unread_count_badge'),
      );
      expect(
        find.descendant(
          of: badge,
          matching: find.text(l10n.profileMessagesUnreadCountOverflow),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'authenticated: Activity Messages omits no-unread subtitle when unread summary RPC fails with no prior count',
    (tester) async {
      await unreadSummaryCubit.close();
      when(() => messagingRepo.getUnreadConversationCount()).thenAnswer(
        (_) async => const FailureResult(NetworkFailure('temporary')),
      );
      unreadSummaryCubit = MessagingUnreadSummaryCubit(messagingRepo);

      const user = AuthUser(id: 'u1', email: 'seller@example.com');
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.profileMessagesNoUnreadStatus), findsNothing);
      expect(find.text(l10n.profileMessagesUnreadStatus), findsNothing);
      expect(
        find.byKey(const ValueKey('profile_messages_unread_count_badge')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'private header uses seller_profiles avatar ahead of AuthUser.photo',
    (tester) async {
      const sellerUrl = 'https://seller.example/from-profile.png';
      const user = AuthUser(
        id: 'u1',
        email: 'a@b.com',
        fullName: 'T',
        avatarUrl: 'https://auth.example/from-auth.jpg',
      );
      when(() => sellersRepo.getMySellerProfile()).thenAnswer(
        (_) async =>
            Success(_myProfile(displayName: 'Pub', avatarUrl: sellerUrl)),
      );
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _profileTestApp(cubit: cubit, messagingUnread: unreadSummaryCubit),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is NetworkImage &&
              (widget.image as NetworkImage).url == sellerUrl,
        ),
        findsWidgets,
      );
    },
  );
}
