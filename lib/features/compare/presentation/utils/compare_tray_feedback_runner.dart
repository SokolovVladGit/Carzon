import 'package:flutter/widgets.dart';

import '../../../../app/di/injection.dart';
import '../widgets/compare_tray_feedback_controller.dart';
import '../widgets/compare_tray_feedback_scope.dart';

/// Shows inline max-limit feedback at the compare tray (no snackbar).
void showCompareTrayMaxLimitFeedback({
  BuildContext? context,
  CompareTrayFeedbackController? controller,
}) {
  final resolved = controller ??
      (context != null ? CompareTrayFeedbackScope.maybeOf(context) : null) ??
      _resolveFeedbackController();
  resolved?.showMaxLimitFeedback();
}

CompareTrayFeedbackController? _resolveFeedbackController() {
  if (!sl.isRegistered<CompareTrayFeedbackController>()) return null;
  return sl<CompareTrayFeedbackController>();
}
