import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import 'brand_icon_resolver.dart';

/// Test hook: listing-card dark logo well wrapper.
const Key brandLogoDarkWellKey = Key('brand_logo_dark_well');

/// Test hook: discovery feed porcelain backplate for dark/complex logos.
const Key brandLogoFeedLightBackplateKey = Key('brand_logo_feed_light_backplate');

/// Test hook: dark-mode monochrome SVG tint applied.
const Key brandLogoDarkTintKey = Key('brand_logo_dark_tint');

/// Renders a resolved brand SVG (or unknown-car fallback) with readable
/// contrast on dark surfaces.
///
/// Light mode keeps flat, untinted SVGs. Listing cards use a soft well plus a
/// warm silver [ColorFilter] for known monochrome marks. Discovery feed chips
/// tint simple emblems or place all other natives on a porcelain backplate.
class BrandLogoGlyph extends StatelessWidget {
  const BrandLogoGlyph({
    super.key,
    required this.assetPath,
    required this.size,
    this.innerSizeFraction = 0.76,
    this.darkWell = true,
    this.tintMonochromeInDarkMode,
    this.darkTintColorOverride,
    this.discoveryFeedPresentation = false,
  });

  final String assetPath;
  final double size;

  /// Logo size inside the dark well, relative to [size].
  final double innerSizeFraction;

  /// When false, never draws the listing-card dark well.
  final bool darkWell;

  /// Dark-mode SVG tint override. `null` → tint only [isBrandIconMonochromeAssetPath].
  final bool? tintMonochromeInDarkMode;

  /// When set, replaces [AppTheme.brandLogoGlyphColor] for dark-mode SVG tinting.
  final Color? darkTintColorOverride;

  /// Discovery feed chip presentation (simple tint / porcelain backplate / bare native).
  final bool discoveryFeedPresentation;

  /// Shared readable plate for listing surfaces and brand filter chips.
  ///
  /// Dark mode: simple emblems get a restrained tint; complex marks (Audi, BMW,
  /// etc.) sit on the warm porcelain circular backplate. Light mode: flat native SVG.
  factory BrandLogoGlyph.readableOnDark({
    required BuildContext context,
    required String assetPath,
    required double size,
    double innerSizeFraction = 0.76,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return BrandLogoGlyph(
      assetPath: assetPath,
      size: size,
      innerSizeFraction: innerSizeFraction,
      discoveryFeedPresentation: isDark,
      darkTintColorOverride: isDark
          ? AppTheme.discoveryFeedBrandLogoColor(scheme)
          : null,
    );
  }

  static const Color _fallbackSilver = Color(0xFF9E9E9E);

  bool _shouldTintInDark({required bool isDark, required bool isUnknown}) {
    if (!isDark || isUnknown || tintMonochromeInDarkMode == false) {
      return false;
    }
    if (discoveryFeedPresentation) {
      return isBrandIconDiscoveryFeedSimpleTintAssetPath(assetPath);
    }
    return isBrandIconMonochromeAssetPath(assetPath);
  }

  bool _useListingWell({
    required bool isDark,
    required bool isUnknown,
    required bool applyTint,
  }) {
    return isDark && darkWell && !isUnknown && !discoveryFeedPresentation;
  }

  bool _useFeedLightBackplate({
    required bool isDark,
    required bool isUnknown,
    required bool applyTint,
  }) {
    return discoveryFeedPresentation &&
        isDark &&
        !isUnknown &&
        !applyTint &&
        isBrandIconDiscoveryFeedLightBackplateAssetPath(assetPath);
  }

  Color? _darkTintColor(ColorScheme scheme, {required bool applyTint}) {
    if (!applyTint) return null;
    return darkTintColorOverride ?? AppTheme.brandLogoGlyphColor(scheme);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final isUnknown = isBrandIconDefaultAssetPath(assetPath);
    final applyTint = _shouldTintInDark(isDark: isDark, isUnknown: isUnknown);
    final useListingWell = _useListingWell(
      isDark: isDark,
      isUnknown: isUnknown,
      applyTint: applyTint,
    );
    final useFeedLightBackplate = _useFeedLightBackplate(
      isDark: isDark,
      isUnknown: isUnknown,
      applyTint: applyTint,
    );
    final useWell = useListingWell || useFeedLightBackplate;

    final glyphSize = useWell
        ? size *
              (useFeedLightBackplate
                  ? brandIconDiscoveryFeedBackplateInnerFraction(assetPath)
                  : innerSizeFraction)
        : size;
    final tintColor = _darkTintColor(scheme, applyTint: applyTint);

    final Widget glyph = isUnknown
        ? Icon(
            Icons.directions_car,
            size: glyphSize,
            color: isDark
                ? (darkTintColorOverride ?? AppTheme.brandLogoGlyphColor(scheme))
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
        key: useFeedLightBackplate
            ? brandLogoFeedLightBackplateKey
            : brandLogoDarkWellKey,
        decoration: useFeedLightBackplate
            ? AppTheme.discoveryFeedBrandLogoBackplateDecoration(scheme)
            : AppTheme.brandLogoWellDecoration(scheme),
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
