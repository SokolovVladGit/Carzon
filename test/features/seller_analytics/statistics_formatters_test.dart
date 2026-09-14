import 'package:carzon/features/seller_analytics/presentation/utils/statistics_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
