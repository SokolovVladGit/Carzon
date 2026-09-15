import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import 'statistics_summary_metrics.dart';
import 'statistics_surface.dart';

class StatisticsInventorySnapshot extends StatelessWidget {
  const StatisticsInventorySnapshot({
    super.key,
    required this.activeCount,
    required this.soldCount,
    this.favorites,
    this.showTotal = false,
  });

  final int activeCount;
  final int soldCount;
  final int? favorites;
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cells = <Widget>[
      if (favorites != null)
        StatisticsSupportMetric(
          key: StatisticsSummaryMetrics.favoritesKey,
          label: l10n.statisticsMetricFavorites,
          value: '$favorites',
          wrapLabel: true,
        ),
      StatisticsSupportMetric(
        label: l10n.statisticsActiveListings,
        value: '$activeCount',
        wrapLabel: true,
      ),
      StatisticsSupportMetric(
        label: l10n.statisticsSoldListings,
        value: '$soldCount',
        wrapLabel: true,
      ),
      if (showTotal)
        StatisticsSupportMetric(
          label: l10n.statisticsInventoryTotal,
          value: '${activeCount + soldCount}',
          wrapLabel: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatisticsWhisperLabel(text: l10n.statisticsCurrentInventory),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: StatisticsTonalCell(child: cells[i])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
