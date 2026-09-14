import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/seller_analytics_summary.dart';
import '../utils/statistics_formatters.dart';

class StatisticsSummaryMetrics extends StatelessWidget {
  const StatisticsSummaryMetrics({super.key, required this.summary});

  final SellerAnalyticsSummary summary;

  static const Key viewsKey = ValueKey<String>('statistics_metric_views');
  static const Key favoritesKey = ValueKey<String>(
    'statistics_metric_favorites',
  );
  static const Key inquiriesKey = ValueKey<String>(
    'statistics_metric_inquiries',
  );
  static const Key conversionKey = ValueKey<String>(
    'statistics_metric_conversion',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.softCardShadow(scheme),
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: AppTheme.softCardBorderColor(scheme)),
        ),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.softCardGroupedGradient(scheme),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    _MetricCell(
                      key: viewsKey,
                      label: l10n.statisticsMetricViews,
                      value: '${summary.periodViews}',
                    ),
                    _MetricCell(
                      key: favoritesKey,
                      label: l10n.statisticsMetricFavorites,
                      value: '${summary.currentFavorites}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricCell(
                      key: inquiriesKey,
                      label: l10n.statisticsMetricInquiries,
                      value: '${summary.periodInquiries}',
                    ),
                    _MetricCell(
                      key: conversionKey,
                      label: l10n.statisticsMetricConversion,
                      value: formatStatisticsConversion(
                        summary.conversionPercent,
                        l10n.statisticsValueUnavailable,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: scheme.outline.withValues(
                    alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.06,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      _InventoryCell(
                        label: l10n.statisticsActiveListings,
                        value: '${summary.activeCount}',
                      ),
                      _InventoryCell(
                        label: l10n.statisticsSoldListings,
                        value: '${summary.soldCount}',
                      ),
                    ],
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

class _MetricCell extends StatelessWidget {
  const _MetricCell({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Semantics(
        label: '$label $value',
        child: Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryCell extends StatelessWidget {
  const _InventoryCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Semantics(
        label: '$label $value',
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label  ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              TextSpan(
                text: value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
