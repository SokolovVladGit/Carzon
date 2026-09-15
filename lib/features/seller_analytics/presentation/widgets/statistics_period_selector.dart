import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/seller_analytics_period.dart';

class StatisticsPeriodSelector extends StatelessWidget {
  const StatisticsPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.embedded = false,
  });

  final SellerAnalyticsPeriod selected;
  final ValueChanged<SellerAnalyticsPeriod> onChanged;
  final bool embedded;

  static const Key days7Key = ValueKey<String>('statistics_period_7');
  static const Key days30Key = ValueKey<String>('statistics_period_30');
  static const Key days90Key = ValueKey<String>('statistics_period_90');

  static const _periods = <SellerAnalyticsPeriod>[
    SellerAnalyticsPeriod.days7,
    SellerAnalyticsPeriod.days30,
    SellerAnalyticsPeriod.days90,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = scheme.brightness == Brightness.dark;
    final selectedIndex = _periods.indexOf(selected);
    final labels = <SellerAnalyticsPeriod, String>{
      SellerAnalyticsPeriod.days7: l10n.statisticsPeriod7,
      SellerAnalyticsPeriod.days30: l10n.statisticsPeriod30,
      SellerAnalyticsPeriod.days90: l10n.statisticsPeriod90,
    };
    final keys = <SellerAnalyticsPeriod, Key>{
      SellerAnalyticsPeriod.days7: days7Key,
      SellerAnalyticsPeriod.days30: days30Key,
      SellerAnalyticsPeriod.days90: days90Key,
    };
    final accent = AppTheme.editorialAccentColor(scheme);
    final track = scheme.surface.withValues(alpha: isDark ? 0.18 : 0.38);

    return Semantics(
      container: true,
      label: l10n.statisticsPeriodSelectorLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: embedded ? track : AppTheme.softCardSurface(scheme),
          borderRadius: BorderRadius.circular(18),
          border: embedded
              ? null
              : Border.all(
                  color: AppTheme.softCardBorderColor(
                    scheme,
                  ).withValues(alpha: 0.7),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = constraints.maxWidth / _periods.length;
              return SizedBox(
                height: 36,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      left: selectedIndex * segmentWidth,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              accent.withValues(alpha: isDark ? 0.28 : 0.12),
                              scheme.surface,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final period in _periods)
                          _PeriodSegment(
                            key: keys[period],
                            label: labels[period]!,
                            selected: selected == period,
                            onTap: () => onChanged(period),
                            theme: theme,
                            scheme: scheme,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
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
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
