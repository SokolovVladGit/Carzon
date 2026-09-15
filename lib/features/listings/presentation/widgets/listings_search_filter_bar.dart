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
  });

  final TextEditingController searchCtrl;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final bool active;
  final bool bellBadge;

  /// Outer search pill — used to assert the typed-state end-cap is flush.
  static const Key searchFieldKey = Key('listingsSearchField');

  /// Leading magnifying-glass shown only while the query is empty.
  static const Key leadingSearchIconKey = Key('listingsSearchLeadingIcon');

  /// In-field Search action shown only while the query is non-empty.
  static const Key submitActionKey = Key('listingsSearchSubmitAction');

  static const Duration _chromeAnim = Duration(milliseconds: 180);

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
    const barHeight = 44.0;
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
              child: _ListingsSearchField(
                searchCtrl: searchCtrl,
                fill: fill,
                pillBorder: pillBorder,
                searchRadius: searchRadius,
                barHeight: barHeight,
                onSearchSubmitted: onSearchSubmitted,
                onClearSearch: onClearSearch,
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

class _ListingsSearchField extends StatefulWidget {
  const _ListingsSearchField({
    required this.searchCtrl,
    required this.fill,
    required this.pillBorder,
    required this.searchRadius,
    required this.barHeight,
    required this.onSearchSubmitted,
    required this.onClearSearch,
  });

  final TextEditingController searchCtrl;
  final Color fill;
  final Color pillBorder;
  final double searchRadius;
  final double barHeight;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;

  @override
  State<_ListingsSearchField> createState() => _ListingsSearchFieldState();
}

class _ListingsSearchFieldState extends State<_ListingsSearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'listingsSearchField');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _submitCurrentQuery() {
    FocusScope.of(context).unfocus();
    widget.onSearchSubmitted(widget.searchCtrl.text);
  }

  Widget _chromeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
        alignment: Alignment.centerRight,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final focused = _focusNode.hasFocus;

    return Material(
      key: ListingsSearchFilterBar.searchFieldKey,
      color: widget.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.searchRadius),
        side: BorderSide(
          color: focused
              ? scheme.primary.withValues(alpha: 0.5)
              : widget.pillBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.searchCtrl,
        builder: (context, value, _) {
          final hasQuery = value.text.isNotEmpty;
          return SizedBox(
            height: widget.barHeight,
            child: Row(
              children: [
                AnimatedSize(
                  duration: ListingsSearchFilterBar._chromeAnim,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: ListingsSearchFilterBar._chromeAnim,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.88,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: hasQuery
                        ? const SizedBox(
                            key: ValueKey<String>('listingsSearchLeadingPad'),
                            width: 14,
                            height: 44,
                          )
                        : SizedBox(
                            key: const ValueKey<String>(
                              'listingsSearchLeadingSlot',
                            ),
                            width: 44,
                            height: 44,
                            child: Icon(
                              CarzonIcons.search,
                              key: ListingsSearchFilterBar.leadingSearchIconKey,
                              size: 20,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: isDark ? 0.78 : 0.7,
                              ),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.searchCtrl,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: l10n.listingsSearchHint,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(
                          alpha: isDark ? 0.72 : 0.65,
                        ),
                      ),
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _submitCurrentQuery(),
                  ),
                ),
                AnimatedSize(
                  duration: ListingsSearchFilterBar._chromeAnim,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: ListingsSearchFilterBar._chromeAnim,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: _chromeTransition,
                    child: hasQuery
                        ? _SearchTypedSuffix(
                            key: const ValueKey<String>(
                              'listingsSearchTypedSuffix',
                            ),
                            onClear: widget.onClearSearch,
                            onSubmit: _submitCurrentQuery,
                            clearTooltip: l10n.listingsSearchClearTooltip,
                            submitTooltip: l10n.listingsSearchSubmitTooltip,
                            fill: widget.fill,
                            scheme: scheme,
                            isDark: isDark,
                          )
                        : const SizedBox(
                            key: ValueKey<String>('listingsSearchEmptyPad'),
                            width: 14,
                            height: 44,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchTypedSuffix extends StatelessWidget {
  const _SearchTypedSuffix({
    super.key,
    required this.onClear,
    required this.onSubmit,
    required this.clearTooltip,
    required this.submitTooltip,
    required this.fill,
    required this.scheme,
    required this.isDark,
  });

  final VoidCallback onClear;
  final VoidCallback onSubmit;
  final String clearTooltip;
  final String submitTooltip;
  final Color fill;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            CarzonIcons.close,
            size: 14,
            color: scheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.62 : 0.5,
            ),
          ),
          tooltip: clearTooltip,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: onClear,
        ),
        _SearchEndCap(
          onSubmit: onSubmit,
          submitTooltip: submitTooltip,
          fill: fill,
          scheme: scheme,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SearchEndCap extends StatelessWidget {
  const _SearchEndCap({
    required this.onSubmit,
    required this.submitTooltip,
    required this.fill,
    required this.scheme,
    required this.isDark,
  });

  final VoidCallback onSubmit;
  final String submitTooltip;
  final Color fill;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.editorialAccentColor(scheme);
    final capFill = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.14 : 0.06),
      fill,
    );
    return Tooltip(
      message: submitTooltip,
      child: Material(
        color: capFill,
        child: InkWell(
          key: ListingsSearchFilterBar.submitActionKey,
          onTap: onSubmit,
          child: SizedBox(
            width: 40,
            height: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: scheme.outline.withValues(
                      alpha: isDark ? 0.26 : 0.12,
                    ),
                    width: 0.5,
                  ),
                ),
              ),
              child: Icon(
                CarzonIcons.search,
                size: 18,
                color: isDark
                    ? accent
                    : scheme.onSurfaceVariant.withValues(alpha: 0.82),
              ),
            ),
          ),
        ),
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
