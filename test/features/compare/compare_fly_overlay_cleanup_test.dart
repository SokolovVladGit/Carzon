import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_layer.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('overlay completes and unmounts after animation', (tester) async {
    final controller = CompareFlyToTrayController();
    addTearDown(controller.cancel);
    const payload = CompareFlyAnimationPayload(
      sourceRect: Rect.fromLTWH(40, 40, 350, 260),
      traySlotRect: Rect.fromLTWH(188, 400, 300, 68),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Scaffold(
            body: SizedBox.expand(
              child: Stack(
                children: [CompareFlyToTrayOverlaySlot(controller: controller)],
              ),
            ),
          ),
        ),
      ),
    );

    controller.play(payload);
    await tester.pump();

    expect(controller.isAnimating, isTrue);
    expect(find.byType(CompareFlyToTrayOverlay), findsOneWidget);

    // Opacity hits 0 at t=0.72 (~360ms); overlay must clear immediately.
    await tester.pump(const Duration(milliseconds: 370));
    expect(controller.isAnimating, isFalse);
    expect(controller.active, isNull);
    expect(find.byType(CompareFlyToTrayOverlay), findsNothing);

    await tester.pump(CompareFlyToTrayOverlay.duration);
    expect(controller.isAnimating, isFalse);
    expect(find.byType(CompareFlyToTrayOverlay), findsNothing);
  });

  testWidgets('fly overlay does not use ListingCoverImage', (tester) async {
    final controller = CompareFlyToTrayController();
    addTearDown(controller.cancel);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Scaffold(
            body: SizedBox.expand(
              child: Stack(
                children: [CompareFlyToTrayOverlaySlot(controller: controller)],
              ),
            ),
          ),
        ),
      ),
    );

    controller.play(
      const CompareFlyAnimationPayload(
        sourceRect: Rect.fromLTWH(40, 40, 100, 80),
        traySlotRect: Rect.fromLTWH(188, 400, 300, 68),
        imageUrl: 'https://example.com/a.jpg',
      ),
    );
    await tester.pump();

    expect(find.byType(CompareFlyToTrayOverlay), findsOneWidget);
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      expect(image.width, 44);
      expect(image.height, 44);
    }
  });
}
