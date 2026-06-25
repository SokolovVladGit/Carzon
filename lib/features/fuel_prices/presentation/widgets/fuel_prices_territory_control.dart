import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../cubit/fuel_prices_cubit.dart';

/// Premium browser-style territory tabs that connect visually to the board below.
class FuelPricesTerritoryControl extends StatelessWidget {
  const FuelPricesTerritoryControl({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.connectToBoard,
  });

  final FuelPricesTerritory selected;
  final ValueChanged<FuelPricesTerritory> onChanged;
  final bool connectToBoard;

  static const Key moldovaTabKey = ValueKey<String>('fuel_prices_tab_moldova');
  static const Key pmrTabKey = ValueKey<String>('fuel_prices_tab_pmr');

  static const double trackRadius = 18;
  static const double _tabTopRadius = 14;
  static const double _tabHeight = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: connectToBoard
            ? Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(
                    alpha: isDark ? 0.1 : 0.12,
                  ),
                ),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5, 5, 5, connectToBoard ? 0 : 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _TerritoryTab(
                key: moldovaTabKey,
                label: l10n.fuelPricesTerritoryMoldova,
                selected: selected == FuelPricesTerritory.moldova,
                onTap: () => onChanged(FuelPricesTerritory.moldova),
                theme: theme,
                scheme: scheme,
                isDark: isDark,
                connectToBoard: connectToBoard,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _TerritoryTab(
                key: pmrTabKey,
                label: l10n.fuelPricesTerritoryPmr,
                selected: selected == FuelPricesTerritory.pmr,
                onTap: () => onChanged(FuelPricesTerritory.pmr),
                theme: theme,
                scheme: scheme,
                isDark: isDark,
                connectToBoard: connectToBoard,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Surface fill for the active tab when connected to the board below.
  static Color activeTabFill(ColorScheme scheme, bool isDark) {
    if (isDark) {
      return Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.08),
        scheme.surfaceContainerHigh,
      );
    }
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.028),
      scheme.surface,
    );
  }
}

class _TerritoryTab extends StatelessWidget {
  const _TerritoryTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
    required this.scheme,
    required this.isDark,
    required this.connectToBoard,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool isDark;
  final bool connectToBoard;

  @override
  Widget build(BuildContext context) {
    final topRadius = BorderRadius.vertical(
      top: Radius.circular(FuelPricesTerritoryControl._tabTopRadius),
    );
    final closedRadius = BorderRadius.circular(
      FuelPricesTerritoryControl._tabTopRadius - 2,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: connectToBoard ? topRadius : closedRadius,
          splashColor: scheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
          highlightColor: scheme.primary.withValues(alpha: isDark ? 0.04 : 0.03),
          child: Ink(
            height: FuelPricesTerritoryControl._tabHeight,
            decoration: BoxDecoration(
              color: selected && connectToBoard
                  ? FuelPricesTerritoryControl.activeTabFill(scheme, isDark)
                  : selected && !connectToBoard
                  ? Color.alphaBlend(
                      scheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                      scheme.surfaceContainerHighest,
                    )
                  : Colors.transparent,
              borderRadius: selected && connectToBoard
                  ? topRadius
                  : closedRadius,
              border: selected && connectToBoard
                  ? Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(
                          alpha: isDark ? 0.2 : 0.24,
                        ),
                      ),
                      left: BorderSide(
                        color: scheme.outlineVariant.withValues(
                          alpha: isDark ? 0.2 : 0.24,
                        ),
                      ),
                      right: BorderSide(
                        color: scheme.outlineVariant.withValues(
                          alpha: isDark ? 0.2 : 0.24,
                        ),
                      ),
                    )
                  : null,
              boxShadow: selected && !isDark && connectToBoard
                  ? [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.035),
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: selected
                      ? theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.08,
                          height: 1.18,
                          color: scheme.onSurface.withValues(
                            alpha: isDark ? 0.96 : 0.94,
                          ),
                        )
                      : theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.04,
                          height: 1.18,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: isDark ? 0.7 : 0.66,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
