import 'package:carzon/features/compare/presentation/utils/compare_fly_to_tray_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldPlayCompareFlyAnimation', () {
    test('true only when all gates pass', () {
      expect(
        shouldPlayCompareFlyAnimation(
          itemWasAdded: true,
          animationsEnabled: true,
          trayVisibleOnRoute: true,
          hasMeasurableSource: true,
        ),
        isTrue,
      );
    });

    test('false when item was not added', () {
      expect(
        shouldPlayCompareFlyAnimation(
          itemWasAdded: false,
          animationsEnabled: true,
          trayVisibleOnRoute: true,
          hasMeasurableSource: true,
        ),
        isFalse,
      );
    });

    test('false when animations disabled', () {
      expect(
        shouldPlayCompareFlyAnimation(
          itemWasAdded: true,
          animationsEnabled: false,
          trayVisibleOnRoute: true,
          hasMeasurableSource: true,
        ),
        isFalse,
      );
    });

    test('false when tray hidden on route', () {
      expect(
        shouldPlayCompareFlyAnimation(
          itemWasAdded: true,
          animationsEnabled: true,
          trayVisibleOnRoute: false,
          hasMeasurableSource: true,
        ),
        isFalse,
      );
    });

    test('false without measurable source', () {
      expect(
        shouldPlayCompareFlyAnimation(
          itemWasAdded: true,
          animationsEnabled: true,
          trayVisibleOnRoute: true,
          hasMeasurableSource: false,
        ),
        isFalse,
      );
    });
  });

  testWidgets('compareFlyAnimationsEnabled respects disableAnimations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              expect(compareFlyAnimationsEnabled(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });

  test('compareFlyRectAt applies upward arc', () {
    const start = Rect.fromLTWH(0, 100, 120, 90);
    const end = Rect.fromLTWH(200, 400, 44, 44);
    final mid = compareFlyRectAt(start: start, end: end, t: 0.5);
    final linear = Rect.lerp(start, end, 0.5)!;
    expect(mid.top, lessThan(linear.top));
  });

  test('compareFlyOpacityAt fades before tray overlap window', () {
    expect(compareFlyOpacityAt(0.45), 1);
    expect(compareFlyOpacityAt(0.50), 1);
    expect(compareFlyOpacityAt(0.60), lessThan(1));
    expect(compareFlyOpacityAt(0.60), greaterThan(0));
    expect(compareFlyOpacityAt(0.72), 0);
    expect(compareFlyOpacityAt(1.0), 0);
  });

  test('compareFlyPathProgressAt stops before full animation duration', () {
    expect(compareFlyPathProgressAt(0.58), 1);
    expect(compareFlyPathProgressAt(0.70), 1);
    expect(compareFlyPathProgressAt(0.30), lessThan(1));
  });

  test('compareFlyThumbSizeAt shrinks while fading', () {
    expect(compareFlyThumbSizeAt(0.45), 44);
    expect(compareFlyThumbSizeAt(0.55), lessThan(44));
    expect(compareFlyThumbSizeAt(0.72), compareFlyMinThumbSize);
  });

  test('compareFlyVisualEndRect sits above tray slot', () {
    const tray = Rect.fromLTWH(100, 500, 300, 68);
    final end = compareFlyVisualEndRect(tray);
    expect(end.bottom, lessThan(tray.top));
  });

  test('last visible fly thumb does not overlap tray', () {
    const start = Rect.fromLTWH(40, 40, 350, 260);
    const tray = Rect.fromLTWH(100, 500, 300, 68);
    const lastVisibleT = 0.71;
    final thumb = compareFlyThumbRectAt(start: start, traySlot: tray, t: lastVisibleT);
    expect(compareFlyOpacityAt(lastVisibleT), greaterThan(0));
    expect(compareFlyThumbOverlapsTray(traySlot: tray, thumb: thumb), isFalse);
    expect(thumb.bottom, lessThan(tray.top));
  });

  test('at hide progress thumb is tiny and opacity is zero', () {
    const start = Rect.fromLTWH(40, 40, 350, 260);
    const tray = Rect.fromLTWH(100, 500, 300, 68);
    const t = compareFlyHiddenAfterProgress;
    final thumb = compareFlyThumbRectAt(start: start, traySlot: tray, t: t);
    expect(compareFlyOpacityAt(t), 0);
    expect(thumb.width, lessThanOrEqualTo(compareFlyMinThumbSize));
  });

  test('compareFlyThumbnailTargetRect targets left thumbnail cluster', () {
    const tray = Rect.fromLTWH(100, 500, 300, 68);
    final thumb = compareFlyThumbnailTargetRect(tray);
    expect(thumb.width, 44);
    expect(thumb.height, 44);
    expect(thumb.left, 112);
  });
}
