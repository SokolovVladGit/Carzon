import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Visual role for exclusive filter choices (currency / region / listing type).
enum ListingsFilterSegmentedControlVariant {
  currency,
  region,
  listingType,
}

/// One option in [ListingsFilterSegmentedControl].
class ListingsFilterSegmentEntry<T> {
  const ListingsFilterSegmentEntry({
    required this.value,
    required this.label,
    this.icon,
    this.secondaryLabel,
    this.isNeutralOption = false,
    this.semanticsLabel,
  });

  final T value;
  final Widget label;

  /// Optional icon (region, listing type).
  final IconData? icon;

  /// Sub-caption (e.g. ISO code under a currency symbol).
  final String? secondaryLabel;

  /// Softer styling for “any / all / both” options.
  final bool isNeutralOption;

  /// Spoken label for accessibility when [label] is symbolic.
  final String? semanticsLabel;
}

/// Exclusive single-choice control with semantic visual variants.
class ListingsFilterSegmentedControl<T> extends StatelessWidget {
  const ListingsFilterSegmentedControl({
    super.key,
    required this.variant,
    required this.value,
    required this.onChanged,
    required this.entries,
    this.minHeight = 44,
  });

  final ListingsFilterSegmentedControlVariant variant;
  final T value;
  final ValueChanged<T> onChanged;
  final List<ListingsFilterSegmentEntry<T>> entries;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ListingsFilterSegmentedControlVariant.currency =>
        _CurrencyChoiceRow<T>(
          value: value,
          onChanged: onChanged,
          entries: entries,
        ),
      ListingsFilterSegmentedControlVariant.region =>
        _RegionChoiceGroup<T>(
          value: value,
          onChanged: onChanged,
          entries: entries,
        ),
      ListingsFilterSegmentedControlVariant.listingType =>
        _ListingTypeChoiceRow<T>(
          value: value,
          onChanged: onChanged,
          entries: entries,
        ),
    };
  }
}

// Fixed outer heights — selected state must not alter layout metrics.
const double _kCurrencyTileHeight = 72;
const double _kRegionTileHeight = 88;
const double _kListingTypeTileHeight = 86;
const double _kCurrencyPrimarySlotHeight = 30;
const double _kCurrencySecondarySlotHeight = 15;
const double _kRegionLabelSlotHeight = 34;
const double _kListingTypeLabelSlotHeight = 22;
const double _kListingTypeIconSize = 32;

// ---------------------------------------------------------------------------
// Shared editorial choice surface
// ---------------------------------------------------------------------------

BoxDecoration _filterChoiceDecoration(
  ColorScheme scheme, {
  required bool selected,
  required bool neutral,
  double radius = 14,
  bool softChrome = false,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: selected
        ? AppTheme.filterChoiceSelectedFill(scheme, neutral: neutral)
        : AppTheme.filterChoiceUnselectedFill(scheme),
    border: Border.all(
      color: AppTheme.filterChoiceBorder(
        scheme,
        selected: selected,
        neutral: neutral,
        soft: softChrome,
      ),
      width: AppTheme.filterChoiceBorderWidth(
        selected: selected,
        soft: softChrome,
      ),
    ),
  );
}

Widget _filterChoiceInkWell({
  required BorderRadius borderRadius,
  required ColorScheme scheme,
  required VoidCallback onTap,
  required Widget child,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      splashColor: scheme.onSurface.withValues(alpha: 0.038),
      highlightColor: scheme.onSurface.withValues(alpha: 0.018),
      child: child,
    ),
  );
}

Widget _mutedIconAnchor({
  required ThemeData theme,
  required IconData icon,
  required bool selected,
  double size = _kListingTypeIconSize,
}) {
  final scheme = theme.colorScheme;
  final light = theme.brightness == Brightness.light;

  return SizedBox(
    width: size,
    height: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected
            ? Color.alphaBlend(
                scheme.onSurface.withValues(alpha: light ? 0.05 : 0.08),
                light ? scheme.surface : scheme.surfaceContainerHigh,
              )
            : Color.alphaBlend(
                scheme.outlineVariant.withValues(alpha: light ? 0.06 : 0.10),
                light ? scheme.surface : scheme.surfaceContainerLow,
              ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(
            alpha: selected
                ? (light ? 0.28 : 0.34)
                : (light ? 0.18 : 0.24),
          ),
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: selected
            ? scheme.onSurface.withValues(alpha: light ? 0.82 : 0.88)
            : scheme.onSurfaceVariant.withValues(alpha: light ? 0.62 : 0.72),
      ),
    ),
  );
}

