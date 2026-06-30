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
  static const Color _lightSurface = Color(0xFFFFFCF7);

  /// Subtle warm surface steps for light mode (cards above canvas).
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFEFE);
  static const Color lightSurfaceContainerLow = Color(0xFFF8F5F0);
  static const Color lightSurfaceContainer = Color(0xFFF2EEE8);
  static const Color lightSurfaceContainerHigh = Color(0xFFEBE7E0);
  static const Color lightSurfaceContainerHighest = Color(0xFFE4E0D8);

  /// Premium dark graphite baseline (not pure black).
  static const Color darkSurface = Color(0xFF121417);
  static const Color darkSurfaceContainer = Color(0xFF1A1D21);
  static const Color darkSurfaceContainerHigh = Color(0xFF22262B);
  static const Color darkSurfaceContainerHighest = Color(0xFF2A3038);
  static const Color darkOnSurface = Color(0xFFF1F3F5);
  static const Color darkOnSurfaceVariant = Color(0xFFB4BAC3);
  static const Color darkOutline = Color(0xFF3A424C);
  static const Color darkOutlineVariant = Color(0xFF2E3640);
  static const Color darkPrimary = Color(0xFF4DA3E8);
  static const Color darkPrimaryContainer = Color(0xFF1E3A4A);
  /// Near-white foreground on primary blue surfaces in dark mode.
  static const Color darkOnPrimary = darkOnSurface;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: _lightSurface,
      surfaceContainerLowest: lightSurfaceContainerLowest,
      surfaceContainerLow: lightSurfaceContainerLow,
      surfaceContainer: lightSurfaceContainer,
      surfaceContainerHigh: lightSurfaceContainerHigh,
      surfaceContainerHighest: lightSurfaceContainerHighest,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    final scheme = baseScheme.copyWith(
      surface: darkSurface,
      onSurface: darkOnSurface,
      onSurfaceVariant: darkOnSurfaceVariant,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      surfaceContainerLow: darkSurfaceContainer,
      surfaceContainerLowest: darkSurfaceContainerHigh,
      surfaceContainerHighest: darkSurfaceContainerHighest,
      surfaceContainerHigh: darkSurfaceContainerHigh,
      inverseSurface: darkSurfaceContainerHighest,
      onInverseSurface: darkOnSurface,
    );

    return _base(scheme, textTheme: _darkTextTheme());
  }

  static TextTheme _darkTextTheme() {
    final base = Typography.whiteMountainView;
    TextStyle? s(TextStyle? style, Color color, {FontWeight? w}) =>
        style?.copyWith(color: color, fontWeight: w ?? style.fontWeight);

    return TextTheme(
      displayLarge: s(base.displayLarge, darkOnSurface, w: FontWeight.w700),
      displayMedium: s(base.displayMedium, darkOnSurface, w: FontWeight.w600),
      displaySmall: s(base.displaySmall, darkOnSurfaceVariant),
      headlineLarge: s(base.headlineLarge, darkOnSurface, w: FontWeight.w700),
      headlineMedium: s(base.headlineMedium, darkOnSurface, w: FontWeight.w600),
      headlineSmall: s(base.headlineSmall, darkOnSurface, w: FontWeight.w600),
      titleLarge: s(base.titleLarge, darkOnSurface, w: FontWeight.w700),
      titleMedium: s(base.titleMedium, darkOnSurface, w: FontWeight.w600),
      titleSmall: s(base.titleSmall, darkOnSurface, w: FontWeight.w600),
      bodyLarge: s(
        base.bodyLarge,
        darkOnSurface.withValues(alpha: 0.94),
        w: FontWeight.w500,
      ),
      bodyMedium: s(base.bodyMedium, darkOnSurface.withValues(alpha: 0.9)),
      bodySmall: s(
        base.bodySmall,
        darkOnSurfaceVariant.withValues(alpha: 0.88),
      ),
      labelLarge: s(
        base.labelLarge,
        darkOnSurface.withValues(alpha: 0.82),
        w: FontWeight.w500,
      ),
      labelMedium: s(
        base.labelMedium,
        darkOnSurfaceVariant.withValues(alpha: 0.9),
        w: FontWeight.w500,
      ),
      labelSmall: s(
        base.labelSmall,
        darkOnSurfaceVariant.withValues(alpha: 0.82),
        w: FontWeight.w500,
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme, {TextTheme? textTheme}) {
    final baseText =
        textTheme ??
        (scheme.brightness == Brightness.light
            ? Typography.blackMountainView
            : Typography.whiteMountainView);

    final fillColor = scheme.brightness == Brightness.light
        ? scheme.surfaceContainerLowest
        : scheme.surfaceContainerLow;

    final hintColor = scheme.brightness == Brightness.light
        ? scheme.onSurfaceVariant.withValues(alpha: 0.65)
        : scheme.onSurfaceVariant.withValues(alpha: 0.72);

    final labelColor = scheme.brightness == Brightness.light
        ? scheme.onSurfaceVariant
        : scheme.onSurfaceVariant.withValues(alpha: 0.9);

    final outlinedBorderColor = scheme.brightness == Brightness.light
        ? scheme.outline
        : scheme.outline.withValues(alpha: 0.55);

    final isDark = scheme.brightness == Brightness.dark;
    final snackBarSurface = isDark
        ? scheme.surfaceContainerHigh
        : Colors.white;
    final snackBarBorderColor = scheme.outlineVariant.withValues(
      alpha: isDark ? 0.35 : 0.22,
    );
    final snackBarContentColor = scheme.onSurface.withValues(
      alpha: isDark ? 0.94 : 0.92,
    );

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
        fillColor: fillColor,
        hintStyle: TextStyle(color: hintColor),
        labelStyle: TextStyle(color: labelColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: scheme.onPrimary,
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          side: BorderSide(color: outlinedBorderColor),
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide.none
              : BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.24),
                ),
        ),
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
        backgroundColor: snackBarSurface,
        elevation: isDark ? 6 : 4,
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: snackBarContentColor,
          height: 1.35,
        ),
        actionTextColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: snackBarBorderColor),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
    );
  }

  // ---------------------------------------------------------------------------
  // Hub pages, grouped cards, and editorial section surfaces.
  // ---------------------------------------------------------------------------

  /// Scaffold background for menu/settings-style hub pages.
  static Color showroomPageBackground(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.050),
        scheme.surface,
      );
    }
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.018),
      scheme.surface,
    );
  }

  /// Vertical canvas wash behind hub-style scroll bodies (menu, settings).
  static List<Color> showroomPageCanvasGradient(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      final top = Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.075),
        scheme.surfaceContainerLow,
      );
      final mid = Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.035),
        scheme.surface,
      );
      final bottom = Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.026),
        Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.080),
          scheme.surfaceContainerLow,
        ),
      );
      return [top, mid, bottom];
    }

    final top = Color.alphaBlend(
      scheme.surfaceTint.withValues(alpha: 0.008),
      scheme.surface,
    );
    final mid = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.032),
      scheme.surfaceContainerLowest,
    );
    final bottom = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.024),
      Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.070),
        scheme.surfaceContainerLow,
      ),
    );
    return [top, mid, bottom];
  }

  /// Soft grouped-card fill (menu rows, profile/settings sections).
  static Color softCardSurface(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.070),
        scheme.surfaceContainerLow,
      );
    }
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.026),
      scheme.surfaceContainerLowest,
    );
  }

  /// Border for soft editorial grouped cards.
  static Color softCardBorderColor(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return scheme.outline.withValues(alpha: 0.28);
    }
    return scheme.outlineVariant.withValues(alpha: 0.42);
  }

  /// Whisper shadow stack for grouped hub cards.
  static List<BoxShadow> softCardShadow(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.18),
          blurRadius: 26,
          offset: const Offset(0, 11),
        ),
      ];
    }
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.056),
        blurRadius: 26,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: scheme.primary.withValues(alpha: 0.026),
        blurRadius: 20,
        offset: const Offset(0, 5),
      ),
    ];
  }

  /// Diagonal wash for grouped hub cards (profile, menu sections).
  static LinearGradient softCardGroupedGradient(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final cardFill = softCardSurface(scheme);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          scheme.onSurface.withValues(alpha: isDark ? 0.028 : 0.012),
          cardFill,
        ),
        cardFill,
        Color.alphaBlend(
          scheme.primary.withValues(alpha: isDark ? 0.035 : 0.018),
          cardFill,
        ),
      ],
      stops: const [0, 0.55, 1],
    );
  }

  /// Editorial section/management card — brightness-aware.
  ///
  /// Dark mode delegates to [editorialDarkSectionCard]. Light mode uses a
  /// calm lifted surface with subtle border and whisper shadow.
  static BoxDecoration editorialSectionCard(
    ColorScheme scheme, {
    required double borderRadius,
  }) {
    final dark = editorialDarkSectionCard(scheme, borderRadius: borderRadius);
    if (dark != null) return dark;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: softCardBorderColor(scheme)),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.038),
            scheme.surfaceContainerLowest,
          ),
          Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.006),
            scheme.surfaceContainerLowest,
          ),
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.014),
            scheme.surfaceContainerLow,
          ),
        ],
        stops: const [0, 0.38, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.042),
          blurRadius: 22,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.018),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: -6,
        ),
      ],
    );
  }

  /// Selected discovery chip / tile fill (dark-aware).
  static Color selectedChipFill(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return scheme.surfaceContainer;
    }
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.22),
      scheme.surfaceContainerHigh,
    );
  }

  /// Unselected discovery chip / tile fill (dark-aware).
  static Color unselectedChipFill(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return scheme.surfaceContainerLowest;
    }
    return scheme.surfaceContainerHighest;
  }

  /// Readable icon/label color on chips (dark-aware).
  static Color chipForeground(ColorScheme scheme, {required bool selected}) {
    if (scheme.brightness == Brightness.light) {
      return selected
          ? scheme.onSurface.withValues(alpha: 0.88)
          : scheme.onSurfaceVariant.withValues(alpha: 0.82);
    }
    return categoryIconColor(scheme, selected: selected);
  }

  /// Body-type / discovery chip icon and label on dark surfaces.
  static Color categoryIconColor(ColorScheme scheme, {required bool selected}) {
    if (scheme.brightness == Brightness.light) {
      return selected
          ? scheme.onSurface.withValues(alpha: 0.88)
          : scheme.onSurfaceVariant.withValues(alpha: 0.82);
    }
    if (selected) {
      return Color.lerp(
        scheme.primary,
        scheme.onSurface,
        0.38,
      )!.withValues(alpha: 0.98);
    }
    return Color.lerp(
      scheme.onSurfaceVariant,
      scheme.onSurface,
      0.5,
    )!.withValues(alpha: 0.96);
  }

  /// Body-type vehicle silhouette tint for discovery feed chips (dark-aware).
  ///
  /// Dark mode follows the same state mapping as [discoveryClearChipIconColor]:
  /// neutral inactive icons, accent/blue only when selected.
  static Color discoveryBodyTypeIconColor(
    ColorScheme scheme, {
    required bool selected,
  }) {
    if (scheme.brightness == Brightness.light) {
      return categoryIconColor(scheme, selected: selected);
    }
    return discoveryClearChipIconColor(scheme, selected: selected);
  }

  /// Discovery feed reset/clear chip (All brands / All body types).
  static bool isDiscoveryClearChipId(String chipId) => chipId == 'all';

  static Color discoveryClearChipFill(
    ColorScheme scheme, {
    required bool selected,
  }) {
    if (scheme.brightness == Brightness.light) {
      return selected ? selectedChipFill(scheme) : unselectedChipFill(scheme);
    }
    if (selected) return selectedChipFill(scheme);
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.11),
      scheme.surfaceContainerHigh,
    );
  }

  /// Discovery feed inactive brand chip fill (dark only; brand row override).
  ///
  /// Editorial blue-graphite between flat [unselectedChipFill] and
  /// [selectedChipFill]. Quieter than [discoveryClearChipFill] so reset/all
  /// and selected states stay distinct.
  static Color discoveryBrandChipInactiveFill(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return unselectedChipFill(scheme);
    }
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.10),
      scheme.surfaceContainerHigh,
    );
  }

  /// Soft inactive brand chip outline (dark only).
  static Color discoveryBrandChipInactiveBorder(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return scheme.outlineVariant.withValues(alpha: 0.42);
    }
    return Color.lerp(scheme.primary, scheme.outline, 0.62)!
        .withValues(alpha: 0.22);
  }

  static Color discoveryClearChipBorder(
    ColorScheme scheme, {
    required bool selected,
  }) {
    if (scheme.brightness == Brightness.light) {
      return selected
          ? scheme.primary.withValues(alpha: 0.34)
          : scheme.outline.withValues(alpha: 0.18);
    }
    if (selected) return scheme.primary.withValues(alpha: 0.52);
    return Color.lerp(scheme.primary, scheme.outline, 0.48)!
        .withValues(alpha: 0.44);
  }

  static Color discoveryClearChipIconColor(
    ColorScheme scheme, {
    required bool selected,
  }) {
    if (scheme.brightness == Brightness.light) {
      return categoryIconColor(scheme, selected: selected);
    }
    if (selected) {
      return Color.lerp(scheme.primary, scheme.onSurface, 0.22)!
          .withValues(alpha: 0.98);
    }
    return Color.lerp(scheme.onSurfaceVariant, scheme.onSurface, 0.68)!
        .withValues(alpha: 0.94);
  }

  /// Muted silver tint for monochrome brand SVGs in dark mode.
  static Color brandLogoGlyphColor(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return scheme.onSurfaceVariant;
    }
    return Color.lerp(
      scheme.onSurfaceVariant,
      scheme.onSurface,
      0.62,
    )!.withValues(alpha: 0.98);
  }

  /// Restrained silver for simple discovery feed emblem tints (dark only).
  static Color discoveryFeedBrandLogoColor(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return brandLogoGlyphColor(scheme);
    }
    return Color.lerp(
      scheme.onSurfaceVariant,
      scheme.onSurface,
      0.72,
    )!.withValues(alpha: 0.90);
  }

  /// Chip border (dark-aware).
  static Color chipBorder(ColorScheme scheme, {required bool selected}) {
    if (scheme.brightness == Brightness.light) {
      return selected
          ? scheme.onSurface.withValues(alpha: 0.24)
          : scheme.outline.withValues(alpha: 0.15);
    }
    return selected
        ? scheme.primary.withValues(alpha: 0.45)
        : scheme.outline.withValues(alpha: 0.32);
  }

  /// Soft disc behind brand SVGs on dark surfaces.
  static BoxDecoration brandLogoWellDecoration(ColorScheme scheme) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.20),
        scheme.surfaceContainerHighest,
      ),
      border: Border.all(
        color: scheme.outline.withValues(alpha: 0.36),
        width: 0.75,
      ),
    );
  }

  /// Warm porcelain backplate for dark/complex discovery feed logos (dark only).
  static BoxDecoration discoveryFeedBrandLogoBackplateDecoration(
    ColorScheme scheme,
  ) {
    const porcelainCenter = Color(0xFFF5F3EF);
    const porcelainEdge = Color(0xFFE8EAED);
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          porcelainCenter.withValues(alpha: 0.94),
          porcelainEdge.withValues(alpha: 0.86),
        ],
        stops: const [0.58, 1.0],
      ),
      border: Border.all(
        color: Color.lerp(scheme.outline, const Color(0xFFD8D4CE), 0.45)!
            .withValues(alpha: 0.16),
        width: 0.5,
      ),
    );
  }

  /// Restrained blue-steel accent for editorial compose surfaces (dark).
  static Color editorialAccentColor(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return scheme.primary;
    }
    return Color.lerp(
      scheme.primary,
      scheme.onSurface,
      0.12,
    )!.withValues(alpha: 0.78);
  }

  /// Soft vertical wash for compact editorial utility modules.
  static LinearGradient editorialModuleAtmosphereWash(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.065),
            scheme.surfaceContainerHigh,
          ),
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.022),
            scheme.surfaceContainerLow,
          ),
          scheme.surfaceContainerLow,
        ],
        stops: const [0, 0.44, 1],
      );
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(scheme.primary.withValues(alpha: 0.042), scheme.surface),
        Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.014),
          scheme.surfaceContainerLowest,
        ),
        scheme.surface,
      ],
      stops: const [0, 0.48, 1],
    );
  }

  /// Faint radial highlight for the header area of editorial utility modules.
  static RadialGradient editorialModuleAtmosphereHighlight(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return RadialGradient(
      center: const Alignment(0, -0.9),
      radius: 1.08,
      colors: [
        scheme.primary.withValues(alpha: isDark ? 0.07 : 0.055),
        scheme.primary.withValues(alpha: isDark ? 0.018 : 0.012),
        Colors.transparent,
      ],
      stops: const [0, 0.42, 1],
    );
  }

  /// Create/edit listing hero card in dark mode. Null in light (callers keep light UI).
  static BoxDecoration? editorialDarkHeroCard(
    ColorScheme scheme, {
    double borderRadius = 24,
  }) {
    if (scheme.brightness == Brightness.light) return null;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.34)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.16),
            scheme.surfaceContainerHigh,
          ),
          Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.05),
            scheme.surfaceContainerLow,
          ),
          scheme.surface,
        ],
        stops: const [0, 0.55, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.07),
          blurRadius: 26,
          offset: const Offset(0, 10),
          spreadRadius: -8,
        ),
      ],
    );
  }

  /// Numbered section shell in dark mode. Null in light.
  static BoxDecoration? editorialDarkSectionCard(
    ColorScheme scheme, {
    required double borderRadius,
  }) {
    if (scheme.brightness == Brightness.light) return null;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: scheme.outline.withValues(alpha: 0.32)),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.10),
            scheme.surfaceContainerHigh,
          ),
          Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.04),
            scheme.surfaceContainerLow,
          ),
          scheme.surfaceContainerLow,
        ],
        stops: const [0, 0.22, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -6,
        ),
      ],
    );
  }

  /// Step index badge (`01`, `02`, …) in dark mode. Null in light.
  static BoxDecoration? editorialDarkStepBadge(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) return null;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      border: Border.all(
        color: editorialAccentColor(scheme).withValues(alpha: 0.42),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.18),
            scheme.surfaceContainerHigh,
          ),
          scheme.surfaceContainerLow,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 2),
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Photo upload outer frame in dark mode. Null in light.
  static BoxDecoration? editorialDarkPhotoFrame(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) return null;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: editorialAccentColor(scheme).withValues(alpha: 0.28),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.08),
            scheme.surfaceContainerHigh,
          ),
          scheme.surfaceContainerLow,
        ],
      ),
    );
  }

  /// Inner photo well (empty state) in dark mode.
  static BoxDecoration editorialDarkPhotoWell(
    ColorScheme scheme, {
    required bool hasPhoto,
  }) {
    if (hasPhoto) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
        color: scheme.surfaceContainerLow,
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: editorialAccentColor(scheme).withValues(alpha: 0.32),
        width: 1.1,
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.10),
            scheme.surfaceContainerHigh,
          ),
          Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.03),
            scheme.surfaceContainerLow,
          ),
        ],
      ),
    );
  }

  /// Focused input border for create/edit compose fields in dark mode.
  static Color editorialDarkFieldFocusBorder(ColorScheme scheme) {
    return editorialAccentColor(scheme).withValues(alpha: 0.62);
  }

  /// Filters page canvas gradient (dark only). Light callers use their own blend.
  static List<Color> editorialDarkFilterCanvasGradient(ColorScheme scheme) {
    final top = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.06),
      Color.alphaBlend(
        scheme.surfaceContainerLow.withValues(alpha: 0.65),
        scheme.surface,
      ),
    );
    final bottom = scheme.surface;
    return [top, Color.lerp(top, bottom, 0.65) ?? bottom, bottom];
  }

  /// Sticky filter footer bar in dark mode. Null in light.
  static BoxDecoration? editorialDarkFilterFooter(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) return null;
    return BoxDecoration(
      color: Color.alphaBlend(
        scheme.surfaceContainerHigh.withValues(alpha: 0.88),
        scheme.surface,
      ),
      border: Border(
        top: BorderSide(color: scheme.outline.withValues(alpha: 0.30)),
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, -10),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.20),
          blurRadius: 20,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }

  /// Compare page canvas gradient (dark). Same family as filters.
  static List<Color> editorialDarkCompareCanvasGradient(ColorScheme scheme) =>
      editorialDarkFilterCanvasGradient(scheme);

  /// Filter-alert / notification management cards.
  static BoxDecoration filterAlertManagementSurface(
    ColorScheme scheme, {
    double borderRadius = 16,
  }) {
    return editorialSectionCard(scheme, borderRadius: borderRadius);
  }

  /// Lifted vehicle column on the compare screen (dark). Null in light.
  static BoxDecoration? editorialDarkCompareVehicleCard(
    ColorScheme scheme, {
    required bool muted,
  }) {
    if (scheme.brightness == Brightness.light) return null;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: scheme.outline.withValues(alpha: muted ? 0.28 : 0.34),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(
            scheme.primary.withValues(alpha: muted ? 0.06 : 0.10),
            scheme.surfaceContainerHigh,
          ),
          scheme.surfaceContainerLow,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: muted ? 0.03 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
          spreadRadius: -4,
        ),
      ],
    );
  }

  /// Full-row tint when emphasizing differing spec rows (dark).
  static Color? editorialDarkCompareDifferenceRowTint(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) return null;
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.08),
      scheme.surfaceContainerLow,
    );
  }

  /// Inline highlight behind a differing value cell (dark).
  static Color editorialDarkCompareValueHighlight(
    ColorScheme scheme, {
    required bool emphasize,
  }) {
    if (scheme.brightness == Brightness.light) {
      return scheme.primary.withValues(alpha: emphasize ? 0.12 : 0.08);
    }
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: emphasize ? 0.22 : 0.14),
      scheme.surfaceContainerHigh,
    );
  }

  /// Discovery filter fields (browse / alert editor).
  static InputDecoration listingsFilterFieldDecoration(
    ThemeData theme, {
    required String label,
    String? hint,
    String? errorText,
  }) {
    final scheme = theme.colorScheme;
    final light = scheme.brightness == Brightness.light;
    final radius = BorderRadius.circular(14);
    final fillColor = light
        ? scheme.surface.withValues(alpha: 0.42)
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.05),
            scheme.surfaceContainerLow,
          );
    final enabledBorderColor = light
        ? scheme.outlineVariant.withValues(alpha: 0.22)
        : scheme.outline.withValues(alpha: 0.32);
    final focusBorderColor = light
        ? scheme.primary.withValues(alpha: 0.5)
        : editorialDarkFieldFocusBorder(scheme);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      isDense: true,
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: light ? 0.72 : 0.88),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: light ? 0.65 : 0.78),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: enabledBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: focusBorderColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.65)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter exclusive-choice tiles (currency / region / listing type).
  // Calm editorial selected state — avoids default primary-blue chip feel.
  // ---------------------------------------------------------------------------

  static Color filterChoiceUnselectedFill(ColorScheme scheme) {
    final light = scheme.brightness == Brightness.light;
    return light
        ? Color.alphaBlend(
            scheme.outlineVariant.withValues(alpha: 0.05),
            scheme.surface,
          )
        : Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.02),
            scheme.surfaceContainerLow,
          );
  }

  static Color filterChoiceSelectedFill(
    ColorScheme scheme, {
    bool neutral = false,
  }) {
    final light = scheme.brightness == Brightness.light;
    if (neutral) {
      return light
          ? Color.alphaBlend(
              scheme.onSurface.withValues(alpha: 0.035),
              scheme.surface,
            )
          : Color.alphaBlend(
              scheme.onSurface.withValues(alpha: 0.05),
              scheme.surfaceContainerLow,
            );
    }
    return light
        ? Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.05),
            Color.alphaBlend(
              scheme.surfaceContainerHighest.withValues(alpha: 0.28),
              scheme.surface,
            ),
          )
        : Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.07),
            scheme.surfaceContainerHigh,
          );
  }

  static Color filterChoiceBorder(
    ColorScheme scheme, {
    required bool selected,
    bool neutral = false,
    bool soft = false,
  }) {
    final light = scheme.brightness == Brightness.light;
    if (selected) {
      if (soft) {
        return scheme.onSurface.withValues(
          alpha: neutral
              ? (light ? 0.14 : 0.18)
              : (light ? 0.12 : 0.16),
        );
      }
      return scheme.onSurface.withValues(
        alpha: neutral
            ? (light ? 0.20 : 0.26)
            : (light ? 0.18 : 0.24),
      );
    }
    return scheme.outlineVariant.withValues(alpha: light ? 0.20 : 0.26);
  }

  static double filterChoiceBorderWidth({
    required bool selected,
    bool soft = false,
  }) {
    // Constant width keeps selected/unselected outer size identical.
    return 1.0;
  }

  static Color filterChoiceSelectedIndicator(
    ColorScheme scheme, {
    bool soft = false,
  }) {
    final light = scheme.brightness == Brightness.light;
    if (soft) {
      return scheme.onSurface.withValues(alpha: light ? 0.22 : 0.32);
    }
    return scheme.onSurface.withValues(alpha: light ? 0.32 : 0.44);
  }

  static List<BoxShadow>? filterChoiceSelectedShadow(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) return null;
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.045),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
