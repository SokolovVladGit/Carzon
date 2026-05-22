import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';

/// Prevents overlapping tray-initiated pushes to [/compare].
bool _compareTrayPushInFlight = false;

/// Resets [openCompareFromTray] push guard (tests only).
void resetCompareTrayNavigationGuardForTests() {
  _compareTrayPushInFlight = false;
}

/// Opens compare from contextual UI (floating tray, etc.) on the navigation stack.
///
/// Uses [GoRouter.push] so [AppBackButton] can [GoRouter.pop] back to the
/// screen the user came from. No-op when already on [AppRoutes.compare] or
/// while a tray push is in flight.
void openCompareFromTray(GoRouter router) {
  final path = router.routerDelegate.currentConfiguration.uri.path;
  if (path == AppRoutes.compare) return;
  if (_compareTrayPushInFlight) return;

  _compareTrayPushInFlight = true;
  router.push(AppRoutes.compare).whenComplete(() {
    _compareTrayPushInFlight = false;
  });
}
