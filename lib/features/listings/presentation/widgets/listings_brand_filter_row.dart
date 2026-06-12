import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/brands/brand_icon_resolver.dart';
import '../../../../shared/brands/brand_logo_glyph.dart';
import '../../domain/catalog/listing_brands.dart';

/// Horizontal brand-logo quick filter rendered under the search/filter row.
class ListingsBrandFilterRow extends StatelessWidget {
  const ListingsBrandFilterRow({
    super.key,
    required this.currentMake,
    required this.onBrandSelected,
  });

  final String? currentMake;
  final ValueChanged<String?> onBrandSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 24, 8),
        itemCount: kListingBrandFeedQuickFilterCatalog.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _BrandTile.all(
              selected: listingBrandFeedQuickFilterAllSelected(currentMake),
              onTap: () => onBrandSelected(null),
            );
          }
          final brand = kListingBrandFeedQuickFilterCatalog[index - 1];
          return _BrandTile.brand(
            make: brand,
            selected: listingBrandFeedQuickFilterIsSelected(currentMake, brand),
            onTap: () => onBrandSelected(brand),
          );
        },
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile._({
    required this.selected,
    required this.onTap,
    required this.semanticsLabel,
    required this.assetPath,
    required this.fallbackIcon,
    this.monogram,
    this.logoOpticalScale = 1.0,
    this.allBrandsAssetPath,
  });

  factory _BrandTile.all({
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _BrandTile._(
      selected: selected,
      onTap: onTap,
      semanticsLabel: null,
      assetPath: null,
      fallbackIcon: null,
      allBrandsAssetPath: _allBrandsAsset,
    );
  }

  factory _BrandTile.brand({
    required String make,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final resolvedPath = getBrandIconPath(make);
    final useMonogram = listingBrandFeedQuickFilterShouldUseMonogram(make);
    return _BrandTile._(
      selected: selected,
      onTap: onTap,
      semanticsLabel: make,
      assetPath: useMonogram ? null : resolvedPath,
      fallbackIcon: null,
      monogram: useMonogram ? listingBrandFeedQuickFilterMonogram(make) : null,
      logoOpticalScale: useMonogram
          ? 1.0
          : listingBrandFeedQuickFilterLogoScale(make),
    );
  }

  final bool selected;
  final VoidCallback onTap;
  final String? semanticsLabel;
  final String? assetPath;
  final IconData? fallbackIcon;
  final String? monogram;
  final double logoOpticalScale;
  final String? allBrandsAssetPath;

  static const String _allBrandsAsset = 'assets/categories/svg/all_brands.svg';

  static const double _size = 54;
  static const double _logoSize = 34;
  static const double _allBrandsIconSize = 38;
  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final bg = selected
        ? (isDark
              ? AppTheme.selectedChipFill(scheme)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.11),
                  Colors.white,
                ))
        : (isDark ? AppTheme.unselectedChipFill(scheme) : Colors.white);
    final borderColor = selected
        ? AppTheme.chipBorder(scheme, selected: true)
        : (isDark
              ? scheme.outline.withValues(alpha: 0.28)
              : scheme.outlineVariant.withValues(alpha: 0.42));
    final borderWidth = selected ? 2.0 : 1.0;
    final shadow = BoxShadow(
      color: selected
          ? scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12)
          : scheme.shadow.withValues(alpha: isDark ? 0.16 : 0.025),
      blurRadius: selected ? 12 : 6,
      spreadRadius: selected ? 0.5 : 0,
      offset: Offset(0, selected ? 3 : 2),
    );

    final label = semanticsLabel != null
        ? l10n.brandFilterBrandSemantics(semanticsLabel!)
        : l10n.brandFilterAllSemantics;

    Widget glyph;
    if (assetPath != null) {
      glyph = BrandLogoGlyph(
        assetPath: assetPath!,
        size: _logoSize * logoOpticalScale,
      );
    } else if (monogram != null) {
      glyph = _BrandMonogramMark(monogram: monogram!, selected: selected);
    } else if (allBrandsAssetPath != null) {
      glyph = SvgPicture.asset(
        allBrandsAssetPath!,
        width: _allBrandsIconSize,
        height: _allBrandsIconSize,
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            SizedBox(width: _allBrandsIconSize, height: _allBrandsIconSize),
      );
    } else if (fallbackIcon != null) {
      glyph = Icon(fallbackIcon, size: _logoSize, color: scheme.primary);
    } else {
      glyph = const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      container: true,
      child: Tooltip(
        message: semanticsLabel ?? l10n.brandFilterAllSemantics,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [shadow],
          ),
          child: Material(
            color: bg,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius),
              side: BorderSide(color: borderColor, width: borderWidth),
            ),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      child: glyph,
                    ),
                    if (selected)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? scheme.surface : Colors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMonogramMark extends StatelessWidget {
  const _BrandMonogramMark({required this.monogram, required this.selected});

  final String monogram;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final ring = scheme.outline.withValues(alpha: isDark ? 0.38 : 0.38);
    final fill = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.05),
      isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
    );
    final textColor = AppTheme.chipForeground(scheme, selected: selected);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: ring),
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: Text(
            monogram,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.6,
              color: textColor,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
