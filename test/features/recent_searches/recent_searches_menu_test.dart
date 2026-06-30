import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/menu/presentation/pages/menu_page.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_state.dart';
import 'package:carzon/features/recent_searches/domain/entities/recent_search_entry.dart';
import 'package:carzon/features/recent_searches/domain/repositories/recent_searches_repository.dart';
import 'package:carzon/features/recent_searches/presentation/cubit/recent_searches_cubit.dart';
import 'package:carzon/features/recent_searches/presentation/pages/recent_searches_page.dart';
import 'package:carzon/features/recently_viewed/domain/entities/recently_viewed_entry.dart';
import 'package:carzon/features/recently_viewed/domain/repositories/recently_viewed_repository.dart';
import 'package:carzon/features/recently_viewed/presentation/cubit/recently_viewed_cubit.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockMessagingUnreadCubit extends MockCubit<MessagingUnreadSummaryState>
    implements MessagingUnreadSummaryCubit {}

class _MockSelfSellerVisualCubit extends MockCubit<SelfSellerVisualState>
    implements SelfSellerVisualCubit {}

class _MemoryCompareRepository implements CompareRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<CompareItem>> loadItems() async => const [];

  @override
  Future<void> saveItems(List<CompareItem> items) async {}
}

class _MemoryRecentlyViewedRepository implements RecentlyViewedRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<RecentlyViewedEntry>> load() async => const [];

  @override
  Future<List<RecentlyViewedEntry>> record(RecentlyViewedEntry entry) async => [
    entry,
  ];
}

class _MemoryRecentSearchesRepository implements RecentSearchesRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<RecentSearchEntry>> load() async => const [];

  @override
  Future<List<RecentSearchEntry>> record(RecentSearchEntry entry) async => [
    entry,
  ];

  @override
  Future<List<RecentSearchEntry>> remove(RecentSearchEntry entry) async =>
      const [];
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthState.unauthenticated());
  });

  final ru = ruStrings();
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late _MockMessagingUnreadCubit messagingCubit;
  late _MockSelfSellerVisualCubit sellerVisualCubit;
  late CompareCubit compareCubit;
  late RecentlyViewedCubit recentlyViewedCubit;
  late RecentSearchesCubit recentSearchesCubit;

  setUp(() {
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    messagingCubit = _MockMessagingUnreadCubit();
    sellerVisualCubit = _MockSelfSellerVisualCubit();
    compareCubit = CompareCubit(repository: _MemoryCompareRepository());
    recentlyViewedCubit = RecentlyViewedCubit(
      repository: _MemoryRecentlyViewedRepository(),
    );
    recentSearchesCubit = RecentSearchesCubit(
      repository: _MemoryRecentSearchesRepository(),
    );

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
    when(() => messagingCubit.state).thenReturn(
      const MessagingUnreadSummaryState(
        phase: MessagingUnreadSummaryPhase.initial,
      ),
    );
    whenListen(
      messagingCubit,
      const Stream<MessagingUnreadSummaryState>.empty(),
      initialState: const MessagingUnreadSummaryState(
        phase: MessagingUnreadSummaryPhase.initial,
      ),
    );
    when(
      () => sellerVisualCubit.state,
    ).thenReturn(const SelfSellerVisualState());
    whenListen(
      sellerVisualCubit,
      const Stream<SelfSellerVisualState>.empty(),
      initialState: const SelfSellerVisualState(),
    );
    when(() => sellerVisualCubit.prime(any())).thenAnswer((_) async {});
    when(() => messagingCubit.sync(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await compareCubit.close();
    await recentlyViewedCubit.close();
    await recentSearchesCubit.close();
  });

  testWidgets('guest menu shows recent searches row and navigates', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.menu,
      routes: [
        GoRoute(path: AppRoutes.menu, builder: (_, _) => const MenuPage()),
        GoRoute(
          path: AppRoutes.recentSearches,
          builder: (_, _) => const RecentSearchesPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
          BlocProvider<CompareCubit>.value(value: compareCubit),
          BlocProvider<RecentlyViewedCubit>.value(value: recentlyViewedCubit),
          BlocProvider<RecentSearchesCubit>.value(value: recentSearchesCubit),
          BlocProvider<MessagingUnreadSummaryCubit>.value(
            value: messagingCubit,
          ),
          BlocProvider<SelfSellerVisualCubit>.value(value: sellerVisualCubit),
        ],
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ru.menuRecentSearches), findsOneWidget);
    await tester.tap(find.text(ru.menuRecentSearches));
    await tester.pumpAndSettle();

    expect(find.text(ru.recentSearchesTitle), findsOneWidget);
  });
}
