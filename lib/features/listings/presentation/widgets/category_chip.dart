import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// UI-only body-style category descriptor used by [CategoryChipsRow].
///
/// Kept intentionally decoupled from the domain layer: the listing
/// entity has no `category` / `bodyType` field yet, so this struct
/// lives in the presentation layer only. When the backend dimension
/// is introduced, [id] will map 1:1 onto the future DB enum value.
@immutable
class UiCategory {
  const UiCategory({
    required this.id,
    required this.label,
    required this.assetPath,
  });

  final String id;
  final String label;

  /// SVG asset path under `assets/categories/svg/`. Resolved via
  /// [SvgPicture.asset]; missing assets render as an empty tile and
  /// are logged by `flutter_svg` without crashing the app.
  final String assetPath;
}

/// Default seed list used by the feed. Hard-coded on purpose: this is
/// the UI pass only and the set is small and stable. Once a `body_type`
/// column is added to `listings`, this list should be replaced by a
/// derived source keyed on that enum.
const List<UiCategory> defaultUiCategories = [
  UiCategory(
    id: 'all',
    label: 'Все',
    assetPath: 'assets/categories/svg/all.svg',
  ),
  UiCategory(
    id: 'sedan',
    label: 'Седан',
    assetPath: 'assets/categories/svg/sedan.svg',
  ),
  UiCategory(
    id: 'suv',
    label: 'SUV',
    assetPath: 'assets/categories/svg/suv.svg',
  ),
  UiCategory(
    id: 'hatch',
    label: 'Хэтчбек',
    assetPath: 'assets/categories/svg/hatch.svg',
  ),
  UiCategory(
    id: 'wagon',
    label: 'Универсал',
    assetPath: 'assets/categories/svg/wagon.svg',
  ),
];

/// Pill-shaped selectable chip: icon on the left, label on the right.
///
/// Intentionally does **not** wrap the icon in its own surface — the
/// icon sits directly on the chip background so the silhouette reads
/// as a single flat pill, matching the marketplace aesthetic.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;

  /// Icon widget. Typically an [SvgPicture.asset]; any widget works
  /// as long as it respects the ambient [IconTheme] color so the
  /// icon recolors with the chip state.
  final Widget icon;

  final bool isSelected;
  final VoidCallback onTap;

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Pass 1.9 aligns the chip with the brand-tile / search-pill
    // language used throughout the feed header:
    //   * inactive chip sits on a close-to-white / lifted dark
    //     surface with a hairline outline, so it reads as a clean
    //     control rather than a grey blob;
    //   * selected chip earns a whisper primary wash + a tinted
    //     hairline outline. No strong blue fill, no loud pill.
    final Color bg = isSelected
        ? (isDark
            ? scheme.primary.withValues(alpha: 0.14)
            : Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.05),
                Colors.white,
              ))
        : (isDark ? scheme.surfaceContainerHighest : Colors.white);
    final Color fg = isSelected
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.85);
    final Color borderColor = isSelected
        ? scheme.primary.withValues(alpha: isDark ? 0.5 : 0.32)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : scheme.outlineVariant.withValues(alpha: 0.45));

    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: isSelected,
          label: label,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: IconTheme.merge(
                    data: IconThemeData(color: fg, size: _iconSize),
                    child: icon,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrollable row of [CategoryChip]s.
///
/// The row is purely presentational: it renders whatever list of
/// [UiCategory] it is given and reports selection changes via
/// [onSelected]. State ownership stays with the caller (the feed
/// page) so selection survives header rebuilds.
class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<UiCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // The outer feed already provides a 20 px editorial gutter, so
      // horizontal padding here is 0 to avoid a double-indent; the
      // wrapping context is responsible for positioning the row.
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _CategoryChipFromUi(
              category: categories[i],
              isSelected: categories[i].id == selectedId,
              onTap: () => onSelected(categories[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Adapter that renders a [UiCategory] as a [CategoryChip]. Kept
/// private because callers work in [UiCategory] terms, not in raw
/// asset paths.
class _CategoryChipFromUi extends StatelessWidget {
  const _CategoryChipFromUi({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final UiCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CategoryChip(
      label: category.label,
      isSelected: isSelected,
      onTap: onTap,
      // `colorFilter` is driven by the ambient IconTheme color set
      // inside `CategoryChip`, so the SVG recolors with the chip
      // state without the asset needing to be themed.
      icon: Builder(
        builder: (context) {
          final color = IconTheme.of(context).color ??
              Theme.of(context).colorScheme.onSurfaceVariant;
          return SvgPicture.asset(
            category.assetPath,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            placeholderBuilder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
