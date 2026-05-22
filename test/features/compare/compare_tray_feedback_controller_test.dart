import 'package:carzon/features/compare/presentation/widgets/compare_tray_feedback_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('showMaxLimitFeedback auto-dismisses', () async {
    final controller = CompareTrayFeedbackController();
    addTearDown(controller.dispose);

    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    controller.showMaxLimitFeedback();
    expect(controller.isShowingMaxLimit, isTrue);

    await Future<void>.delayed(kCompareTrayMaxLimitFeedbackDuration);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.isShowingMaxLimit, isFalse);
    expect(notifyCount, greaterThanOrEqualTo(2));
  });

  test('dismissMaxLimit cancels pending auto-dismiss', () {
    final controller = CompareTrayFeedbackController();
    addTearDown(controller.dispose);

    controller.showMaxLimitFeedback();
    controller.dismissMaxLimit();
    expect(controller.isShowingMaxLimit, isFalse);
  });
}
