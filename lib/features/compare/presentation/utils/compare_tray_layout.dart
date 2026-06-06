import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../widgets/compare_floating_tray.dart';
import '../widgets/compare_tray_dock_shield.dart';

/// Main discovery feed — the only route where the floating compare tray appears.
///
/// [AppRoutes.listings] is `/` (home). Query strings on that path still count
/// as the listings feed, e.g. `/?openFilters=1`.
bool compareTrayVisibleForRoute(String location) {
  final path = Uri.parse(location).path;
  return path == AppRoutes.listings;
}

/// Routes where the floating compare tray is not shown.
bool compareTrayHiddenForRoute(String location) {
  return !compareTrayVisibleForRoute(location);
}

/// Top-level surfaces that render [FloatingCapsuleNav] under the tray.
bool compareTrayUsesBottomNavClearance(String location) {
  final path = Uri.parse(location).path;
  const withNav = <String>{
    AppRoutes.listings,
    AppRoutes.favorites,
    AppRoutes.createListing,
    AppRoutes.menu,
    AppRoutes.myListings,
  };
  return withNav.contains(path);
}

/// Extra offset between tray bottom and [kFloatingCapsuleNavClearance].
///
/// Negative values move the tray closer to the floating nav (small slit).
/// Tuned so the capsule clears nav icons without overlapping them.
const double kCompareTrayGapAboveBottomNav = -20;

/// Bottom inset for positioning the compare tray above system UI.
double compareTrayBottomInset(BuildContext context, String location) {
  if (compareTrayUsesBottomNavClearance(location)) {
    return kFloatingCapsuleNavClearance +
        kCompareTrayGapAboveBottomNav +
        MediaQuery.paddingOf(context).bottom;
  }
  return 16 + MediaQuery.paddingOf(context).bottom;
}

/// Total vertical size of the positioned tray unit (backplate + capsule + shadow).
double compareTrayUnitHeight() {
  return CompareFloatingTray.height +
      CompareTrayCapsuleBackplate.haloPadding * 2;
}
