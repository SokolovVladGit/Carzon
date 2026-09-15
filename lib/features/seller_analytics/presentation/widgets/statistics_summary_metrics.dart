import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/seller_analytics_daily_point.dart';
import '../../domain/entities/seller_analytics_period.dart';
import '../../domain/entities/seller_analytics_summary.dart';
import '../utils/statistics_formatters.dart';
import 'statistics_chart_card.dart';
import 'statistics_inventory_snapshot.dart';
import 'statistics_period_selector.dart';
import 'statistics_surface.dart';

class StatisticsSummaryMetrics extends StatelessWidget {
  const StatisticsSummaryMetrics({
    super.key,
    required this.summary,
    required this.points,
    required this.chartSemanticLabel,
    required this.period,
    required this.onPeriodChanged,
    this.showInventoryTotal = false,
  });

  final SellerAnalyticsSummary summary;
  final List<SellerAnalyticsDailyPoint> points;
  final String chartSemanticLabel;
  final SellerAnalyticsPeriod period;
  final ValueChanged<SellerAnalyticsPeriod> onPeriodChanged;
  final bool showInventoryTotal;

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

    return StatisticsGroupedSurface(
      emphasized: true,
      padding: StatisticsLayout.modulePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatisticsPeriodSelector(
            selected: period,
            onChanged: onPeriodChanged,
            embedded: true,
          ),
          const SizedBox(height: 14),
          _HeroViews(
            key: viewsKey,
            label: l10n.statisticsMetricViews,
            value: '${summary.periodViews}',
          ),
          const SizedBox(height: 8),
          StatisticsChartCard(
            points: points,
            semanticLabel: chartSemanticLabel,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatisticsSupportMetric(
                  key: inquiriesKey,
                  label: l10n.statisticsMetricInquiries,
                  value: '${summary.periodInquiries}',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StatisticsSupportMetric(
                  key: conversionKey,
                  label: l10n.statisticsMetricConversion,
                  value: formatStatisticsConversion(
                    summary.conversionPercent,
                    l10n.statisticsValueUnavailable,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const StatisticsHairline(),
          const SizedBox(height: 16),
          StatisticsInventorySnapshot(
            favorites: summary.currentFavorites,
            activeCount: summary.activeCount,
            soldCount: summary.soldCount,
            showTotal: showInventoryTotal,
          ),
        ],
      ),
    );
  }
}

class _HeroViews extends StatelessWidget {
  const _HeroViews({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -1.8,
              height: 0.92,
              color: AppTheme.editorialAccentColor(scheme),
            ),
          ),
        ],
      ),
    );
  }
}
