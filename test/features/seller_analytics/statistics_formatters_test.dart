import 'package:carzon/features/seller_analytics/presentation/utils/statistics_formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('null and non-finite conversion become em dash', () {
    expect(formatStatisticsConversion(null, '—'), '—');
    expect(formatStatisticsConversion(double.nan, '—'), '—');
  });

  test('avoids fake two-decimal precision', () {
    expect(formatStatisticsConversion(12, '—'), '12%');
    expect(formatStatisticsConversion(12.0, '—'), '12%');
    expect(formatStatisticsConversion(4.2, '—'), '4.2%');
    expect(formatStatisticsConversion(4.24, '—'), '4.2%');
  });

  test('chart dates stay compact', () {
    final formatted = formatStatisticsChartDate(DateTime(2026, 9, 1), 'en');
    expect(formatted, contains('1'));
    expect(formatted.length, lessThan(12));
  });

  test('monotone cubic interpolates source knots exactly', () {
    const y = [0.0, 4.0, 4.0, 10.0, 1.0];
    for (var i = 0; i < y.length; i++) {
      expect(statisticsMonotoneY(y, i.toDouble()), closeTo(y[i], 1e-9));
    }
  });

  test('monotone cubic stays within adjacent source extrema', () {
    const y = [0.0, 10.0, 2.0, 8.0, 8.0, 0.0];
    for (var i = 0; i < y.length - 1; i++) {
      final lo = y[i] < y[i + 1] ? y[i] : y[i + 1];
      final hi = y[i] > y[i + 1] ? y[i] : y[i + 1];
      for (final t in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final v = statisticsMonotoneY(y, i + t);
        expect(v, greaterThanOrEqualTo(lo - 1e-9));
        expect(v, lessThanOrEqualTo(hi + 1e-9));
      }
    }
  });

  test('all-zero interpolant stays on zero', () {
    const y = [0.0, 0.0, 0.0, 0.0];
    expect(statisticsMonotoneY(y, 1.5), 0);
    expect(statisticsMonotoneSlopes(y), everyElement(0));
  });

  test('single spike does not invent neighboring extrema', () {
    const y = [0.0, 0.0, 10.0, 0.0, 0.0];
    expect(statisticsMonotoneY(y, 0.5), closeTo(0, 1e-9));
    expect(statisticsMonotoneY(y, 3.5), closeTo(0, 1e-9));
    var maxV = 0.0;
    var minV = 10.0;
    for (var s = 0; s <= 40; s++) {
      final v = statisticsMonotoneY(y, s / 10);
      if (v > maxV) maxV = v;
      if (v < minV) minV = v;
    }
    expect(maxV, closeTo(10, 1e-9));
    expect(minV, closeTo(0, 1e-9));
  });

  test('monotonic increasing interpolant stays non-decreasing', () {
    const y = [0.0, 1.0, 3.0, 6.0, 10.0];
    var prev = -1.0;
    for (var s = 0; s <= 40; s++) {
      final v = statisticsMonotoneY(y, s / 10);
      expect(v, greaterThanOrEqualTo(prev - 1e-9));
      prev = v;
    }
  });

  test('monotonic decreasing interpolant stays non-increasing', () {
    const y = [10.0, 6.0, 3.0, 1.0, 0.0];
    var prev = 11.0;
    for (var s = 0; s <= 40; s++) {
      final v = statisticsMonotoneY(y, s / 10);
      expect(v, lessThanOrEqualTo(prev + 1e-9));
      prev = v;
    }
  });
}
