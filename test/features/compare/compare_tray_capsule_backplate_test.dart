import 'package:carzon/features/compare/presentation/utils/compare_tray_layout.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_floating_tray.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_dock_shield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('capsule backplate wraps tray without full-width band', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CompareTrayCapsuleBackplate(
              surfaceColor: Colors.white,
              child: SizedBox(
                width: 280,
                height: CompareFloatingTray.height,
                child: const ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );

    final box = tester.renderObject<RenderBox>(
      find.byKey(CompareTrayCapsuleBackplate.backplateKey),
    );
    expect(box.size.width, 280 + CompareTrayCapsuleBackplate.haloPadding * 2);
    expect(
      box.size.height,
      CompareFloatingTray.height + CompareTrayCapsuleBackplate.haloPadding * 2,
    );
  });

  test('compareTrayBottomInset on nav routes clears floating nav', () {
    expect(kCompareTrayGapAboveBottomNav, -20);
    expect(compareTrayUnitHeight(), CompareFloatingTray.height + 12);
  });
}
