import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/seller_analytics_period.dart';

class StatisticsPeriodSelector extends StatelessWidget {
  const StatisticsPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SellerAnalyticsPeriod selected;
  final ValueChanged<SellerAnalyticsPeriod> onChanged;

  static const Key days7Key = ValueKey<String>('statistics_period_7');
  static const Key days30Key = ValueKey<String>('statistics_period_30');
  static const Key days90Key = ValueKey<String>('statistics_period_90');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: l10n.statisticsPeriodSelectorLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.softCardSurface(scheme),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.softCardBorderColor(scheme)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _PeriodChip(
                key: days7Key,
                label: l10n.statisticsPeriod7,
                selected: selected == SellerAnalyticsPeriod.days7,
                onTap: () => onChanged(SellerAnalyticsPeriod.days7),
                theme: theme,
                scheme: scheme,
              ),
              _PeriodChip(
                key: days30Key,
                label: l10n.statisticsPeriod30,
                selected: selected == SellerAnalyticsPeriod.days30,
                onTap: () => onChanged(SellerAnalyticsPeriod.days30),
                theme: theme,
                scheme: scheme,
              ),
              _PeriodChip(
                key: days90Key,
                label: l10n.statisticsPeriod90,
                selected: selected == SellerAnalyticsPeriod.days90,
                onTap: () => onChanged(SellerAnalyticsPeriod.days90),
                theme: theme,
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: isDark ? 0.28 : 0.14),
                  scheme.surface,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
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
