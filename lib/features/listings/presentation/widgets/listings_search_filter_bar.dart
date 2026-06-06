import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/ui/carzon_icons.dart';
import 'filters/catalog_filter_alert_ui_constants.dart';

/// Pill-shaped search field next to a rounded filter button.
///
/// The widget is presentation-only: callers own search dispatching, filter
/// opening, and filter-alert state derivation.
class ListingsSearchFilterBar extends StatelessWidget {
  const ListingsSearchFilterBar({
    super.key,
    required this.searchCtrl,
    required this.onOpenFilters,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.active,
    required this.bellBadge,
    required this.savedNoDeliveryBadge,
  });

  final TextEditingController searchCtrl;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final bool active;
  final bool bellBadge;
  final bool savedNoDeliveryBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final pillBorder = isDark
        ? scheme.outline.withValues(alpha: 0.32)
        : scheme.outlineVariant.withValues(alpha: 0.45);
    const barHeight = 50.0;
    const searchRadius = 16.0;
    const filterRadius = 14.0;
    final searchShadow = BoxShadow(
      color: scheme.shadow.withValues(alpha: isDark ? 0.22 : 0.025),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
    final restingBg = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final bg = active
        ? (isDark
              ? AppTheme.selectedChipFill(scheme)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.14),
                  restingBg,
                ))
        : restingBg;
    final fg = active
        ? (isDark ? scheme.onSurface.withValues(alpha: 0.96) : scheme.primary)
        : AppTheme.chipForeground(scheme, selected: false);
    final border = active
        ? AppTheme.chipBorder(scheme, selected: true)
        : pillBorder;
    final badgeOutline = restingBg;
    final semanticsLabel = bellBadge
        ? '${l10n.listingsFiltersTooltip}. '
              '${l10n.catalogBrowseFilterBellFilterChipSemantics}'
        : savedNoDeliveryBadge
        ? '${l10n.listingsFiltersTooltip}. '
              '${l10n.catalogBrowseFilterBellSavedDeliveryUnavailableTooltip}'
        : l10n.listingsFiltersTooltip;

    return SizedBox(
      height: barHeight,
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(searchRadius),
                boxShadow: [searchShadow],
              ),
              child: TextField(
                controller: searchCtrl,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: l10n.listingsSearchHint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.72 : 0.65,
                    ),
                  ),
                  prefixIcon: Icon(
                    CarzonIcons.search,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.78 : 0.7,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchCtrl,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(CarzonIcons.close, size: 18),
                        tooltip: l10n.listingsSearchClearTooltip,
                        onPressed: onClearSearch,
                      );
                    },
                  ),
                  filled: true,
                  fillColor: fill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(searchRadius),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(searchRadius),
                    borderSide: BorderSide(color: pillBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(searchRadius),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                onSubmitted: onSearchSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: barHeight,
            width: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(filterRadius),
              boxShadow: [searchShadow],
            ),
            child: Material(
              color: bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(filterRadius),
                side: BorderSide(color: border, width: active ? 1.25 : 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Tooltip(
                message: l10n.listingsFiltersTooltip,
                child: InkWell(
                  onTap: onOpenFilters,
                  child: Semantics(
                    button: true,
                    label: semanticsLabel,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(CarzonIcons.filter, size: 20, color: fg),
                        if (active)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: _FilterFabCornerBadge(
                              background: scheme.primary,
                              outline: badgeOutline,
                              icon: Icons.check,
                              iconColor: scheme.onPrimary,
                              iconSize: 9,
                            ),
                          ),
                        if (bellBadge)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: _FilterFabCornerBadge(
                              ornamentKey: CatalogFilterAlertAccent
                                  .discoveryFilterFABAlertBellKey,
                              background: CatalogFilterAlertAccent.amber,
                              outline: badgeOutline,
                              icon: Icons.notifications,
                              iconColor: scheme.onPrimary,
                              iconSize: 9,
                            ),
                          )
                        else if (savedNoDeliveryBadge)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: _FilterFabCornerBadge(
                              ornamentKey: CatalogFilterAlertAccent
                                  .discoveryFilterFABSavedNoDeliveryBellKey,
                              background: Color.alphaBlend(
                                CatalogFilterAlertAccent.amber.withValues(
                                  alpha: 0.22,
                                ),
                                restingBg,
                              ),
                              outline: CatalogFilterAlertAccent.amber
                                  .withValues(alpha: 0.55),
                              icon: Icons.notifications,
                              iconColor: CatalogFilterAlertAccent.amber,
                              iconSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterFabCornerBadge extends StatelessWidget {
  const _FilterFabCornerBadge({
    this.ornamentKey,
    required this.background,
    required this.outline,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
  });

  final Key? ornamentKey;
  final Color background;
  final Color outline;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 16,
        height: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: outline, width: 1.25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2.5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              key: ornamentKey,
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
