import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/listings/presentation/utils/feed_home_body_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Body-type chip descriptor for the home feed row ([CategoryChipsRow]).
@immutable
class FeedBodyChipDescriptor {
  const FeedBodyChipDescriptor({
    required this.id,
    required this.label,
    required this.icon,
    this.svgAssetPath,
  });

  final String id;
  final String label;
  final IconData icon;

  /// When set, rendered with [SvgPicture.asset] instead of [icon].
  final String? svgAssetPath;
}

/// Feed body chip: premium monochrome tile with SVG or fallback icon.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.chipId,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.svgAssetPath,
  });

  /// Stable feed chip id (e.g. `all`, `sedan`, `wagon`) for optical scaling.
  final String chipId;
  final String label;

  /// Shown when [svgAssetPath] is null or fails to decode.
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? svgAssetPath;

  static const double _allBodiesIconSize = 42;

  static const double _normalChipSelectedPillWidth = 24;
  static const double _normalChipSelectedPillHeight = 3;
  static const double _normalChipSelectedPillBottomInset = 4;

  /// Fallback [IconData] size when SVG decode fails (vehicle + All chips).
  static const double _fallbackIconSize = 36;

  /// Width for wide vehicle silhouette SVGs; height follows asset aspect ratio.
  static const double _vehicleIconWidth = 56;

  /// Fixed layout slot for the icon row; decoupled from glyph render sizing.
  static const double _iconSlotHeight = 44;

  /// Fixed chip label size; must not track icon scaling.
  static const double _labelFontSize = 11;

  /// Slightly wide for long Cyrillic labels (e.g. «Универсал», «Минивэн»).
  static const double _chipWidth = 84;
  static const double _chipHeight = 58;
  static const double _cornerRadius = 16;

  static const double _chipHorizontalPadding = 5;

  static double get _iconSlotWidth => _chipWidth - (_chipHorizontalPadding * 2);

  @visibleForTesting
  static bool isAllBodyChip({
    required String chipId,
    required String? svgAssetPath,
  }) =>
      chipId == 'all' &&
      (svgAssetPath?.endsWith('all_bodies.svg') ?? false);

  @visibleForTesting
  static double get allIconSize => _allBodiesIconSize;

  @visibleForTesting
  static double get vehicleIconBaseWidth => _vehicleIconWidth;

  @visibleForTesting
  static double get iconBaseSize => _fallbackIconSize;

  @visibleForTesting
  static double get iconSlotWidth => _iconSlotWidth;

  @visibleForTesting
  static double get iconSlotHeight => _iconSlotHeight;

  @visibleForTesting
  static double get chipWidth => _chipWidth;

  @visibleForTesting
  static double get chipHeight => _chipHeight;

  @visibleForTesting
  static double get labelFontSize => _labelFontSize;

  List<BoxShadow> _lightElevation(ColorScheme scheme) {
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: isSelected ? 0.046 : 0.036),
        blurRadius: isSelected ? 20 : 17,
        spreadRadius: 0,
        offset: Offset(0, isSelected ? 6 : 5),
      ),
      BoxShadow(
        color: scheme.shadow.withValues(alpha: isSelected ? 0.092 : 0.068),
        blurRadius: isSelected ? 9 : 7,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color bg = isSelected
        ? AppTheme.selectedChipFill(scheme)
        : AppTheme.unselectedChipFill(scheme);

    final Color fg = AppTheme.categoryIconColor(scheme, selected: isSelected);

    final Color borderColor = isSelected
        ? (isDark
              ? scheme.primary.withValues(alpha: 0.48)
              : scheme.primary.withValues(alpha: 0.34))
        : AppTheme.chipBorder(scheme, selected: false);

    final borderWidth = isSelected ? 1.25 : 1.0;
    final radius = BorderRadius.circular(_cornerRadius);

    final List<BoxShadow> elevationShadow = isDark
        ? const []
        : _lightElevation(scheme);

    final isAllChip = chipId == 'all';
    final iconScale = listingBodyTypeQuickFilterIconScale(chipId);
    final vehicleRenderWidth = _vehicleIconWidth * iconScale;

    final chipGlyph = _chipGlyph(
      assetPath: svgAssetPath,
      fallbackIcon: icon,
      fg: fg,
      isAllChip: isAllChip,
      allBodiesIconSize: _allBodiesIconSize,
      fallbackIconSize: _fallbackIconSize,
      vehicleRenderWidth: vehicleRenderWidth,
    );

    final inner = ExcludeSemantics(
      child: SizedBox(
        width: _chipWidth,
        height: _chipHeight,
        child: Center(child: chipGlyph),
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: elevationShadow,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: scheme.onSurface.withValues(alpha: 0.048),
            highlightColor: scheme.onSurface.withValues(alpha: 0.026),
            child: Ink(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radius,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  inner,
                  if (isSelected)
                    _selectedBottomAccentPill(
                      scheme: scheme,
                      isDark: isDark,
                      width: _normalChipSelectedPillWidth,
                      height: _normalChipSelectedPillHeight,
                      bottomInset: _normalChipSelectedPillBottomInset,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _chipGlyph({
  required String? assetPath,
  required IconData fallbackIcon,
  required Color fg,
  required bool isAllChip,
  required double allBodiesIconSize,
  required double fallbackIconSize,
  required double vehicleRenderWidth,
}) {
  final path = assetPath;
  if (isAllChip) {
    if (path != null) {
      return SvgPicture.asset(
        path,
        width: allBodiesIconSize,
        height: allBodiesIconSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, _) =>
            Icon(fallbackIcon, color: fg, size: fallbackIconSize),
      );
    }
    return Icon(fallbackIcon, color: fg, size: fallbackIconSize);
  }

  if (path != null) {
    return SvgPicture.asset(
      path,
      width: vehicleRenderWidth,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      errorBuilder: (context, error, _) =>
          Icon(fallbackIcon, color: fg, size: fallbackIconSize),
    );
  }
  return Icon(fallbackIcon, color: fg, size: fallbackIconSize);
}

Positioned _selectedBottomAccentPill({
  required ColorScheme scheme,
  required bool isDark,
  required double width,
  required double height,
  required double bottomInset,
}) {
  return Positioned(
    bottom: bottomInset,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: scheme.primary.withValues(alpha: isDark ? 0.70 : 0.62),
        ),
      ),
    ),
  );
}

/// Horizontal scrollable row of body-type [CategoryChip]s.
class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<FeedBodyChipDescriptor> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Matches [_BrandFilterRow] horizontal gutter (20) and vertical air (8).
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            CategoryChip(
              chipId: categories[i].id,
              label: categories[i].label,
              isSelected: categories[i].id == selectedId,
              onTap: () => onSelected(categories[i].id),
              icon: categories[i].icon,
              svgAssetPath: categories[i].svgAssetPath,
            ),
          ],
        ],
      ),
    );
  }
}
