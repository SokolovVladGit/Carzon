import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../shared/ui/carzon_icons.dart';
import '../l10n/app_localizations_x.dart';
import 'floating_capsule_nav.dart';

/// Destinations rendered in the app's floating capsule bottom nav.
///
/// The MVP ships a deliberately compact 4-tab nav:
///
///   1. [listings] — the search/feed surface (left),
///   2. [favorites] — the user's saved cars,
///   3. [createListing] — the central "Sell" action,
///   4. [menu] — account & account-adjacent surfaces (My Listings,
///      Profile, Legal, Sign in/out), grouped behind a single Menu
///      destination so the bar stays breathable.
///
/// The enum is ordered left-to-right as it appears in the nav.
enum TopLevelDestination { listings, favorites, createListing, menu }

/// Maps a destination to the canonical route path it represents in the
/// router. Kept alongside the enum so the mapping cannot drift from
/// the nav's visual order.
extension TopLevelDestinationRoute on TopLevelDestination {
  String get route {
    switch (this) {
      case TopLevelDestination.listings:
        return AppRoutes.listings;
      case TopLevelDestination.favorites:
        return AppRoutes.favorites;
      case TopLevelDestination.createListing:
        return AppRoutes.createListing;
      case TopLevelDestination.menu:
        return AppRoutes.menu;
    }
  }
}

/// Shared scaffold used by the top-level app sections (plus the
/// sub-surfaces grouped under the Menu tab) so they all render the
/// same premium floating-capsule bottom nav.
///
/// Rationale for a shared scaffold rather than a go_router `ShellRoute`:
/// the app's existing top-level pages each build their own [Scaffold]
/// with a page-specific [AppBar] and body. Introducing a `ShellRoute`
/// would either nest scaffolds or force a broad rewrite of every
/// top-level page. A shared scaffold widget keeps router changes zero
/// and is less invasive per page (one-line wrap), at the cost of a
/// small amount of duplication at each usage site.
///
/// Secondary pages (listing details, edit listing, auth, legal) keep
/// their plain [Scaffold] and `AppBackButton` — the bottom nav is a
/// top-level affordance only.
class TopLevelScaffold extends StatelessWidget {
  const TopLevelScaffold({
    super.key,
    required this.destination,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  /// Which top-level tab this page represents. Drives the selected
  /// index of the floating capsule nav. Sub-surfaces accessed from
  /// the Menu tab (e.g. My Listings) may pass
  /// [TopLevelDestination.menu] so the Menu tab stays highlighted
  /// while the user is drilled in. Secondary routes (e.g. Account on
  /// `/profile`) use a plain [Scaffold] without this widget.
  final TopLevelDestination destination;

  /// Page body, rendered inside the scaffold.
  final Widget body;

  /// Page-specific [AppBar]. Top-level pages should NOT pass an
  /// `AppBackButton` here because the bottom nav is the primary way to
  /// leave a top-level surface.
  final PreferredSizeWidget? appBar;

  final Widget? floatingActionButton;

  /// Optional override for the scaffold background color. Feed pages
  /// (e.g. the main listings feed) pass a pure white (light) / surface
  /// (dark) value so the feed reads as one clean editorial canvas;
  /// pages that do not pass a value fall back to the Material default.
  final Color? backgroundColor;

  void _onDestinationSelected(BuildContext context, int index) {
    final target = TopLevelDestination.values[index];
    if (target == destination) return;
    // Use `go` so top-level tabs don't stack on top of each other in
    // the router stack. Tapping a tab is a lateral top-level switch,
    // not a push.
    context.go(target.route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: backgroundColor,
      // Let the body render full-height behind the floating nav so
      // the scaffold does not paint a flat rectangle of background
      // around the pill (which made the nav read as a default
      // Material bottom bar with a capsule stuck inside it). Pages
      // add `kFloatingCapsuleNavClearance` to their scrollable
      // bottom padding so the last row clears the pill.
      extendBody: true,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: FloatingCapsuleNav(
        selectedIndex: destination.index,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        // All four destinations use the Lucide outline family so the
        // bar reads as a single set — same stroke weight, consistent
        // geometry, no mix of outlined and rounded Material glyphs.
        destinations: [
          CapsuleNavDestination(
            // Listings tab doubles as the search/discovery surface,
            // so a magnifying-glass icon reads truer than a car icon.
            icon: CarzonIcons.navListings,
            selectedIcon: CarzonIcons.navListings,
            label: l10n.navListings,
          ),
          CapsuleNavDestination(
            icon: CarzonIcons.navFavoritesOutline,
            selectedIcon: CarzonIcons.navFavoritesFilled,
            label: l10n.navFavorites,
          ),
          CapsuleNavDestination(
            // Stronger silhouette than a plain plus so the central
            // "Sell" destination holds its own next to the search and
            // heart icons on either side.
            icon: CarzonIcons.navCreateOutline,
            selectedIcon: CarzonIcons.navCreateFilled,
            label: l10n.navSell,
            // Center/create action — the nav gives it a slightly
            // larger icon so it reads as the primary action without
            // becoming a bright FAB.
            isEmphasized: true,
          ),
          CapsuleNavDestination(
            icon: CarzonIcons.navMenu,
            selectedIcon: CarzonIcons.navMenu,
            label: l10n.navMenu,
          ),
        ],
      ),
    );
  }
}
