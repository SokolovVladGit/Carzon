import 'dart:async';

import 'package:flutter/foundation.dart';

/// How long the tray-level max-limit capsule stays visible.
const Duration kCompareTrayMaxLimitFeedbackDuration = Duration(
  milliseconds: 1750,
);

/// Transient UI state for inline compare tray feedback (not persisted).
class CompareTrayFeedbackController extends ChangeNotifier {
  bool _showingMaxLimit = false;
  Timer? _dismissTimer;

  bool get isShowingMaxLimit => _showingMaxLimit;

  /// Shows the max-limit capsule at the tray position; auto-dismisses.
  void showMaxLimitFeedback() {
    _dismissTimer?.cancel();
    _showingMaxLimit = true;
    notifyListeners();
    _dismissTimer = Timer(
      kCompareTrayMaxLimitFeedbackDuration,
      dismissMaxLimit,
    );
  }

  void dismissMaxLimit() {
    if (!_showingMaxLimit) return;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _showingMaxLimit = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
