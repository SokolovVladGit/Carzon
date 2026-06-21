import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/recently_viewed/domain/entities/recently_viewed_entry.dart';
import 'package:carzon/features/recently_viewed/domain/repositories/recently_viewed_repository.dart';
import 'package:carzon/features/recently_viewed/presentation/cubit/recently_viewed_cubit.dart';
import 'package:carzon/features/recently_viewed/presentation/cubit/recently_viewed_state.dart';
import 'package:carzon/features/recently_viewed/presentation/pages/recently_viewed_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MemoryRecentlyViewedRepository implements RecentlyViewedRepository {
  List<RecentlyViewedEntry> stored = const [];

  @override
  Future<void> clear() async {
    stored = const [];
  }

  @override
  Future<List<RecentlyViewedEntry>> load() async =>
      List<RecentlyViewedEntry>.from(stored);

  @override
  Future<List<RecentlyViewedEntry>> record(RecentlyViewedEntry entry) async {
    stored = [entry, ...stored.where((e) => e.listingId != entry.listingId)];
    return List<RecentlyViewedEntry>.from(stored);
  }
}

RecentlyViewedEntry _entry(String id) => RecentlyViewedEntry(
  listingId: id,
  viewedAt: DateTime.utc(2026, 6, 1),
  title: 'Skoda Octavia 1.8 TSI',
  make: 'Skoda',
  model: 'Octavia',
  year: 2017,
  priceEur: 10800,
  priceCurrency: ListingCurrency.eur,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  coverImageUrl: 'https://cdn.example/cover.jpg',
);

void main() {
  final l10n = ruStrings();
  late _MemoryRecentlyViewedRepository repository;
  late RecentlyViewedCubit cubit;

  setUp(() {
    repository = _MemoryRecentlyViewedRepository();
    cubit = RecentlyViewedCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  Widget app({required GoRouter router}) {
    return BlocProvider<RecentlyViewedCubit>.value(
      value: cubit,
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('empty state before any views', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentlyViewed,
          builder: (_, _) => const RecentlyViewedPage(),
        ),
      ],
      initialLocation: AppRoutes.recentlyViewed,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    expect(find.text(l10n.recentlyViewedEmptyTitle), findsOneWidget);
    expect(find.text(l10n.recentlyViewedBrowseListings), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recently_viewed_clear_button')),
      findsNothing,
    );
  });

  testWidgets('populated state shows stored entries', (tester) async {
    cubit.syncEntries([_entry('listing-a'), _entry('listing-b')]);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentlyViewed,
          builder: (_, _) => const RecentlyViewedPage(),
        ),
      ],
      initialLocation: AppRoutes.recentlyViewed,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Skoda Octavia 1.8 TSI'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('recently_viewed_row_listing-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('recently_viewed_clear_button')),
      findsOneWidget,
    );
  });

  testWidgets('clear all dialog clears list', (tester) async {
    cubit.syncEntries([_entry('listing-a')]);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentlyViewed,
          builder: (_, _) => const RecentlyViewedPage(),
        ),
      ],
      initialLocation: AppRoutes.recentlyViewed,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('recently_viewed_clear_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('recently_viewed_clear_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.isEmpty, isTrue);
    expect(find.text(l10n.recentlyViewedEmptyTitle), findsOneWidget);
  });

  testWidgets('tapping row navigates to listing details', (tester) async {
    cubit.syncEntries([_entry('listing-nav')]);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.recentlyViewed,
          builder: (_, _) => const RecentlyViewedPage(),
        ),
        GoRoute(
          path: AppRoutes.listingDetails,
          builder: (_, state) =>
              Scaffold(body: Text('details:${state.pathParameters['id']}')),
        ),
      ],
      initialLocation: AppRoutes.recentlyViewed,
    );

    await tester.pumpWidget(app(router: router));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('recently_viewed_row_listing-nav')),
    );
    await tester.pumpAndSettle();

    expect(find.text('details:listing-nav'), findsOneWidget);
  });

  test('RO smoke strings resolve', () {
    final ro = roStrings();
    expect(ro.recentlyViewedTitle, isNotEmpty);
    expect(ro.recentlyViewedEmptyTitle, isNotEmpty);
  });
}
