import 'package:carzon/features/menu/presentation/widgets/menu_count_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renders nothing for zero count', (tester) async {
    await tester.pumpWidget(wrap(const MenuCountBadge(count: 0)));

    expect(find.byType(MenuCountBadge), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('single-digit count uses compact circle badge', (tester) async {
    await tester.pumpWidget(wrap(const MenuCountBadge(count: 1)));

    expect(
      find.byKey(const ValueKey('menu_count_badge_circle_1')),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('two-digit count uses pill badge without clipping', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MenuCountBadge(count: 12)));

    expect(
      find.byKey(const ValueKey('menu_count_badge_pill_12')),
      findsOneWidget,
    );
    expect(find.text('12'), findsOneWidget);

    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('menu_count_badge_pill_12')),
    );
    expect(box.size.width, greaterThan(22));
  });
}
