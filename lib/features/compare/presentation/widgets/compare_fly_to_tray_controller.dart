import 'package:flutter/material.dart';

/// Active fly-to-tray animation payload.
@immutable
class CompareFlyAnimationPayload {
  const CompareFlyAnimationPayload({
    required this.sourceRect,
    required this.traySlotRect,
    this.imageUrl,
  });

  final Rect sourceRect;

  /// Full tray slot bounds from [CompareFlyToTrayController.trayFlyTargetKey].
  final Rect traySlotRect;
  final String? imageUrl;
}

/// Coordinates compare fly-to-tray overlay playback and tray target measurement.
class CompareFlyToTrayController extends ChangeNotifier {
  CompareFlyAnimationPayload? _active;
  int _generation = 0;

  /// Stable tray slot for fly destination measurement (outside AnimatedSwitcher).
  final GlobalKey trayFlyTargetKey = GlobalKey(
    debugLabel: 'compare_tray_fly_target',
  );

  CompareFlyAnimationPayload? get active => _active;

  bool get isAnimating => _active != null;

  int get generation => _generation;

  /// Starts a fly animation; prior runs are cancelled.
  void play(CompareFlyAnimationPayload payload) {
    _generation++;
    _active = payload;
    notifyListeners();
  }

  /// Called when the overlay finishes; clears [active].
  void complete(int generation) {
    if (generation != _generation) return;
    _active = null;
    notifyListeners();
  }

  void cancel() {
    _generation++;
    _active = null;
    notifyListeners();
  }
}
