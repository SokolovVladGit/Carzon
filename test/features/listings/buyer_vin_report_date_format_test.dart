import 'package:carzon/features/listings/presentation/utils/buyer_vin_report_date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatBuyerVinReportDate uses dd.MM.yyyy for local DateTime', () {
    expect(formatBuyerVinReportDate(DateTime(2026, 5, 16)), '16.05.2026');
    expect(formatBuyerVinReportDate(DateTime(2026, 1, 7)), '07.01.2026');
  });
}
