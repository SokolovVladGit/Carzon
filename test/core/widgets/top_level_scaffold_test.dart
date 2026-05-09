import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/widgets/floating_capsule_nav.dart';
import 'package:carzon/core/widgets/top_level_scaffold.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:carzon/shared/ui/carzon_icons.dart';

import '../../helpers/l10n_test_helpers.dart';

/// Builds a minimal `GoRouter`-backed test harness that registers the
/// four top-level routes (matching only by path), each pointing to a
/// [TopLevelScaffold] whose `body` identifies itself with a text
/// marker so navigation can be asserted.
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
      'exposes all four Russian-localized destinations on the capsule — '
      'as Semantics labels (icon-only bar), not as visible text',
      (tester) async {
        await tester.pumpWidget(
          _routerHost(initialLocation: AppRoutes.listings),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingCapsuleNav), findsOneWidget);
        // Material `NavigationBar` must no longer be used by the
        // top-level scaffold — the capsule is the single nav surface.
        expect(find.byType(NavigationBar), findsNothing);

        for (final label in [
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

        // My Listings and Profile are no longer direct top-level tabs;
        // they live under Menu.
        expect(find.bySemanticsLabel(l10n.navMyListings), findsNothing);
        expect(find.bySemanticsLabel(l10n.navProfile), findsNothing);
      },
    );

    test(
      'CarzonIcons.navMenu avoids slidersHorizontal used by catalog filters',
      () {
        expect(CarzonIcons.filter, LucideIcons.slidersHorizontal);
        expect(CarzonIcons.navMenu, isNot(LucideIcons.slidersHorizontal));
        expect(CarzonIcons.navMenu, isNot(CarzonIcons.filter));
      },
    );

    testWidgets('selectedIndex reflects the current top-level route', (
      tester,
    ) async {
      for (final (initial, expectedIndex) in const [
        (AppRoutes.listings, 0),
        (AppRoutes.favorites, 1),
        (AppRoutes.createListing, 2),
        (AppRoutes.menu, 3),
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

      await tester.tap(find.bySemanticsLabel(l10n.navFavorites));
      await tester.pumpAndSettle();
      expect(find.text('body-favorites'), findsOneWidget);
      expect(find.text('body-listings'), findsNothing);

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
