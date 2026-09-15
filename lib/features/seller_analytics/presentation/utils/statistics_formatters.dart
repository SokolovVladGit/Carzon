import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Conservative conversion display. Null / non-finite → [unavailable].
///
/// Integers stay whole (`12%`). One decimal only when it carries information
/// (`4.2%`). Never forced two-decimal formatting.
String formatStatisticsConversion(double? value, String unavailable) {
  if (value == null || !value.isFinite) return unavailable;
  final clamped = value < 0 ? 0.0 : value;
  final tenths = (clamped * 10).round();
  if (tenths % 10 == 0) {
    return '${tenths ~/ 10}%';
  }
  return '${(tenths / 10).toStringAsFixed(1)}%';
}

/// Compact locale-aware chart tick, e.g. `1 Sep` / `1 sept.`.
String formatStatisticsChartDate(DateTime date, String localeName) {
  return DateFormat('d MMM', localeName).format(date);
}

/// Zero-based plot scale. [plotMax] includes visual headroom above [dataMax].
class StatisticsViewsChartScale {
  const StatisticsViewsChartScale({
    required this.dataMax,
    required this.plotMax,
  });

  factory StatisticsViewsChartScale.fromViews(Iterable<int> views) {
    var dataMax = 0;
    for (final value in views) {
      if (value > dataMax) dataMax = value;
    }
    return StatisticsViewsChartScale(
      dataMax: dataMax,
      plotMax: dataMax == 0 ? 1 : dataMax * 1.12,
    );
  }

  final int dataMax;
  final double plotMax;

  /// Maps [views] onto the plot. Zero is [bottomY]; [plotMax] is [topY].
  double yFor(num views, {required double topY, required double bottomY}) {
    final t = (views / plotMax).clamp(0.0, 1.0);
    return bottomY - t * (bottomY - topY);
  }
}

/// First / middle / last for short series; 4 ticks for 30/90 without overlap.
List<int> statisticsChartLabelIndices(int count) {
  if (count <= 0) return const [];
  if (count == 1) return const [0];
  final last = count - 1;
  if (count <= 8) {
    return _uniqueSorted(<int>[0, last ~/ 2, last]);
  }
  return _uniqueSorted(<int>[
    0,
    (last / 3).round(),
    (2 * last / 3).round(),
    last,
  ]);
}

/// Baseline micro-ticks: one per sample, denser than readable date labels.
List<int> statisticsChartMicroTickIndices(int count) {
  if (count <= 0) return const [];
  return [for (var i = 0; i < count; i++) i];
}

/// Fritsch–Carlson endpoint slopes for equally spaced samples.
///
/// Interval overshoot is prevented by [statisticsMonotoneSegmentSlopes].
List<double> statisticsMonotoneSlopes(List<double> y) {
  final n = y.length;
  if (n == 0) return const [];
  if (n == 1) return const [0];
  final d = <double>[for (var i = 0; i < n - 1; i++) y[i + 1] - y[i]];
  final m = List<double>.filled(n, 0);
  m[0] = d[0];
  m[n - 1] = d[n - 2];
  for (var i = 1; i < n - 1; i++) {
    if (d[i - 1] * d[i] <= 0) {
      m[i] = 0;
    } else {
      m[i] = (d[i - 1] + d[i]) / 2;
    }
  }
  for (var i = 0; i < n - 1; i++) {
    if (d[i] == 0) {
      m[i] = 0;
      m[i + 1] = 0;
    }
  }
  return m;
}

/// 3-circle-constrained slopes for segment `[i, i + 1]`.
///
/// Guarantees the Hermite cubic stays within the adjacent source values,
/// so the path cannot invent peaks or troughs between samples.
(double, double) statisticsMonotoneSegmentSlopes(List<double> y, int i) {
  final m = statisticsMonotoneSlopes(y);
  final d = y[i + 1] - y[i];
  if (d == 0) return (0.0, 0.0);
  var m0 = m[i];
  var m1 = m[i + 1];
  final a = m0 / d;
  final b = m1 / d;
  final ss = a * a + b * b;
  if (ss > 9) {
    final t = 3 / math.sqrt(ss);
    m0 = t * a * d;
    m1 = t * b * d;
  }
  return (m0, m1);
}

/// Monotone cubic sample at fractional index [t] in `[0, y.length - 1]`.
double statisticsMonotoneY(List<double> y, double t) {
  if (y.isEmpty) return 0;
  if (y.length == 1 || t <= 0) return y.first;
  if (t >= y.length - 1) return y.last;
  final i = t.floor().clamp(0, y.length - 2);
  final u = t - i;
  final segment = statisticsMonotoneSegmentSlopes(y, i);
  return _hermite(y[i], y[i + 1], segment.$1, segment.$2, u);
}

double _hermite(double y0, double y1, double m0, double m1, double t) {
  final t2 = t * t;
  final t3 = t2 * t;
  return (2 * t3 - 3 * t2 + 1) * y0 +
      (t3 - 2 * t2 + t) * m0 +
      (-2 * t3 + 3 * t2) * y1 +
      (t3 - t2) * m1;
}

List<int> _uniqueSorted(List<int> values) {
  final unique = values.toSet().toList()..sort();
  return unique;
}
