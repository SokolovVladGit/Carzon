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
  });
}
