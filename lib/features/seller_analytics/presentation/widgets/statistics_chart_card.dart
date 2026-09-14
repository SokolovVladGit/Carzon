import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/seller_analytics_daily_point.dart';
import 'statistics_views_sparkline.dart';

class StatisticsChartCard extends StatelessWidget {
  const StatisticsChartCard({
    super.key,
    required this.points,
    required this.semanticLabel,
    this.height = 112,
  });

  final List<SellerAnalyticsDailyPoint> points;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: StatisticsViewsSparkline(
              points: points,
              semanticLabel: semanticLabel,
              height: height,
            ),
          ),
        ),
      ),
    );
  }
}
