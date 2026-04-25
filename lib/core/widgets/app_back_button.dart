import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';

/// A consistent back button for Carzon's secondary pages.
///
/// Problem this solves: the app navigates with `go_router`'s
/// `context.go(...)` from top-level entry points, which replaces the
/// navigation stack. On those replaced routes Flutter's built-in
/// `AppBar.automaticallyImplyLeading` sees no `canPop` and renders no
/// arrow, so deep-linked or tab-switched users can get stuck with no
/// visible way back.
///
/// This widget renders a normal back arrow that:
///   * pops the route if a back stack exists (`context.canPop()`),
///   * otherwise navigates to [fallback] via `context.go(fallback)`,
///     defaulting to the public listings feed (`/`).
///
/// Use as `AppBar.leading: const AppBackButton()` or with a page-
/// appropriate [fallback] such as `AppRoutes.myListings` or
/// `AppRoutes.signIn`.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallback = AppRoutes.listings,
    this.tooltip,
  });

  /// Route to navigate to when there is no back stack. Defaults to the
  /// public listings feed so deep-linked users always land somewhere
  /// meaningful.
  final String fallback;

  /// Optional tooltip override. Defaults to the system "Back" string
  /// via [BackButtonIcon] / [Tooltip].
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      icon: const BackButtonIcon(),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallback);
        }
      },
    );
  }
}
