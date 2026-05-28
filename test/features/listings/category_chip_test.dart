import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/listings/presentation/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _chipHarness({required CategoryChip child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('CategoryChip unselected builds without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
          label: 'Универсал',
          icon: Icons.luggage_outlined,
          isSelected: false,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Универсал'), findsOneWidget);
  });

  testWidgets('CategoryChip selected builds without throwing', (tester) async {
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
          label: 'Минивэн',
          icon: Icons.airport_shuttle_outlined,
          isSelected: true,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Минивэн'), findsOneWidget);
  });

  testWidgets('CategoryChip tap invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _chipHarness(
        child: CategoryChip(
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
          label: 'Хэтчбек',
          icon: Icons.time_to_leave_outlined,
          isSelected: true,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Хэтчбек'), findsOneWidget);
  });

  testWidgets('CategoryChip unselected icon uses readable foreground in dark', (
    tester,
  ) async {
    final theme = AppTheme.dark();
    await tester.pumpWidget(
      _chipHarness(
        theme: theme,
        child: CategoryChip(
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
}
