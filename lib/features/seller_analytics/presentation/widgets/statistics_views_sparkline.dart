import 'package:flutter/material.dart';

import '../../domain/entities/seller_analytics_daily_point.dart';

class StatisticsViewsSparkline extends StatelessWidget {
  const StatisticsViewsSparkline({
    super.key,
    required this.points,
    required this.semanticLabel,
    this.height = 112,
  });

  final List<SellerAnalyticsDailyPoint> points;
  final String semanticLabel;
  final double height;

  static const Key chartKey = ValueKey<String>('statistics_views_sparkline');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: SizedBox(
        key: chartKey,
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: StatisticsViewsSparklinePainter(
            views: [for (final point in points) point.views],
            lineColor: scheme.primary,
            fillColor: scheme.primary.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.18 : 0.10,
            ),
            baselineColor: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class StatisticsViewsSparklinePainter extends CustomPainter {
  StatisticsViewsSparklinePainter({
    required this.views,
    required this.lineColor,
    required this.fillColor,
    required this.baselineColor,
  });

  final List<int> views;
  final Color lineColor;
  final Color fillColor;
  final Color baselineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final baselineY = size.height * 0.72;
    final baselinePaint = Paint()
      ..color = baselineColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      baselinePaint,
    );

    if (views.isEmpty) return;

    final minY = 10.0;
    final maxY = size.height - 10.0;
    final midY = (minY + maxY) / 2;
    var minViews = views.first;
    var maxViews = views.first;
    for (final value in views) {
      if (value < minViews) minViews = value;
      if (value > maxViews) maxViews = value;
    }
    final span = maxViews - minViews;

    Offset pointAt(int index) {
      final x = views.length == 1
          ? size.width / 2
          : size.width * (index / (views.length - 1));
      final y = span == 0
          ? midY
          : maxY - ((views[index] - minViews) / span) * (maxY - minY);
      return Offset(x, y);
    }

    if (views.length == 1) {
      final center = pointAt(0);
      canvas.drawCircle(center, 3.5, Paint()..color = lineColor);
      return;
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < views.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant StatisticsViewsSparklinePainter oldDelegate) {
    return oldDelegate.views != views ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.baselineColor != baselineColor;
  }
}
