import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../domain/entities/seller_analytics_daily_point.dart';
import 'statistics_surface.dart';
import 'statistics_views_sparkline.dart';

/// Unframed chart used inside the hero surface.
class StatisticsChartCard extends StatelessWidget {
  const StatisticsChartCard({
    super.key,
    required this.points,
    required this.semanticLabel,
    this.height = StatisticsLayout.chartPlotHeight,
  });

  final List<SellerAnalyticsDailyPoint> points;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return StatisticsViewsSparkline(
      points: points,
      semanticLabel: semanticLabel,
      localeName: context.l10n.localeName,
      height: height,
    );
  }
}