Widget _regionIconGlyph({
  required ThemeData theme,
  required IconData icon,
  required bool selected,
}) {
  final scheme = theme.colorScheme;
  final light = theme.brightness == Brightness.light;

  return SizedBox(
    width: 20,
    height: 20,
    child: Center(
      child: Icon(
        icon,
        size: 13,
        color: selected
            ? scheme.onSurfaceVariant.withValues(alpha: light ? 0.66 : 0.74)
            : scheme.onSurfaceVariant.withValues(alpha: light ? 0.44 : 0.54),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Currency — equal tile row, strong symbol hierarchy
// ---------------------------------------------------------------------------

class _CurrencyChoiceRow<T> extends StatelessWidget {
  const _CurrencyChoiceRow({
    required this.value,
    required this.onChanged,
    required this.entries,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<ListingsFilterSegmentEntry<T>> entries;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _CurrencyTile<T>(
                entry: entries[i],
                selected: entries[i].value == value,
                onTap: () => onChanged(entries[i].value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrencyTile<T> extends StatelessWidget {
  const _CurrencyTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final ListingsFilterSegmentEntry<T> entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(14);
    final neutral = entry.isNeutralOption;

    return Semantics(
      button: true,
      selected: selected,
      label: entry.semanticsLabel,
      child: SizedBox(
        height: _kCurrencyTileHeight,
        child: _filterChoiceInkWell(
          borderRadius: radius,
          scheme: scheme,
          onTap: onTap,
          child: Ink(
            decoration: _filterChoiceDecoration(
              scheme,
              selected: selected,
              neutral: neutral,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
              child: neutral
                  ? _CurrencyNeutralContent(
                      theme: theme,
                      scheme: scheme,
                      selected: selected,
                      label: entry.label,
                    )
                  : _CurrencySymbolContent(
                      theme: theme,
                      scheme: scheme,
                      selected: selected,
                      label: entry.label,
                      secondaryLabel: entry.secondaryLabel,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyNeutralContent extends StatelessWidget {
  const _CurrencyNeutralContent({
    required this.theme,
    required this.scheme,
    required this.selected,
    required this.label,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final bool selected;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final light = theme.brightness == Brightness.light;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: _kCurrencyPrimarySlotHeight,
          child: Center(
            child: DefaultTextStyle(
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.08,
                height: 1.05,
                color: selected
                    ? scheme.onSurface.withValues(alpha: 0.88)
                    : scheme.onSurfaceVariant.withValues(
                        alpha: light ? 0.72 : 0.78,
                      ),
              ),
              textAlign: TextAlign.center,
              child: label,
            ),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(height: _kCurrencySecondarySlotHeight),
      ],
    );
  }
}

class _CurrencySymbolContent extends StatelessWidget {
  const _CurrencySymbolContent({
    required this.theme,
    required this.scheme,
    required this.selected,
    required this.label,
    this.secondaryLabel,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final bool selected;
  final Widget label;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final light = theme.brightness == Brightness.light;
    final primaryColor = selected
        ? scheme.onSurface.withValues(alpha: 0.96)
        : scheme.onSurface.withValues(alpha: light ? 0.86 : 0.90);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: _kCurrencyPrimarySlotHeight,
          child: Center(
            child: DefaultTextStyle(
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.35,
                height: 1.0,
                color: primaryColor,
              ),
              child: label,
            ),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: _kCurrencySecondarySlotHeight,
          child: secondaryLabel == null
              ? null
              : Center(
                  child: Text(
                    secondaryLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.45,
                      height: 1.1,
                      color: selected
                          ? scheme.onSurfaceVariant.withValues(alpha: 0.78)
                          : scheme.onSurfaceVariant.withValues(
                              alpha: light ? 0.58 : 0.66,
                            ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Region — compact market tiles, readable multi-line labels
// ---------------------------------------------------------------------------

class _RegionChoiceGroup<T> extends StatelessWidget {
  const _RegionChoiceGroup({
    required this.value,
    required this.onChanged,
    required this.entries,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<ListingsFilterSegmentEntry<T>> entries;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _RegionTile<T>(
                entry: entries[i],
                selected: entries[i].value == value,
                onTap: () => onChanged(entries[i].value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RegionTile<T> extends StatelessWidget {
  const _RegionTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final ListingsFilterSegmentEntry<T> entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final radius = BorderRadius.circular(14);
    final neutral = entry.isNeutralOption;

    return Semantics(
      button: true,
      selected: selected,
      label: entry.semanticsLabel,
      child: SizedBox(
        height: _kRegionTileHeight,
        child: _filterChoiceInkWell(
          borderRadius: radius,
          scheme: scheme,
          onTap: onTap,
          child: Ink(
            decoration: _filterChoiceDecoration(
              scheme,
              selected: selected,
              neutral: neutral,
              softChrome: true,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (entry.icon != null)
                    _regionIconGlyph(
                      theme: theme,
                      icon: entry.icon!,
                      selected: selected,
                    ),
                  if (entry.icon != null) const SizedBox(height: 6),
                  SizedBox(
                    height: _kRegionLabelSlotHeight,
                    child: Center(
                      child: DefaultTextStyle(
                        style: theme.textTheme.labelSmall!.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.02,
                          height: 1.32,
                          fontSize: 11.5,
                          color: selected
                              ? scheme.onSurface.withValues(alpha: 0.92)
                              : scheme.onSurfaceVariant.withValues(
                                  alpha: light ? 0.76 : 0.82,
                                ),
                        ),
                        textAlign: TextAlign.center,
                        child: entry.label,
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Listing type — premium intent tiles (equal row, icon anchor + label)
// ---------------------------------------------------------------------------

class _ListingTypeChoiceRow<T> extends StatelessWidget {
  const _ListingTypeChoiceRow({
    required this.value,
    required this.onChanged,
    required this.entries,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<ListingsFilterSegmentEntry<T>> entries;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _ListingTypeTile<T>(
                entry: entries[i],
                selected: entries[i].value == value,
                onTap: () => onChanged(entries[i].value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListingTypeTile<T> extends StatelessWidget {
  const _ListingTypeTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final ListingsFilterSegmentEntry<T> entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final radius = BorderRadius.circular(14);
    final neutral = entry.isNeutralOption;

    return Semantics(
      button: true,
      selected: selected,
      label: entry.semanticsLabel,
      child: SizedBox(
        height: _kListingTypeTileHeight,
        child: _filterChoiceInkWell(
          borderRadius: radius,
          scheme: scheme,
          onTap: onTap,
          child: Ink(
            decoration: _filterChoiceDecoration(
              scheme,
              selected: selected,
              neutral: neutral,
              softChrome: true,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 11, 6, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (entry.icon != null)
                    _mutedIconAnchor(
                      theme: theme,
                      icon: entry.icon!,
                      selected: selected,
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: _kListingTypeLabelSlotHeight,
                    child: Center(
                      child: DefaultTextStyle(
                        style: theme.textTheme.labelMedium!.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: selected ? -0.02 : 0.01,
                          height: 1.2,
                          color: selected
                              ? scheme.onSurface.withValues(alpha: 0.94)
                              : scheme.onSurfaceVariant.withValues(
                                  alpha: light ? 0.74 : 0.80,
                                ),
                        ),
                        textAlign: TextAlign.center,
                        child: entry.label,
                      ),
                    ),
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

/// Fixed outer height for each filter choice variant (layout-stable tests).
@visibleForTesting
double filterChoiceVariantOuterHeight(
  ListingsFilterSegmentedControlVariant variant,
) {
  return switch (variant) {
    ListingsFilterSegmentedControlVariant.currency => _kCurrencyTileHeight,
    ListingsFilterSegmentedControlVariant.region => _kRegionTileHeight,
    ListingsFilterSegmentedControlVariant.listingType => _kListingTypeTileHeight,
  };
}
