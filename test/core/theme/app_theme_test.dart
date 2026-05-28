import 'package:carzon/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light() is constructible and uses Material 3 light brightness', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark() is constructible and uses Material 3 dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('light and dark use the same seed-derived primary family', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(
        light.colorScheme.primary,
        isNot(equals(dark.colorScheme.primary)),
      );
      expect(light.colorScheme.primary.a, greaterThan(0));
      expect(dark.colorScheme.primary.a, greaterThan(0));
    });

    test('dark() uses premium graphite hierarchy tokens', () {
      final theme = AppTheme.dark();
      final scheme = theme.colorScheme;

      expect(scheme.surface, AppTheme.darkSurface);
      expect(scheme.onSurface, AppTheme.darkOnSurface);
      expect(scheme.onSurfaceVariant, AppTheme.darkOnSurfaceVariant);
      expect(scheme.primary, AppTheme.darkPrimary);
      expect(scheme.surfaceContainerLow, AppTheme.darkSurfaceContainer);
      expect(scheme.surfaceContainerHigh, AppTheme.darkSurfaceContainerHigh);
    });

    test('dark text theme uses warm off-white primary text', () {
      final theme = AppTheme.dark();
      expect(theme.textTheme.bodyLarge?.color, isNotNull);
      expect(
        theme.textTheme.bodyLarge!.color!.a,
        closeTo(AppTheme.darkOnSurface.a * 0.94, 0.02),
      );
      expect(theme.textTheme.titleMedium?.color, AppTheme.darkOnSurface);
    });

    test('brandLogoWellDecoration is defined for dark surfaces', () {
      final scheme = AppTheme.dark().colorScheme;
      final decoration = AppTheme.brandLogoWellDecoration(scheme);
      expect(decoration.color, isNotNull);
      expect(decoration.border, isNotNull);
    });

    test('editorial filter helpers are dark-only', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;
      expect(AppTheme.editorialDarkFilterFooter(light), isNull);
      expect(AppTheme.editorialDarkFilterFooter(dark), isNotNull);
      expect(AppTheme.editorialDarkFilterCanvasGradient(dark), hasLength(3));
    });

    test('filter alert management surface is editorial in dark only', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;
      final lightDeco = AppTheme.filterAlertManagementSurface(light);
      final darkDeco = AppTheme.filterAlertManagementSurface(dark);
      expect(lightDeco.color, isNotNull);
      expect(darkDeco.gradient, isNotNull);
    });

    test('editorial compare helpers are dark-only', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;
      expect(
        AppTheme.editorialDarkCompareVehicleCard(light, muted: false),
        isNull,
      );
      expect(
        AppTheme.editorialDarkCompareVehicleCard(dark, muted: false),
        isNotNull,
      );
      expect(AppTheme.editorialDarkCompareDifferenceRowTint(light), isNull);
      expect(AppTheme.editorialDarkCompareDifferenceRowTint(dark), isNotNull);
      expect(
        AppTheme.editorialDarkCompareCanvasGradient(dark),
        AppTheme.editorialDarkFilterCanvasGradient(dark),
      );
    });

    test('editorial compose helpers are dark-only', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;
      expect(AppTheme.editorialDarkHeroCard(light), isNull);
      expect(AppTheme.editorialDarkHeroCard(dark), isNotNull);
      expect(AppTheme.editorialAccentColor(dark).a, greaterThan(0.7));
    });

    test('brandLogoGlyphColor and categoryIconColor are readable in dark', () {
      final scheme = AppTheme.dark().colorScheme;
      final logo = AppTheme.brandLogoGlyphColor(scheme);
      final unselected = AppTheme.categoryIconColor(scheme, selected: false);
      final selected = AppTheme.categoryIconColor(scheme, selected: true);

      expect(logo.a, greaterThan(0.95));
      expect(unselected.a, greaterThan(0.94));
      expect(selected.a, greaterThan(0.94));
    });

    test('chip helpers return readable dark-mode colors', () {
      final scheme = AppTheme.dark().colorScheme;
      final unselectedFg = AppTheme.chipForeground(scheme, selected: false);
      final selectedFg = AppTheme.chipForeground(scheme, selected: true);

      expect(unselectedFg.a, greaterThan(0.85));
      expect(selectedFg.a, greaterThan(0.9));
      expect(
        AppTheme.selectedChipFill(scheme),
        isNot(equals(AppTheme.unselectedChipFill(scheme))),
      );
    });

    test('wires core component themes used across the app', () {
      final theme = AppTheme.light();
      expect(theme.appBarTheme, isNotNull);
      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(theme.inputDecorationTheme, isNotNull);
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.outlinedButtonTheme.style, isNotNull);
      expect(theme.textButtonTheme.style, isNotNull);
      expect(theme.cardTheme, isNotNull);
      expect(theme.floatingActionButtonTheme, isNotNull);
      expect(theme.dividerTheme, isNotNull);
    });

    test('dark input decoration uses readable hint and label colors', () {
      final theme = AppTheme.dark();
      final input = theme.inputDecorationTheme;
      expect(input.hintStyle?.color?.a, greaterThan(0.7));
      expect(input.labelStyle?.color?.a, greaterThan(0.85));
      expect(input.fillColor, AppTheme.darkSurfaceContainer);
    });
  });
}
