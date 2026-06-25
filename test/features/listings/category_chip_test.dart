import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/listings/presentation/widgets/category_chip.dart';
import 'package:carzon/features/listings/presentation/widgets/listings_brand_filter_row.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/brands/brand_logo_glyph.dart';
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
    expect(icon.color!.a, greaterThan(0.84));
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

  testWidgets(
    'CategoryChip All chip selected in light uses neutral icon tint',
    (tester) async {
      const allBodiesAsset = 'assets/categories/svg/all_bodies.svg';
      final scheme = AppTheme.light().colorScheme;

      await tester.pumpWidget(
        _chipHarness(
          theme: AppTheme.light(),
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

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final expected = AppTheme.discoveryClearChipIconColor(
        scheme,
        selected: true,
      );
      expect(svg.colorFilter, ColorFilter.mode(expected, BlendMode.srcIn));
      expect(expected, isNot(scheme.primary.withValues(alpha: 0.86)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CategoryChip All chip unselected in dark applies tinted SVG for contrast',
    (tester) async {
      const allBodiesAsset = 'assets/categories/svg/all_bodies.svg';

      await tester.pumpWidget(
        _chipHarness(
          theme: AppTheme.dark(),
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

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CategoryChip vehicle SVG in dark uses neutral inactive body-type tint',
    (tester) async {
      final scheme = AppTheme.dark().colorScheme;
      await tester.pumpWidget(
        _chipHarness(
          theme: AppTheme.dark(),
          child: CategoryChip(
            chipId: 'sedan',
            label: 'Седан',
            icon: Icons.directions_car_outlined,
            isSelected: false,
            onTap: () {},
            svgAssetPath: 'assets/categories/svg/sedan.svg',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final bodyTint = AppTheme.discoveryBodyTypeIconColor(
        scheme,
        selected: false,
      );
      final selectedTint = AppTheme.discoveryBodyTypeIconColor(
        scheme,
        selected: true,
      );
      expect(
        svg.colorFilter,
        ColorFilter.mode(bodyTint, BlendMode.srcIn),
      );
      expect(bodyTint, AppTheme.discoveryClearChipIconColor(scheme, selected: false));
      expect(bodyTint.b, lessThan(selectedTint.b));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CategoryChip vehicle SVG in dark selected uses accent body-type tint',
    (tester) async {
      final scheme = AppTheme.dark().colorScheme;
      await tester.pumpWidget(
        _chipHarness(
          theme: AppTheme.dark(),
          child: CategoryChip(
            chipId: 'suv',
            label: 'SUV',
            icon: Icons.directions_car_outlined,
            isSelected: true,
            onTap: () {},
            svgAssetPath: 'assets/categories/svg/suv.svg',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final selectedTint = AppTheme.discoveryBodyTypeIconColor(
        scheme,
        selected: true,
      );
      expect(
        svg.colorFilter,
        ColorFilter.mode(selectedTint, BlendMode.srcIn),
      );
      expect(selectedTint.b, greaterThan(
        AppTheme.discoveryBodyTypeIconColor(scheme, selected: false).b,
      ));
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

  testWidgets(
    'ListingsBrandFilterRow all-brands chip tints SVG in dark mode',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListingsBrandFilterRow(
              currentMake: null,
              onBrandSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svgs = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
      expect(svgs, isNotEmpty);
      expect(svgs.first.colorFilter, isNotNull);
      expect(find.byKey(brandLogoDarkWellKey), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ListingsBrandFilterRow all-brands chip selected in light uses neutral icon',
    (tester) async {
      final scheme = AppTheme.light().colorScheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListingsBrandFilterRow(
              currentMake: null,
              onBrandSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svgs = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
      expect(svgs, isNotEmpty);
      final expected = AppTheme.discoveryClearChipIconColor(
        scheme,
        selected: true,
      );
      expect(svgs.first.colorFilter, ColorFilter.mode(expected, BlendMode.srcIn));
      expect(expected, isNot(scheme.primary.withValues(alpha: 0.86)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ListingsBrandFilterRow dark inactive brand uses blue-graphite surface',
    (tester) async {
      final scheme = AppTheme.dark().colorScheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListingsBrandFilterRow(
              currentMake: 'BMW',
              onBrandSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final materials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(ListingsBrandFilterRow),
          matching: find.byType(Material),
        ),
      );
      expect(materials.length, greaterThan(2));
      expect(
        materials.first.color,
        AppTheme.discoveryClearChipFill(scheme, selected: false),
      );
      expect(materials.elementAt(1).color, AppTheme.discoveryBrandChipInactiveFill(scheme));
      expect(materials.elementAt(5).color, AppTheme.selectedChipFill(scheme));
    },
  );

  testWidgets(
    'ListingsBrandFilterRow light inactive brand keeps white surface',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListingsBrandFilterRow(
              currentMake: 'BMW',
              onBrandSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final materials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(ListingsBrandFilterRow),
          matching: find.byType(Material),
        ),
      );
      expect(materials.elementAt(1).color, Colors.white);
    },
  );

  testWidgets(
    'ListingsBrandFilterRow dark brand tiles use neutral InkWell splash',
    (tester) async {
      final scheme = AppTheme.dark().colorScheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListingsBrandFilterRow(
              currentMake: null,
              onBrandSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = tester.widgetList<InkWell>(
        find.descendant(
          of: find.byType(ListingsBrandFilterRow),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWells, isNotEmpty);
      for (final inkWell in inkWells) {
        expect(inkWell.splashColor, scheme.onSurface.withValues(alpha: 0.048));
        expect(
          inkWell.highlightColor,
          scheme.onSurface.withValues(alpha: 0.026),
        );
      }
    },
  );

  testWidgets(
    'ListingsBrandFilterRow dark inactive BMW uses porcelain backplate',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListingsBrandFilterRow(
              currentMake: 'Toyota',
              onBrandSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoFeedLightBackplateKey), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ListingsBrandFilterRow dark selected BMW keeps selected fill and pill',
    (tester) async {
      final scheme = AppTheme.dark().colorScheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListingsBrandFilterRow(
              currentMake: 'BMW',
              onBrandSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectedSemantics = tester.widgetList<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.selected == true &&
              widget.properties.button == true,
        ),
      );
      expect(selectedSemantics.length, 1);

      final materials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(ListingsBrandFilterRow),
          matching: find.byType(Material),
        ),
      );
      expect(
        materials.where((m) => m.color == AppTheme.selectedChipFill(scheme)),
        isNotEmpty,
      );
      expect(
        materials.where(
          (m) => m.color == AppTheme.discoveryBrandChipInactiveFill(scheme),
        ),
        isNotEmpty,
      );
    },
  );
}
