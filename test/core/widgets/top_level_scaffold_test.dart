import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/widgets/floating_capsule_nav.dart';
import 'package:carzon/core/widgets/top_level_scaffold.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:carzon/shared/ui/carzon_icons.dart';

import '../../helpers/l10n_test_helpers.dart';

Widget _routerHost({required String initialLocation}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.listings,
        builder: (_, _) => const TopLevelScaffold(
          destination: TopLevelDestination.listings,
          body: Center(child: Text('body-listings')),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, _) => const TopLevelScaffold(
          destination: TopLevelDestination.search,
          body: Center(child: Text('body-search')),
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (_, _) => const TopLevelScaffold(
          destination: TopLevelDestination.favorites,
          body: Center(child: Text('body-favorites')),
        ),
      ),
      GoRoute(
        path: AppRoutes.createListing,
        builder: (_, _) => const TopLevelScaffold(
          destination: TopLevelDestination.createListing,
          body: Center(child: Text('body-create')),
        ),
      ),
      GoRoute(
        path: AppRoutes.menu,
        builder: (_, _) => const TopLevelScaffold(
          destination: TopLevelDestination.menu,
          body: Center(child: Text('body-menu')),
        ),
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
  final l10n = ruStrings();

  group('TopLevelScaffold floating capsule nav', () {
    testWidgets(
      'exposes all five Russian-localized destinations on the capsule',
      (tester) async {
        await tester.pumpWidget(
          _routerHost(initialLocation: AppRoutes.listings),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingCapsuleNav), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        for (final label in [
          l10n.navHome,
          l10n.navListings,
          l10n.navFavorites,
          l10n.navSell,
          l10n.navMenu,
        ]) {
          expect(
            find.text(label),
            findsNothing,
            reason: 'Nav is icon-only — no visible labels',
          );
          expect(
            find.bySemanticsLabel(label),
            findsWidgets,
            reason: 'Nav must still expose semantics for "$label"',
          );
        }

        expect(find.bySemanticsLabel(l10n.navMyListings), findsNothing);
        expect(find.bySemanticsLabel(l10n.navProfile), findsNothing);
        expect(find.byKey(kCapsuleNavCreateAssetKey), findsOneWidget);
        expect(find.byIcon(CarzonIcons.navCreateOutline), findsNothing);
        expect(find.byIcon(CarzonIcons.navHome), findsOneWidget);
        expect(find.byIcon(LucideIcons.home), findsNothing);
      },
    );

    test('Home uses Cupertino house_fill instead of thin Lucide home', () {
      expect(CarzonIcons.navHome, CupertinoIcons.house_fill);
      expect(CarzonIcons.navHome, isNot(LucideIcons.home));
    });

    test(
      'CarzonIcons.navMenu avoids slidersHorizontal used by catalog filters',
      () {
        expect(CarzonIcons.filter, LucideIcons.slidersHorizontal);
        expect(CarzonIcons.navMenu, isNot(LucideIcons.slidersHorizontal));
        expect(CarzonIcons.navMenu, isNot(CarzonIcons.filter));
      },
    );

    test('production destination order and indices', () {
      expect(TopLevelDestination.values.length, 5);
      expect(TopLevelDestination.values, [
        TopLevelDestination.listings,
        TopLevelDestination.search,
        TopLevelDestination.createListing,
        TopLevelDestination.favorites,
        TopLevelDestination.menu,
      ]);
      expect(TopLevelDestination.listings.index, 0);
      expect(TopLevelDestination.search.index, 1);
      expect(TopLevelDestination.createListing.index, 2);
      expect(TopLevelDestination.favorites.index, 3);
      expect(TopLevelDestination.menu.index, 4);
    });

    testWidgets('selectedIndex reflects the current top-level route', (
      tester,
    ) async {
      for (final (initial, expectedIndex) in const [
        (AppRoutes.listings, 0),
        (AppRoutes.search, 1),
        (AppRoutes.createListing, 2),
        (AppRoutes.favorites, 3),
        (AppRoutes.menu, 4),
      ]) {
        await tester.pumpWidget(_routerHost(initialLocation: initial));
        await tester.pumpAndSettle();

        final nav = tester.widget<FloatingCapsuleNav>(
          find.byType(FloatingCapsuleNav),
        );
        expect(
          nav.selectedIndex,
          expectedIndex,
          reason: 'selectedIndex for $initial should be $expectedIndex',
        );
      }
    });

    testWidgets('tapping a tab navigates to the destination route', (
      tester,
    ) async {
      await tester.pumpWidget(_routerHost(initialLocation: AppRoutes.listings));
      await tester.pumpAndSettle();
      expect(find.text('body-listings'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.navListings));
      await tester.pumpAndSettle();
      expect(find.text('body-search'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.navFavorites));
      await tester.pumpAndSettle();
      expect(find.text('body-favorites'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.navMenu));
      await tester.pumpAndSettle();
      expect(find.text('body-menu'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.navSell));
      await tester.pumpAndSettle();
      expect(find.text('body-create'), findsOneWidget);
    });

    testWidgets('tapping the already-selected tab does not re-navigate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routerHost(initialLocation: AppRoutes.favorites),
      );
      await tester.pumpAndSettle();
      expect(find.text('body-favorites'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.navFavorites));
      await tester.pumpAndSettle();

      expect(find.text('body-favorites'), findsOneWidget);
    });
  });
}
