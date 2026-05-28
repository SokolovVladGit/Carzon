import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import 'brand_icon_resolver.dart';

/// Test hook: dark-mode logo well wrapper on listing/feed brand glyphs.
const Key brandLogoDarkWellKey = Key('brand_logo_dark_well');

/// Test hook: dark-mode monochrome SVG tint applied.
const Key brandLogoDarkTintKey = Key('brand_logo_dark_tint');

/// Renders a resolved brand SVG (or unknown-car fallback) with readable
/// contrast on dark surfaces.
///
/// Light mode keeps flat, untinted SVGs. Dark mode uses a soft well plus a
/// warm silver [ColorFilter] for known monochrome marks (Toyota, Honda, …).
/// Multi-color SVGs (BMW, Ferrari, …) keep native colors.
class BrandLogoGlyph extends StatelessWidget {
  const BrandLogoGlyph({
    super.key,
    required this.assetPath,
    required this.size,
    this.innerSizeFraction = 0.76,
    this.darkWell = true,
    this.tintMonochromeInDarkMode,
  });

  final String assetPath;
  final double size;

  /// Logo size inside the dark well, relative to [size].
  final double innerSizeFraction;

  /// When false, never draws the dark well (e.g. previews on light tiles).
  final bool darkWell;

  /// Dark-mode SVG tint override. `null` → tint only [isBrandIconMonochromeAssetPath].
  final bool? tintMonochromeInDarkMode;

  static const Color _fallbackSilver = Color(0xFF9E9E9E);

  bool _shouldTintInDark({required bool isDark, required bool isUnknown}) {
    if (!isDark || isUnknown || tintMonochromeInDarkMode == false) {
      return false;
    }
    return isBrandIconMonochromeAssetPath(assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final isUnknown = isBrandIconDefaultAssetPath(assetPath);
    final useWell = isDark && darkWell && !isUnknown;
    final applyTint = _shouldTintInDark(isDark: isDark, isUnknown: isUnknown);

    final glyphSize = useWell ? size * innerSizeFraction : size;
    final tintColor = applyTint ? AppTheme.brandLogoGlyphColor(scheme) : null;

    final Widget glyph = isUnknown
        ? Icon(
            Icons.directions_car,
            size: glyphSize,
            color: isDark
                ? AppTheme.brandLogoGlyphColor(scheme)
                : _fallbackSilver,
          )
        : _brandSvg(
            assetPath: assetPath,
            size: glyphSize,
            tintColor: tintColor,
          );

    if (!useWell) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: glyph),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        key: brandLogoDarkWellKey,
        decoration: AppTheme.brandLogoWellDecoration(scheme),
        child: Center(child: glyph),
      ),
    );
  }

  Widget _brandSvg({
    required String assetPath,
    required double size,
    required Color? tintColor,
  }) {
    Widget svg = SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: tintColor != null
          ? ColorFilter.mode(tintColor, BlendMode.srcIn)
          : null,
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
    );

    if (tintColor != null) {
      svg = KeyedSubtree(key: brandLogoDarkTintKey, child: svg);
    }

    return svg;
  }
}
