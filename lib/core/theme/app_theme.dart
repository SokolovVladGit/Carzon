import 'package:flutter/material.dart';

/// Centralized light and dark theme for Carzon.
///
/// This is a foundation pass, not a final visual design. The goal is to
/// have a single, opinionated place where colors, typography hooks, and
/// core component themes live, so future styling is consistent across
/// the app without manual per-widget overrides.
///
/// Visual direction:
///   * calm, neutral automotive-marketplace surface
///   * single blue-ish primary accent
///   * Material 3 color scheme via `ColorScheme.fromSeed`
///   * readable contrast in both brightness modes
class AppTheme {
  AppTheme._();

  /// Seed color used to derive both light and dark color schemes.
  /// Kept private so the visual identity is owned by the theme layer.
  static const Color _seed = Color(0xFF1E88E5);

  /// Warm milk-white used as the light-theme base.
  ///
  /// M3's seed-derived `surface` is a slightly cool, blue-tinted
  /// off-white (a byproduct of the blue seed). The product direction
  /// is a clean automotive-marketplace white: we override `surface`
  /// with a warm off-white so the scaffold, app bars, and the home
  /// feed backdrop all read as milk-white without touching the
  /// `surfaceContainer*` tones — those stay as the soft warm greys
  /// that cards, search, filter, and nav controls live on, so the
  /// hierarchy `background (white) → controls (grey) → icons (muted)`
  /// is preserved.
  static const Color _lightSurface = Color(0xFFFFFCF7);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(surface: _lightSurface);
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final baseText = scheme.brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
    );
  }
}
