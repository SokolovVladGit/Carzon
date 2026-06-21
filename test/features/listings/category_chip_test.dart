import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/listings/presentation/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _chipHarness({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: Center(child: child)),
  );
}

bool _isHorizontalFlipTransform(Transform transform) {
  final matrix = transform.transform;
  return (matrix.entry(0, 0) + 1.0).abs() < 0.001 &&
      (matrix.entry(1, 1) - 1.0).abs() < 0.001;
}

void main() {
  testWidgets('CategoryChip unselected builds without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
          chipId: 'wagon',
          label: 'Универсал',
          icon: Icons.luggage_outlined,
          isSelected: false,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Универсал'), findsNothing);
    expect(find.bySemanticsLabel('Универсал'), findsOneWidget);
  });

  testWidgets('CategoryChip selected builds without throwing', (tester) async {
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
          chipId: 'minivan',
          label: 'Минивэн',
          icon: Icons.airport_shuttle_outlined,
          isSelected: true,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Минивэн'), findsNothing);
    expect(find.bySemanticsLabel('Минивэн'), findsOneWidget);
  });

  testWidgets('CategoryChip tap invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
          chipId: 'sedan',
          label: 'Tap target',
          icon: Icons.directions_car_outlined,
          isSelected: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(CategoryChip));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('CategoryChip semantics exposes button and selected state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
          chipId: 'suv',
          label: 'Selected chip',
          icon: Icons.directions_car_outlined,
          isSelected: true,
          onTap: () {},
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(CategoryChip)),
      matchesSemantics(
        label: 'Selected chip',
        isButton: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('CategoryChip semantics unselected state', (tester) async {
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
          chipId: 'hatchback',
          label: 'Idle chip',
          icon: Icons.directions_car_outlined,
          isSelected: false,
          onTap: () {},
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(CategoryChip)),
      matchesSemantics(
        label: 'Idle chip',
        isButton: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: false,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('CategoryChip builds in dark theme', (tester) async {
    await tester.pumpWidget(
      _chipHarness(
        theme: AppTheme.dark(),
        child: CategoryChip(
          chipId: 'hatchback',
          label: 'Хэтчбек',
          icon: Icons.time_to_leave_outlined,
          isSelected: true,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Хэтчбек'), findsNothing);
    expect(find.bySemanticsLabel('Хэтчбек'), findsOneWidget);
  });

  testWidgets('CategoryChip unselected icon uses readable foreground in dark', (
    tester,
  ) async {
    final theme = AppTheme.dark();
    await tester.pumpWidget(
      _chipHarness(
        theme: theme,
        child: CategoryChip(
          chipId: 'sedan',
          label: 'Седан',
          icon: Icons.directions_car_outlined,
          isSelected: false,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color!.a, greaterThan(0.94));
  });

  testWidgets('CategoryChip selected icon uses high-contrast color in dark', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chipHarness(
        theme: AppTheme.dark(),
        child: CategoryChip(
          chipId: 'coupe',
          label: 'Купе',
          icon: Icons.time_to_leave_outlined,
          isSelected: true,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color!.a, greaterThan(0.94));
  });

  testWidgets(
    'CategoryChip sedan and pickup SVGs are not horizontally mirrored',
    (tester) async {
      for (final chip in [
        (id: 'sedan', path: 'assets/categories/svg/sedan.svg', label: 'Седан'),
        (
          id: 'pickup',
          path: 'assets/categories/svg/pickup.svg',
          label: 'Пикап',
        ),
      ]) {
        await tester.pumpWidget(
          _chipHarness(
            child: CategoryChip(
              chipId: chip.id,
              label: chip.label,
              icon: Icons.directions_car_outlined,
              isSelected: false,
              onTap: () {},
              svgAssetPath: chip.path,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final horizontalFlips = tester
            .widgetList<Transform>(find.byType(Transform))
            .where(_isHorizontalFlipTransform);
        expect(horizontalFlips, isEmpty, reason: chip.id);
      }
    },
  );

  testWidgets('CategoryChip icon-only chips hide labels but keep semantics', (
    tester,
  ) async {
    const labels = ['Универсал', 'Минивэн', 'Хэтчбек'];
    for (final label in labels) {
      await tester.pumpWidget(
        _chipHarness(
          child: CategoryChip(
            chipId: label == 'Универсал'
                ? 'wagon'
                : label == 'Минивэн'
                ? 'minivan'
                : 'hatchback',
            label: label,
            icon: Icons.directions_car_outlined,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
      expect(find.text(label), findsNothing);
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
  });

  testWidgets('CategoryChip icon-only chips render without overflow', (
    tester,
  ) async {
    const chips = [
      (chipId: 'sedan', label: 'Седан'),
      (chipId: 'wagon', label: 'Универсал'),
      (chipId: 'pickup', label: 'Пикап'),
      (chipId: 'minivan', label: 'Минивэн'),
    ];

    for (final chip in chips) {
      await tester.pumpWidget(
        _chipHarness(
          child: CategoryChip(
            chipId: chip.chipId,
            label: chip.label,
            icon: Icons.directions_car_outlined,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: chip.chipId);
      expect(find.text(chip.label), findsNothing);
      expect(find.bySemanticsLabel(chip.label), findsOneWidget);
    }
  });

  testWidgets(
    'CategoryChip All chip uses all_bodies.svg without visible label',
    (tester) async {
      const allBodiesAsset = 'assets/categories/svg/all_bodies.svg';

      await tester.pumpWidget(
        _chipHarness(
          child: CategoryChip(
            chipId: 'all',
            label: 'Все',
            icon: Icons.directions_car_outlined,
            svgAssetPath: allBodiesAsset,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Все'), findsNothing);
      expect(find.bySemanticsLabel('Все'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      final svgs = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
      expect(svgs.length, 1);
      expect(svgs.first.width, CategoryChip.allIconSize);
      expect(svgs.first.height, CategoryChip.allIconSize);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CategoryChip All chip selected preserves semantics without dot',
    (tester) async {
      const allBodiesAsset = 'assets/categories/svg/all_bodies.svg';

      await tester.pumpWidget(
        _chipHarness(
          child: CategoryChip(
            chipId: 'all',
            label: 'Все',
            icon: Icons.directions_car_outlined,
            svgAssetPath: allBodiesAsset,
            isSelected: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(CategoryChip)),
        matchesSemantics(
          label: 'Все',
          isButton: true,
          isFocusable: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
    },
  );

  testWidgets('CategoryChip vehicle silhouettes use width-based SVG sizing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chipHarness(
        child: Row(
          children: [
            CategoryChip(
              chipId: 'sedan',
              label: 'Седан',
              icon: Icons.directions_car_outlined,
              isSelected: false,
              onTap: () {},
              svgAssetPath: 'assets/categories/svg/sedan.svg',
            ),
            CategoryChip(
              chipId: 'wagon',
              label: 'Универсал',
              icon: Icons.luggage_outlined,
              isSelected: false,
              onTap: () {},
              svgAssetPath: 'assets/categories/svg/wagon.svg',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final svgs = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(svgs.length, 2);
    expect(svgs.first.width, CategoryChip.vehicleIconBaseWidth);
    expect(svgs.first.height, isNull);
    expect(svgs.last.width, CategoryChip.vehicleIconBaseWidth * 1.04);
    expect(svgs.last.height, isNull);
  });

  testWidgets('CategoryChip icon-only chips keep fixed layout box', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chipHarness(
        child: Row(
          children: [
            CategoryChip(
              chipId: 'sedan',
              label: 'Седан',
              icon: Icons.directions_car_outlined,
              isSelected: false,
              onTap: () {},
            ),
            CategoryChip(
              chipId: 'wagon',
              label: 'Универсал',
              icon: Icons.luggage_outlined,
              isSelected: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chipBoxes = tester.widgetList<SizedBox>(
      find.descendant(
        of: find.byType(CategoryChip),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.width == CategoryChip.chipWidth &&
              widget.height == CategoryChip.chipHeight,
        ),
      ),
    );
    expect(chipBoxes.length, 2);
    for (final box in chipBoxes) {
      expect(box.width, CategoryChip.chipWidth);
      expect(box.height, CategoryChip.chipHeight);
    }

    final icons = tester.widgetList<Icon>(find.byType(Icon));
    expect(icons.length, 2);
    expect(icons.first.size, CategoryChip.iconBaseSize);
    expect(icons.last.size, CategoryChip.iconBaseSize);
  });

  testWidgets('CategoryChip boosted pickup renders without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
          chipId: 'pickup',
          label: 'Пикап',
          icon: Icons.local_shipping_outlined,
          isSelected: true,
          onTap: () {},
          svgAssetPath: 'assets/categories/svg/pickup.svg',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
