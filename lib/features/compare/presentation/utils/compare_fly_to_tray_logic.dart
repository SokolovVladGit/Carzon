import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Whether the fly-to-tray micro-animation should run.
bool shouldPlayCompareFlyAnimation({
  required bool itemWasAdded,
  required bool animationsEnabled,
  required bool trayVisibleOnRoute,
  required bool hasMeasurableSource,
}) {
  if (!itemWasAdded) return false;
  if (!animationsEnabled) return false;
  if (!trayVisibleOnRoute) return false;
  if (!hasMeasurableSource) return false;
  return true;
}

/// Reads [MediaQuery.disableAnimationsOf] when available.
bool compareFlyAnimationsEnabled(BuildContext context) {
  return !MediaQuery.disableAnimationsOf(context);
}

/// Global bounds of [key]'s render box, or null if not laid out.
Rect? measureGlobalRect(GlobalKey? key) {
  if (key == null) return null;
  final context = key.currentContext;
  if (context == null) return null;
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final offset = box.localToGlobal(Offset.zero);
  return offset & box.size;
}

/// First non-null measurable rect from [keys] in order.
Rect? measureFirstGlobalRect(Iterable<GlobalKey?> keys) {
  for (final key in keys) {
    final rect = measureGlobalRect(key);
    if (rect != null) return rect;
  }
  return null;
}

/// Schedules [run] after the compare tray has had time to lay out.
void scheduleCompareFlyMeasure({
  required bool trayWasHiddenBeforeAdd,
  required VoidCallback run,
}) {
  void frame() => SchedulerBinding.instance.addPostFrameCallback((_) => run());

  if (trayWasHiddenBeforeAdd) {
    frame();
    frame();
  } else {
    frame();
  }
}

/// Interpolates [start]→[end] with a subtle upward arc (pixels).
Rect compareFlyRectAt({
  required Rect start,
  required Rect end,
  required double t,
  double arcHeight = 20,
}) {
  final curved = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
  final base = Rect.lerp(start, end, curved) ?? end;
  final arcOffset = -arcHeight * (4 * t * (1 - t));
  return base.shift(Offset(0, arcOffset));
}

/// Progress (0–1) along the travel path; stops before the tray area.
double compareFlyPathProgressAt(double t) {
  const pathCompleteAt = 0.58;
  if (t >= pathCompleteAt) return 1;
  if (t <= 0) return 0;
  return Curves.easeInOutCubic.transform(t / pathCompleteAt);
}

/// Opacity fades out during travel; zero before the tray is reached.
double compareFlyOpacityAt(double t) {
  const fadeStart = 0.50;
  const fadeEnd = 0.72;
  if (t >= fadeEnd) return 0;
  if (t <= fadeStart) return 1;
  return (1 - (t - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0);
}

/// Flying thumbnail size; shrinks to [compareFlyMinThumbSize] while fading.
double compareFlyThumbSizeAt(double t) {
  const maxSize = 44.0;
  const fadeStart = 0.50;
  const fadeEnd = 0.72;
  if (t <= fadeStart) return maxSize;
  if (t >= fadeEnd) return compareFlyMinThumbSize;
  final u = Curves.easeIn.transform(
    ((t - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0),
  );
  return maxSize - (maxSize - compareFlyMinThumbSize) * u;
}

/// Smallest painted fly size before the overlay is cleared.
const double compareFlyMinThumbSize = 8;

/// Progress after which the fly must not be visible.
const double compareFlyHiddenAfterProgress = 0.72;

/// Center above [traySlot] where the path ends (never inside tray bounds).
Offset compareFlyVisualEndCenter(Rect traySlot, Rect thumbInTray) {
  const clearanceAboveTray = 36;
  return Offset(thumbInTray.center.dx, traySlot.top - clearanceAboveTray);
}

/// Visual endpoint rect above the tray (measurement / tests).
Rect compareFlyVisualEndRect(Rect traySlot) {
  final thumb = compareFlyThumbnailTargetRect(traySlot);
  final center = compareFlyVisualEndCenter(traySlot, thumb);
  return Rect.fromCenter(
    center: center,
    width: 44,
    height: 44,
  );
}

/// Bounds of the flying thumbnail at progress [t].
Rect compareFlyThumbRectAt({
  required Rect start,
  required Rect traySlot,
  required double t,
  double arcHeight = 24,
}) {
  final visualEnd = compareFlyVisualEndRect(traySlot);
  final pathT = compareFlyPathProgressAt(t);
  final size = compareFlyThumbSizeAt(t);
  final center = Offset.lerp(start.center, visualEnd.center, pathT)!;
  final arcOffset = -arcHeight * (4 * pathT * (1 - pathT));
  return Rect.fromCenter(
    center: center.translate(0, arcOffset),
    width: size,
    height: size,
  );
}

/// Whether [thumb] intersects the tray slot (used in tests).
bool compareFlyThumbOverlapsTray({
  required Rect traySlot,
  required Rect thumb,
}) {
  return thumb.overlaps(traySlot);
}

/// Left thumbnail cluster inside the tray slot (stable outer [trayFlyTargetKey]).
Rect compareFlyThumbnailTargetRect(
  Rect traySlotBounds, {
  double thumbSize = 44,
}) {
  const padLeft = 12;
  final top = traySlotBounds.top +
      (traySlotBounds.height - thumbSize) / 2;
  return Rect.fromLTWH(
    traySlotBounds.left + padLeft,
    top,
    thumbSize,
    thumbSize,
  );
}
