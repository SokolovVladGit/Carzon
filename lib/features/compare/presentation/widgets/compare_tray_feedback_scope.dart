import 'package:flutter/material.dart';

import 'compare_tray_feedback_controller.dart';

/// Exposes [CompareTrayFeedbackController] to [CompareToggleButton] under [CompareTrayHost].
class CompareTrayFeedbackScope extends InheritedWidget {
  const CompareTrayFeedbackScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final CompareTrayFeedbackController controller;

  static CompareTrayFeedbackController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CompareTrayFeedbackScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(CompareTrayFeedbackScope oldWidget) =>
      oldWidget.controller != controller;
}
