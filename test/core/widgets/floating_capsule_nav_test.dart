import 'package:carzon/core/widgets/floating_capsule_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _searchOverlay(BuildContext context) {
  return const IgnorePointer(
    child: Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        key: ValueKey<String>('search-overlay-probe'),
        width: 8,
        height: 8,
      ),
    ),
  );
}

/// Builds a minimal host that renders [FloatingCapsuleNav] as a
/// bottom nav so the widget is exercised in the same layout shape
/// it ships in (i.e. as a `Scaffold.bottomNavigationBar`).
Widget _host({required int selectedIndex, required ValueChanged<int> onTap}) {
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

    testWidgets('invokes onDestinationSelected with the tapped index, using '
        'semantics labels as the tap target', (tester) async {
      var tapped = -1;
      await tester.pumpWidget(
        _host(selectedIndex: 0, onTap: (i) => tapped = i),
      );

      await tester.tap(find.bySemanticsLabel('Favs'));
      expect(tapped, 1);

      await tester.tap(find.bySemanticsLabel('Me'));
      expect(tapped, 2);
    });

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
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Главная',
                  ),
                  CapsuleNavDestination(
                    icon: Icons.search,
                    selectedIcon: Icons.search,
                    label: 'Поиск',
                  ),
                  CapsuleNavDestination(
                    assetIcon: 'assets/icons/icon_plus.png',
                    label: 'Подать',
                    isEmphasized: true,
                  ),
                  CapsuleNavDestination(
                    icon: Icons.favorite_border,
                    selectedIcon: Icons.favorite,
                    label: 'Избранное',
                  ),
                  CapsuleNavDestination(
                    icon: Icons.menu,
                    selectedIcon: Icons.menu,
                    label: 'Меню',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        final targets = tester.renderObjectList<RenderBox>(
          find.byType(AnimatedContainer),
        );
        expect(targets.length, 5);
        for (final target in targets) {
          expect(target.size, const Size(44, 44));
        }

        for (final label in const [
          'Главная',
          'Поиск',
          'Подать',
          'Избранное',
          'Меню',
        ]) {
          expect(find.bySemanticsLabel(label), findsWidgets);
        }

        final create = tester.widget<Image>(
          find.byKey(kCapsuleNavCreateAssetKey),
        );
        expect(create.width, kCapsuleNavCreateAssetSize);
        expect(create.height, kCapsuleNavCreateAssetSize);
        expect(create.fit, BoxFit.contain);
        expect(create.color, isNull);
      },
    );

    testWidgets(
      'normal destinations share Home selected chrome; Create has none',
      (tester) async {
        final destinations = [
          CapsuleNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          CapsuleNavDestination(
            icon: Icons.search,
            selectedIcon: Icons.search,
            label: 'Search',
            iconOverlayBuilder: _searchOverlay,
          ),
          CapsuleNavDestination(
            assetIcon: 'assets/icons/icon_plus.png',
            label: 'Sell',
            isEmphasized: true,
          ),
          CapsuleNavDestination(
            icon: Icons.favorite_border,
            selectedIcon: Icons.favorite,
            label: 'Favs',
          ),
          CapsuleNavDestination(
            icon: Icons.menu,
            selectedIcon: Icons.menu,
            label: 'Menu',
          ),
        ];

        Future<void> pumpSelected(int index) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: const SizedBox.expand(),
                bottomNavigationBar: FloatingCapsuleNav(
                  selectedIndex: index,
                  onDestinationSelected: (_) {},
                  destinations: destinations,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        ColorScheme schemeOf() {
          return Theme.of(
            tester.element(find.byType(FloatingCapsuleNav)),
          ).colorScheme;
        }

        BoxDecoration chromeOf(String label) {
          return tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: find.bySemanticsLabel(label),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
        }

        await pumpSelected(0);
        final scheme = schemeOf();
        final activePill = capsuleNavSelectedPillColor(scheme, isDark: false);
        final activeIcon = capsuleNavActiveIconColor(scheme);
        final inactiveIcon = capsuleNavInactiveIconColor(scheme, isDark: false);

        expect(chromeOf('Home').color, activePill);
        expect(chromeOf('Home').borderRadius, BorderRadius.circular(14));
        expect(tester.widget<Icon>(find.byIcon(Icons.home)).color, activeIcon);
        expect(chromeOf('Search').color, Colors.transparent);
        expect(chromeOf('Favs').color, Colors.transparent);
        expect(chromeOf('Menu').color, Colors.transparent);
        expect(chromeOf('Sell').color, Colors.transparent);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.search)).color,
          inactiveIcon,
        );

        for (final (index, label, selectedIcon) in const [
          (1, 'Search', Icons.search),
          (3, 'Favs', Icons.favorite),
          (4, 'Menu', Icons.menu),
        ]) {
          await pumpSelected(index);
          expect(
            chromeOf(label).color,
            activePill,
            reason: '$label must use the same selected pill as Home',
          );
          expect(
            chromeOf(label).borderRadius,
            BorderRadius.circular(kCapsuleNavSelectedChromeRadius),
          );
          expect(
            tester.widget<Icon>(find.byIcon(selectedIcon)).color,
            activeIcon,
            reason: '$label must use the same selected icon tint as Home',
          );
          expect(chromeOf('Sell').color, Colors.transparent);
          expect(
            find.byKey(const ValueKey('search-overlay-probe')),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets('Create asset stays 34px, untinted, without a selected pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: FloatingCapsuleNav(
              selectedIndex: 2,
              onDestinationSelected: (_) {},
              destinations: const [
                CapsuleNavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                CapsuleNavDestination(
                  icon: Icons.search,
                  selectedIcon: Icons.search,
                  label: 'Search',
                ),
                CapsuleNavDestination(
                  assetIcon: 'assets/icons/icon_plus.png',
                  label: 'Sell',
                  isEmphasized: true,
                ),
                CapsuleNavDestination(
                  icon: Icons.favorite_border,
                  selectedIcon: Icons.favorite,
                  label: 'Favs',
                ),
                CapsuleNavDestination(
                  icon: Icons.menu,
                  selectedIcon: Icons.menu,
                  label: 'Menu',
                ),
              ],
            ),
          ),
        ),
      );

      final create = tester.widget<Image>(
        find.byKey(kCapsuleNavCreateAssetKey),
      );
      expect(create.width, kCapsuleNavCreateAssetSize);
      expect(create.height, kCapsuleNavCreateAssetSize);
      expect(create.color, isNull);
      expect(create.colorBlendMode, isNull);
      final sellChrome =
          tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: find.bySemanticsLabel('Sell'),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(sellChrome.color, Colors.transparent);
    });

    testWidgets('renders the emphasized destination with a bigger icon than a '
        'non-emphasized one', (tester) async {
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

      final regular = tester.widget<Icon>(find.byIcon(Icons.directions_car));
      final emphasized = tester.widget<Icon>(
        find.byIcon(Icons.add_circle_outline),
      );
      expect(
        (emphasized.size ?? 0) > (regular.size ?? 0),
        isTrue,
        reason: 'Emphasized destination should render a larger icon',
      );
    });
  });
}
