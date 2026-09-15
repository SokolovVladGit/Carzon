import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/seller_analytics_daily_point.dart';
import '../utils/statistics_formatters.dart';
import 'statistics_surface.dart';

class StatisticsViewsSparkline extends StatelessWidget {
  const StatisticsViewsSparkline({
    super.key,
    required this.points,
    required this.semanticLabel,
    required this.localeName,
    this.height = StatisticsLayout.chartPlotHeight,
  });

  final List<SellerAnalyticsDailyPoint> points;
  final String semanticLabel;
  final String localeName;
  final double height;

  static const Key chartKey = ValueKey<String>('statistics_views_sparkline');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final accent = AppTheme.editorialAccentColor(scheme);
    final isDark = scheme.brightness == Brightness.dark;
    final views = [for (final point in points) point.views];
    final scale = StatisticsViewsChartScale.fromViews(views);
    final indices = statisticsChartLabelIndices(points.length);
    final labels = [
      for (final index in indices)
        formatStatisticsChartDate(points[index].date, localeName),
    ];
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.74 : 0.68),
      fontWeight: FontWeight.w500,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final topLabel = scale.dataMax == 0 ? '' : '${scale.dataMax}';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: StatisticsLayout.yAxisWidth,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(topLabel, style: labelStyle),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: StatisticsLayout.chartAxisBand,
                  ),
                  child: Text('0', style: labelStyle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              key: chartKey,
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: StatisticsViewsSparklinePainter(
                  views: views,
                  xLabelIndices: indices,
                  xLabelTexts: labels,
                  microTickIndices: statisticsChartMicroTickIndices(
                    views.length,
                  ),
                  lineColor: accent.withValues(alpha: isDark ? 0.88 : 0.90),
                  fillColor: accent,
                  guideColor: scheme.outline.withValues(
                    alpha: isDark ? 0.14 : 0.045,
                  ),
                  tickColor: scheme.outline.withValues(
                    alpha: isDark ? 0.26 : 0.12,
                  ),
                  labelStyle: labelStyle ?? const TextStyle(fontSize: 11),
                  fillStrong: isDark ? 0.32 : 0.26,
                  axisBand: StatisticsLayout.chartAxisBand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatisticsViewsSparklinePainter extends CustomPainter {
  StatisticsViewsSparklinePainter({
    required this.views,
    required this.xLabelIndices,
    required this.xLabelTexts,
    required this.microTickIndices,
    required this.lineColor,
    required this.fillColor,
    required this.guideColor,
    required this.tickColor,
    required this.labelStyle,
    required this.fillStrong,
    this.axisBand = StatisticsLayout.chartAxisBand,
  });

  final List<int> views;
  final List<int> xLabelIndices;
  final List<String> xLabelTexts;
  final List<int> microTickIndices;
  final Color lineColor;
  final Color fillColor;
  final Color guideColor;
  final Color tickColor;
  final TextStyle labelStyle;
  final double fillStrong;
  final double axisBand;

  static const double _topPad = 4;
  static const double _tickHeight = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final topY = _topPad;
    final bottomY = size.height - axisBand;
    if (bottomY <= topY) return;
    final scale = StatisticsViewsChartScale.fromViews(views);

    final midPaint = Paint()
      ..color = guideColor
      ..strokeWidth = 0.7;
    canvas.drawLine(
      Offset(0, bottomY - 0.5 * (bottomY - topY)),
      Offset(size.width, bottomY - 0.5 * (bottomY - topY)),
      midPaint,
    );
    canvas.drawLine(Offset(0, bottomY), Offset(size.width, bottomY), midPaint);

    if (views.isEmpty) {
      _paintXLabels(canvas, size, bottomY);
      return;
    }

    Offset pointAt(int index) {
      final x = views.length == 1
          ? size.width / 2
          : size.width * (index / (views.length - 1));
      final y = scale.yFor(views[index], topY: topY, bottomY: bottomY);
      return Offset(x, y);
    }

    final last = views.length - 1;
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (final index in microTickIndices) {
      final x = last <= 0 ? size.width / 2 : size.width * (index / last);
      canvas.drawLine(
        Offset(x, bottomY),
        Offset(x, bottomY - _tickHeight),
        tickPaint,
      );
    }

    final pts = [for (var i = 0; i < views.length; i++) pointAt(i)];

    if (pts.length == 1) {
      canvas.drawCircle(pts.first, 2.0, Paint()..color = lineColor);
      _paintXLabels(canvas, size, bottomY);
      return;
    }

    final line = _monotoneLine(pts);
    var fillTop = pts.first.dy;
    for (final point in pts) {
      if (point.dy < fillTop) fillTop = point.dy;
    }
    final fill = Path.from(line)
      ..lineTo(pts.last.dx, bottomY)
      ..lineTo(pts.first.dx, bottomY)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor.withValues(alpha: fillStrong),
            fillColor.withValues(alpha: fillStrong * 0.42),
            fillColor.withValues(alpha: 0.0),
          ],
          stops: const [0, 0.38, 1],
        ).createShader(Rect.fromLTRB(0, fillTop, size.width, bottomY)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.85
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    _paintXLabels(canvas, size, bottomY);
  }

  void _paintXLabels(Canvas canvas, Size size, double baseline) {
    if (xLabelIndices.isEmpty || views.isEmpty) return;
    final last = views.length - 1;
    for (var i = 0; i < xLabelIndices.length; i++) {
      final index = xLabelIndices[i];
      final text = i < xLabelTexts.length ? xLabelTexts[i] : '';
      final x = last <= 0 ? size.width / 2 : size.width * (index / last);
      final painter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: size.width / 3);
      var left = x - painter.width / 2;
      if (i == 0) left = 0;
      if (i == xLabelIndices.length - 1) left = size.width - painter.width;
      left = left.clamp(0.0, size.width - painter.width);
      painter.paint(canvas, Offset(left, baseline + 2));
    }
  }

  static Path _monotoneLine(List<Offset> points) {
    final ys = [for (final point in points) point.dy];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final dx = points[i + 1].dx - points[i].dx;
      final segment = statisticsMonotoneSegmentSlopes(ys, i);
      path.cubicTo(
        points[i].dx + dx / 3,
        points[i].dy + segment.$1 / 3,
        points[i + 1].dx - dx / 3,
        points[i + 1].dy - segment.$2 / 3,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant StatisticsViewsSparklinePainter oldDelegate) {
    return oldDelegate.views != views ||
        oldDelegate.xLabelTexts != xLabelTexts ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.tickColor != tickColor;
  }
}
