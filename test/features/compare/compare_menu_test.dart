import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/pages/compare_page.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/menu/presentation/pages/menu_page.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_state.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
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
  List<CompareItem> items = const [];

  @override
  Future<void> clear() async => items = const [];

  @override
  Future<List<CompareItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<CompareItem> value) async => items = value;
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
  late _MemoryCompareRepository compareRepo;

  setUp(() {
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    messagingCubit = _MockMessagingUnreadCubit();
    sellerVisualCubit = _MockSelfSellerVisualCubit();
    compareRepo = _MemoryCompareRepository();
    compareCubit = CompareCubit(repository: compareRepo);

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

  tearDown(() => compareCubit.close());

  Widget menuApp() {
    final router = GoRouter(
      initialLocation: AppRoutes.menu,
      routes: [
        GoRoute(path: AppRoutes.menu, builder: (_, _) => const MenuPage()),
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => const ComparePage(),
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
        BlocProvider<CompareCubit>.value(value: compareCubit),
        BlocProvider<MessagingUnreadSummaryCubit>.value(value: messagingCubit),
        BlocProvider<SelfSellerVisualCubit>.value(value: sellerVisualCubit),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('menu compare row hides badge when compare set is empty', (
    tester,
  ) async {
    await tester.pumpWidget(menuApp());
    await tester.pumpAndSettle();

    expect(find.text(ru.menuCompare), findsOneWidget);
    expect(
      find.byKey(const ValueKey('menu_count_badge_circle_0')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('menu_count_badge_pill_0')), findsNothing);

    final compareRow = find.ancestor(
      of: find.text(ru.menuCompare),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: compareRow, matching: find.text('0')),
      findsNothing,
    );
  });

  testWidgets('menu compare row shows circle badge for count 1', (
    tester,
  ) async {
    await compareCubit.addSnapshot(
      CompareListingSnapshot(
        listingId: 'm1',
        addedAt: DateTime.utc(2026, 5, 22),
        make: 'VW',
        priceCurrency: ListingCurrency.eur,
      ),
    );

    await tester.pumpWidget(menuApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('menu_count_badge_circle_1')),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('menu shows Сравнение row with count badge', (tester) async {
    await compareCubit.addSnapshot(
      CompareListingSnapshot(
        listingId: 'm1',
        addedAt: DateTime.utc(2026, 5, 22),
        make: 'VW',
        priceCurrency: ListingCurrency.eur,
      ),
    );
    await compareCubit.addSnapshot(
      CompareListingSnapshot(
        listingId: 'm2',
        addedAt: DateTime.utc(2026, 5, 22),
        make: 'Ford',
        priceCurrency: ListingCurrency.eur,
      ),
    );

    await tester.pumpWidget(menuApp());
    await tester.pumpAndSettle();

    expect(find.text(ru.menuCompare), findsOneWidget);
    expect(
      find.byKey(const ValueKey('menu_count_badge_circle_2')),
      findsOneWidget,
    );
  });

  testWidgets('tapping menu compare row navigates to compare page', (
    tester,
  ) async {
    await tester.pumpWidget(menuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(ru.menuCompare));
    await tester.pumpAndSettle();

    expect(find.text(ru.compareTitle), findsOneWidget);
    expect(find.text(ru.compareVehiclesTitle), findsOneWidget);
  });
}
