import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../widgets/compare_fly_to_tray_controller.dart';
import 'compare_fly_to_tray_logic.dart';
import 'compare_tray_layout.dart';

/// Measures rects and starts the fly-to-tray animation when eligible.
void requestCompareFlyToTray({
  required BuildContext context,
  CompareFlyToTrayController? controller,
  GlobalKey? sourceKey,
  GlobalKey? sourceFallbackKey,
  required String? imageUrl,
  required bool itemWasAdded,
  required bool trayWasHiddenBeforeAdd,
}) {
  final trayVisible = _isTrayVisibleOnCurrentRoute(context);
  final animationsEnabled = compareFlyAnimationsEnabled(context);
  final hasSource = sourceKey != null || sourceFallbackKey != null;

  if (!shouldPlayCompareFlyAnimation(
    itemWasAdded: itemWasAdded,
    animationsEnabled: animationsEnabled,
    trayVisibleOnRoute: trayVisible,
    hasMeasurableSource: hasSource,
  )) {
    return;
  }

  final flyController = controller ?? _resolveFlyController();
  if (flyController == null) return;

  scheduleCompareFlyMeasure(
    trayWasHiddenBeforeAdd: trayWasHiddenBeforeAdd,
    run: () {
      if (!context.mounted) return;
      final source = measureFirstGlobalRect([sourceKey, sourceFallbackKey]);
      final trayBounds = measureGlobalRect(flyController.trayFlyTargetKey);
      if (source == null || trayBounds == null) return;

      flyController.play(
        CompareFlyAnimationPayload(
          sourceRect: source,
          traySlotRect: trayBounds,
          imageUrl: imageUrl,
        ),
      );
    },
  );
}

bool _isTrayVisibleOnCurrentRoute(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return false;
  final location = router.routerDelegate.currentConfiguration.uri.toString();
  return !compareTrayHiddenForRoute(location);
}

CompareFlyToTrayController? _resolveFlyController() {
  if (!sl.isRegistered<CompareFlyToTrayController>()) return null;
  return sl<CompareFlyToTrayController>();
}
