import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/widgets/floating_capsule_nav.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/menu/presentation/pages/menu_page.dart';
import 'package:carzon/features/profile/presentation/pages/profile_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockSellersRepository extends Mock implements SellersRepository {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

class _MemoryCompareRepository implements CompareRepository {
  List<CompareItem> items = const [];

  @override
  Future<void> clear() async => items = const [];

  @override
  Future<List<CompareItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<CompareItem> value) async => items = value;
}

MySellerProfileModel _menuSellerProfile({
  String? displayName,
  String? avatarUrl,
}) => MySellerProfileModel(
  displayName: displayName,
  avatarUrl: avatarUrl,
  avatarPath: null,
  memberSince: DateTime.utc(2026, 4, 1),
  publicVisibility: true,
);

Widget _wrap(
  Widget child,
  AuthCubit cubit, {
  required SellersRepository sellersRepo,
  required MessagingRepository messagingRepo,
  required CompareCubit compareCubit,
}) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: cubit),
        BlocProvider<CompareCubit>.value(value: compareCubit),
        BlocProvider(
          create: (_) => SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
        ),
        BlocProvider(create: (_) => MessagingUnreadSummaryCubit(messagingRepo)),
      ],
      child: child,
    ),
  );
}

void main() {
  late _MockAuthCubit cubit;
  late _MockSellersRepository sellersRepo;
  late _MockMessagingRepository messagingRepo;
  late CompareCubit compareCubit;
  final l10n = ruStrings();

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    cubit = _MockAuthCubit();
    sellersRepo = _MockSellersRepository();
    messagingRepo = _MockMessagingRepository();
    when(
      () => sellersRepo.getSellerPublicProfile(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => sellersRepo.getMySellerProfile(),
    ).thenAnswer((_) async => Success(_menuSellerProfile(displayName: 'S')));
    when(
      () => messagingRepo.getUnreadConversationCount(),
    ).thenAnswer((_) async => const Success(0));
    compareCubit = CompareCubit(repository: _MemoryCompareRepository());
  });

  tearDown(() => compareCubit.close());

  testWidgets(
    'unauthenticated: renders Sign in CTA and does not surface sign-out',
    (tester) async {
      when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(
        _wrap(
          const MenuPage(),
          cubit,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
          compareCubit: compareCubit,
        ),
      );

      expect(find.text(l10n.commonSignIn), findsOneWidget);
      expect(find.text(l10n.profileSignOut), findsNothing);
      // The menu destinations are always visible so users can browse
      // legal/content surfaces even when logged out.
      expect(find.text(l10n.profileMyListings), findsOneWidget);
      expect(find.text(l10n.menuAccount), findsOneWidget);
      expect(find.text(l10n.menuSettings), findsOneWidget);
      expect(find.text(l10n.profileLegal), findsOneWidget);
    },
  );

  testWidgets('authenticated: renders identity header and sign-out action', (
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
      _wrap(
        const MenuPage(),
        cubit,
        sellersRepo: sellersRepo,
        messagingRepo: messagingRepo,
        compareCubit: compareCubit,
      ),
    );

    expect(find.text('Ana Popescu'), findsOneWidget);
    expect(find.text('seller@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu_sign_out_action')), findsOneWidget);
    expect(find.text(l10n.profileSignOut), findsOneWidget);
    expect(find.text(l10n.commonSignIn), findsNothing);
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
      _wrap(
        const MenuPage(),
        cubit,
        sellersRepo: sellersRepo,
        messagingRepo: messagingRepo,
        compareCubit: compareCubit,
      ),
    );
    final signOutFinder = find.byKey(const ValueKey('menu_sign_out_action'));
    await tester.ensureVisible(signOutFinder);
    await tester.pumpAndSettle();
    await tester.tap(signOutFinder);
    await tester.pump();

    verify(() => cubit.signOut()).called(1);
  });

  testWidgets(
    'Account row pushes /profile; profile scaffold has no capsule nav',
    (tester) async {
      when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.unauthenticated(),
      );

      late final GoRouter router;
      router = GoRouter(
        initialLocation: AppRoutes.menu,
        routes: [
          GoRoute(
            path: AppRoutes.menu,
            builder: (_, _) => MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: cubit),
                BlocProvider(
                  create: (_) =>
                      SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
                ),
                BlocProvider(
                  create: (_) => MessagingUnreadSummaryCubit(messagingRepo),
                ),
              ],
              child: const MenuPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => BlocProvider<AuthCubit>.value(
              value: cubit,
              child: const ProfilePage(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<CompareCubit>.value(
          value: compareCubit,
          child: MaterialApp.router(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.canPop(), isFalse);
      expect(find.byType(FloatingCapsuleNav), findsOneWidget);

      await tester.tap(find.text(l10n.menuAccount));
      await tester.pumpAndSettle();

      expect(router.canPop(), isTrue);
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ProfilePage),
          matching: find.byType(FloatingCapsuleNav),
        ),
        findsNothing,
      );

      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10n.profileSignInRequired));
      expect(find.text(l10n.profileSignInRequired), findsOneWidget);
    },
  );

  testWidgets('Settings row pushes /settings', (tester) async {
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    const settingsStubKey = ValueKey<String>('menu_test_settings_stub');

    late final GoRouter router;
    router = GoRouter(
      initialLocation: AppRoutes.menu,
      routes: [
        GoRoute(
          path: AppRoutes.menu,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: cubit),
              BlocProvider(
                create: (_) =>
                    SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
              ),
              BlocProvider(
                create: (_) => MessagingUnreadSummaryCubit(messagingRepo),
              ),
            ],
            child: const MenuPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const Scaffold(
            key: settingsStubKey,
            body: Text('menu_settings_stub'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<CompareCubit>.value(
        value: compareCubit,
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('menu_settings_row')),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey<String>('menu_settings_row')));
    await tester.pumpAndSettle();

    expect(find.byKey(settingsStubKey), findsOneWidget);
  });

  testWidgets('Fuel prices row pushes /fuel-prices', (tester) async {
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    const fuelPricesStubKey = ValueKey<String>('menu_test_fuel_prices_stub');

    late final GoRouter router;
    router = GoRouter(
      initialLocation: AppRoutes.menu,
      routes: [
        GoRoute(
          path: AppRoutes.menu,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: cubit),
              BlocProvider(
                create: (_) =>
                    SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
              ),
              BlocProvider(
                create: (_) => MessagingUnreadSummaryCubit(messagingRepo),
              ),
            ],
            child: const MenuPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.fuelPrices,
          builder: (_, _) => const Scaffold(
            key: fuelPricesStubKey,
            body: Text('menu_fuel_prices_stub'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<CompareCubit>.value(
        value: compareCubit,
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('menu_fuel_prices_row')),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('menu_fuel_prices_row')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(fuelPricesStubKey), findsOneWidget);
  });

  testWidgets('identity avatar prefers seller_profiles URL when present', (
    tester,
  ) async {
    const sellerAvatar = 'https://seller.example/menu.png';
    when(() => sellersRepo.getMySellerProfile()).thenAnswer(
      (_) async => Success(
        _menuSellerProfile(displayName: 'Shop X', avatarUrl: sellerAvatar),
      ),
    );

    const user = AuthUser(
      id: 'u1',
      email: 'e@example.com',
      avatarUrl: 'https://auth.example/a.png',
    );
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(
      _wrap(
        const MenuPage(),
        cubit,
        sellersRepo: sellersRepo,
        messagingRepo: messagingRepo,
        compareCubit: compareCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is NetworkImage &&
            (w.image as NetworkImage).url == sellerAvatar,
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'identity avatar falls back to auth avatar when seller lacks URL',
    (tester) async {
      const authAvatar = 'https://auth.example/only-me.png';
      when(() => sellersRepo.getMySellerProfile()).thenAnswer(
        (_) async => Success(_menuSellerProfile(displayName: 'Bare')),
      );

      const user = AuthUser(
        id: 'u1',
        email: 'e@example.com',
        avatarUrl: authAvatar,
      );
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(
        _wrap(
          const MenuPage(),
          cubit,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
          compareCubit: compareCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is NetworkImage &&
              (w.image as NetworkImage).url == authAvatar,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('menu compare row uses go and back falls back to menu', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.menu,
      routes: [
        GoRoute(
          path: AppRoutes.menu,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: cubit),
              BlocProvider<CompareCubit>.value(value: compareCubit),
              BlocProvider(
                create: (_) =>
                    SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
              ),
              BlocProvider(
                create: (_) => MessagingUnreadSummaryCubit(messagingRepo),
              ),
            ],
            child: const MenuPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallback: AppRoutes.menu),
            ),
            body: const Text('compare-screen'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.menuCompare));
    await tester.pumpAndSettle();

    expect(find.text('compare-screen'), findsOneWidget);
    expect(router.canPop(), isFalse);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byType(MenuPage), findsOneWidget);
    expect(find.text('compare-screen'), findsNothing);
  });
}
