import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'carzon_svg_color_mapper.dart';

/// Carzon horizontal wordmark from [assets/icons/carzon_logo.svg].
///
/// Light mode uses the original SVG colors. In dark mode, only the dark
/// letter fill (#0D1824) is remapped to a soft light tone; blue accent
/// (#0067FF) and white details are preserved.
class CarzonLogo extends StatelessWidget {
  const CarzonLogo({
    super.key,
    this.height = 18,
    this.width,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Carzon',
    this.adaptToBrightness = true,
    this.darkModeTextColor = CarzonSvgColors.darkModeTextReplacement,
  });

  static const String assetPath = 'assets/icons/carzon_logo.svg';

  /// Original dark letter fill in the SVG source.
  static const Color originalDarkFill = CarzonSvgColors.originalDarkFill;

  final double height;
  final double? width;
  final BoxFit fit;
  final String semanticLabel;
  final bool adaptToBrightness;
  final Color darkModeTextColor;

  @override
  Widget build(BuildContext context) {
    final isDark =
        adaptToBrightness && Theme.of(context).brightness == Brightness.dark;
    final colorMapper = isDark
        ? CarzonLogoDarkTextColorMapper(darkModeTextColor)
        : null;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SvgPicture.asset(
          assetPath,
          height: height,
          width: width,
          fit: fit,
          colorMapper: colorMapper,
        ),
      ),
    );
  }
}

