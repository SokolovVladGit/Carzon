import 'package:carzon/core/theme/app_theme.dart';
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
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.svgAssetPath,
  });

  final String label;

  /// Shown when [svgAssetPath] is null or fails to decode.
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? svgAssetPath;

  /// Dominant silhouette for at-a-glance recognition on phones.
  static const double _iconSize = 29;

  /// Slightly wide for long Cyrillic labels (e.g. «Универсал», «Минивэн»).
  static const double _chipWidth = 84;
  static const double _chipHeight = 58;
  static const double _cornerRadius = 16;

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

    final Color borderColor = AppTheme.chipBorder(scheme, selected: isSelected);

    final borderWidth = isSelected ? 1.15 : 1.0;
    final radius = BorderRadius.circular(_cornerRadius);

    final List<BoxShadow> elevationShadow = isDark
        ? const []
        : _lightElevation(scheme);

    final inner = ExcludeSemantics(
      child: SizedBox(
        width: _chipWidth,
        height: _chipHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: _iconSize,
                height: _iconSize,
                child: _chipGlyph(
                  assetPath: svgAssetPath,
                  fallbackIcon: icon,
                  fg: fg,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.05,
                  letterSpacing: 0.06,
                ),
              ),
            ],
          ),
        ),
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
              child: inner,
            ),
          ),
        ),
      ),
    );
  }
}

/// Faces silhouette leftward like other feed body icons (see `sedan`/`pickup` SVG source).
bool _mirrorCategorySvgHorizontally(String? assetPath) {
  if (assetPath == null) return false;
  return assetPath.endsWith('sedan.svg') || assetPath.endsWith('pickup.svg');
}

Widget _chipGlyph({
  required String? assetPath,
  required IconData fallbackIcon,
  required Color fg,
}) {
  const size = CategoryChip._iconSize;
  final path = assetPath;
  final mirror = _mirrorCategorySvgHorizontally(path);
  Widget glyph;
  if (path != null) {
    glyph = SvgPicture.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      errorBuilder: (context, error, _) =>
          Icon(fallbackIcon, color: fg, size: size),
    );
  } else {
    glyph = Icon(fallbackIcon, color: fg, size: size);
  }

  if (mirror) {
    return Transform.flip(flipX: true, child: glyph);
  }
  return glyph;
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
