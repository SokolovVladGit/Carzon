import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/pages/listings_page.dart';
import 'package:carzon/features/recent_searches/domain/entities/recent_search_entry.dart';
import 'package:carzon/features/recent_searches/domain/repositories/recent_searches_repository.dart';
import 'package:carzon/features/recent_searches/presentation/cubit/recent_searches_cubit.dart';
import 'package:carzon/features/recent_searches/presentation/pages/recent_searches_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MemoryRecentSearchesRepository implements RecentSearchesRepository {
  List<RecentSearchEntry> stored = const [];

  @override
  Future<void> clear() async {
    stored = const [];
  }

  @override
  Future<List<RecentSearchEntry>> load() async =>
      List<RecentSearchEntry>.from(stored);

  @override
  Future<List<RecentSearchEntry>> record(RecentSearchEntry entry) async {
    stored = [entry, ...stored];
    return List<RecentSearchEntry>.from(stored);
  }

  @override
  Future<List<RecentSearchEntry>> remove(RecentSearchEntry entry) async {
    stored = stored
        .where((e) => e.criteria.search != entry.criteria.search)
        .toList(growable: false);
    return List<RecentSearchEntry>.from(stored);
  }
}

void main() {
  final l10n = ruStrings();
  late _MemoryRecentSearchesRepository repository;
  late RecentSearchesCubit cubit;
  ListingsFeedLaunch? capturedLaunch;

  setUp(() {
    repository = _MemoryRecentSearchesRepository();
    cubit = RecentSearchesCubit(repository: repository);
    capturedLaunch = null;
  });

  tearDown(() => cubit.close());

  Widget app({required GoRouter router}) {
    return BlocProvider<RecentSearchesCubit>.value(
      value: cubit,
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('empty state before any searches', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentSearches,
          builder: (_, _) => const RecentSearchesPage(),
        ),
      ],
      initialLocation: AppRoutes.recentSearches,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    expect(find.text(l10n.recentSearchesEmptyTitle), findsOneWidget);
    expect(find.text(l10n.recentSearchesBrowseListings), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recent_searches_clear_button')),
      findsNothing,
    );
  });

  testWidgets('populated state shows stored entries', (tester) async {
    await repository.record(
      RecentSearchEntry(
        criteria: const ListingDiscoveryCriteria(
          search: 'golf',
          make: 'Volkswagen',
        ),
        searchedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await repository.record(
      RecentSearchEntry(
        criteria: const ListingDiscoveryCriteria(search: 'bmw'),
        searchedAt: DateTime.utc(2026, 6, 2),
      ),
    );
    await cubit.loadFromStorage();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentSearches,
          builder: (_, _) => const RecentSearchesPage(),
        ),
      ],
      initialLocation: AppRoutes.recentSearches,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.recentSearchesSearchOnlyLabel('golf')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('recent_searches_clear_button')),
      findsOneWidget,
    );
  });

  testWidgets('tap row navigates with ListingsFeedLaunch criteria', (
    tester,
  ) async {
    final criteria = const ListingDiscoveryCriteria(
      search: 'octavia',
      make: 'Skoda',
      marketRegion: MarketRegion.moldova,
    );
    await repository.record(
      RecentSearchEntry(
        criteria: criteria,
        searchedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await cubit.loadFromStorage();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentSearches,
          builder: (_, _) => const RecentSearchesPage(),
        ),
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, state) {
            final extra = state.extra;
            if (extra is ListingsFeedLaunch) {
              capturedLaunch = extra;
            }
            return const Scaffold(body: Text('feed'));
          },
        ),
      ],
      initialLocation: AppRoutes.recentSearches,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.recentSearchesSearchOnlyLabel('octavia')));
    await tester.pumpAndSettle();

    expect(find.text('feed'), findsOneWidget);
    expect(capturedLaunch, isNotNull);
    expect(capturedLaunch!.snapshot.search, 'octavia');
    expect(capturedLaunch!.snapshot.make, 'Skoda');
  });

  testWidgets('delete one removes row', (tester) async {
    await repository.record(
      RecentSearchEntry(
        criteria: const ListingDiscoveryCriteria(search: 'alpha'),
        searchedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await repository.record(
      RecentSearchEntry(
        criteria: const ListingDiscoveryCriteria(search: 'beta'),
        searchedAt: DateTime.utc(2026, 6, 2),
      ),
    );
    await cubit.loadFromStorage();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentSearches,
          builder: (_, _) => const RecentSearchesPage(),
        ),
      ],
      initialLocation: AppRoutes.recentSearches,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recent_search_delete_0')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.recentSearchesSearchOnlyLabel('beta')), findsNothing);
    expect(
      find.text(l10n.recentSearchesSearchOnlyLabel('alpha')),
      findsOneWidget,
    );
  });

  testWidgets('clear all dialog clears list', (tester) async {
    await repository.record(
      RecentSearchEntry(
        criteria: const ListingDiscoveryCriteria(search: 'solo'),
        searchedAt: DateTime.utc(2026, 6, 1),
      ),
    );
    await cubit.loadFromStorage();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentSearches,
          builder: (_, _) => const RecentSearchesPage(),
        ),
      ],
      initialLocation: AppRoutes.recentSearches,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('recent_searches_clear_button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('recent_searches_clear_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.recentSearchesEmptyTitle), findsOneWidget);
    expect(cubit.state.entries, isEmpty);
  });
}
