import 'dart:ui';

import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('play and complete clears active payload', () {
    final controller = CompareFlyToTrayController();
    addTearDown(controller.cancel);

    const payload = CompareFlyAnimationPayload(
      sourceRect: Rect.fromLTWH(0, 0, 80, 60),
      traySlotRect: Rect.fromLTWH(100, 200, 300, 68),
    );
    controller.play(payload);
    expect(controller.isAnimating, isTrue);

    controller.complete(controller.generation);
    expect(controller.isAnimating, isFalse);
    expect(controller.active, isNull);
  });

  test('stale complete does not clear newer animation', () {
    final controller = CompareFlyToTrayController();
    addTearDown(controller.cancel);

    controller.play(
      const CompareFlyAnimationPayload(
        sourceRect: Rect.fromLTWH(0, 0, 10, 10),
        traySlotRect: Rect.fromLTWH(1, 1, 300, 68),
      ),
    );
    final firstGen = controller.generation;
    controller.play(
      const CompareFlyAnimationPayload(
        sourceRect: Rect.fromLTWH(0, 0, 20, 20),
        traySlotRect: Rect.fromLTWH(2, 2, 300, 68),
      ),
    );
    controller.complete(firstGen);
    expect(controller.isAnimating, isTrue);
  });
}
