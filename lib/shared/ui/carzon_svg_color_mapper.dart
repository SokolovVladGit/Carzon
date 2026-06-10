import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared Carzon SVG brand colors and dark-mode letter remapping.
class CarzonSvgColors {
  CarzonSvgColors._();

  static const Color originalDarkFill = Color(0xFF0D1824);
  static const Color blueAccent = Color(0xFF0067FF);
  static const Color darkModeTextReplacement = Color(0xFFEAF0F7);
}

/// Remaps only [CarzonSvgColors.originalDarkFill] during SVG parsing.
class CarzonLogoDarkTextColorMapper extends ColorMapper {
  const CarzonLogoDarkTextColorMapper([
    this.replacement = CarzonSvgColors.darkModeTextReplacement,
  ]);

  final Color replacement;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == CarzonSvgColors.originalDarkFill) {
      return replacement;
    }
    return color;
  }
}
