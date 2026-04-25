import 'package:carzon/core/widgets/floating_capsule_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a minimal host that renders [FloatingCapsuleNav] as a
/// bottom nav so the widget is exercised in the same layout shape
/// it ships in (i.e. as a `Scaffold.bottomNavigationBar`).
Widget _host({
  required int selectedIndex,
  required ValueChanged<int> onTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: FloatingCapsuleNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        destinations: const [
          CapsuleNavDestination(
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car,
            label: 'Feed',
          ),
          CapsuleNavDestination(
            icon: Icons.favorite_border,
            selectedIcon: Icons.favorite,
            label: 'Favs',
          ),
          CapsuleNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Me',
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('FloatingCapsuleNav', () {
    testWidgets(
      'exposes every destination via a Semantics label (icon-only bar, '
      'so labels are not rendered as visible text) and via a Tooltip',
      (tester) async {
        await tester.pumpWidget(_host(selectedIndex: 0, onTap: (_) {}));

        // Pass 1.5: labels are no longer drawn under the icons. The
        // localized name must still reach screen readers and tooltips.
        for (final label in const ['Feed', 'Favs', 'Me']) {
          expect(
            find.text(label),
            findsNothing,
            reason: 'Nav must not render visible text labels in Pass 1.5',
          );
          expect(
            find.bySemanticsLabel(label),
            findsWidgets,
            reason: 'Nav must expose a Semantics label for "$label"',
          );
          expect(
            find.byTooltip(label),
            findsOneWidget,
            reason: 'Nav must expose a Tooltip for "$label"',
          );
        }
      },
    );

    testWidgets(
      'uses the selected icon for the currently selected destination and '
      'the outlined icon for the others',
      (tester) async {
        await tester.pumpWidget(_host(selectedIndex: 1, onTap: (_) {}));

        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
        expect(find.byIcon(Icons.directions_car), findsNothing);
      },
    );

    testWidgets(
      'invokes onDestinationSelected with the tapped index, using '
      'semantics labels as the tap target',
      (tester) async {
        var tapped = -1;
        await tester.pumpWidget(
          _host(selectedIndex: 0, onTap: (i) => tapped = i),
        );

        await tester.tap(find.bySemanticsLabel('Favs'));
        expect(tapped, 1);

        await tester.tap(find.bySemanticsLabel('Me'));
        expect(tapped, 2);
      },
    );

    testWidgets('is NOT a Material NavigationBar', (tester) async {
      await tester.pumpWidget(_host(selectedIndex: 0, onTap: (_) {}));

      expect(find.byType(FloatingCapsuleNav), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets(
      'lays out all 5 Carzon destinations on a narrow 320-wide device '
      'without overflow now that labels are removed',
      (tester) async {
        tester.view.physicalSize = const Size(320, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: FloatingCapsuleNav(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: const [
                  CapsuleNavDestination(
                    icon: Icons.directions_car_outlined,
                    selectedIcon: Icons.directions_car,
                    label: 'Объявления',
                  ),
                  CapsuleNavDestination(
                    icon: Icons.favorite_border,
                    selectedIcon: Icons.favorite,
                    label: 'Избранное',
                  ),
                  CapsuleNavDestination(
                    icon: Icons.add_circle_outline,
                    selectedIcon: Icons.add_circle,
                    label: 'Подать',
                    isEmphasized: true,
                  ),
                  CapsuleNavDestination(
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2,
                    label: 'Мои',
                  ),
                  CapsuleNavDestination(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Профиль',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        for (final label in const [
          'Объявления',
          'Избранное',
          'Подать',
          'Мои',
          'Профиль',
        ]) {
          expect(find.bySemanticsLabel(label), findsWidgets);
        }
      },
    );

    testWidgets(
      'renders the emphasized destination with a bigger icon than a '
      'non-emphasized one',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: FloatingCapsuleNav(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: const [
                  CapsuleNavDestination(
                    icon: Icons.directions_car_outlined,
                    selectedIcon: Icons.directions_car,
                    label: 'Feed',
                  ),
                  CapsuleNavDestination(
                    icon: Icons.add_circle_outline,
                    selectedIcon: Icons.add_circle,
                    label: 'Sell',
                    isEmphasized: true,
                  ),
                ],
              ),
            ),
          ),
        );

        final regular = tester.widget<Icon>(
          find.byIcon(Icons.directions_car),
        );
        final emphasized = tester.widget<Icon>(
          find.byIcon(Icons.add_circle_outline),
        );
        expect(
          (emphasized.size ?? 0) > (regular.size ?? 0),
          isTrue,
          reason: 'Emphasized destination should render a larger icon',
        );
      },
    );
  });
}
