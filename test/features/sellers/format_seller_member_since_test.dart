import 'package:carzon/features/sellers/presentation/utils/format_seller_member_since.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();

  test('May uses genitive «мая», not nominative «май»', () {
    expect(
      formatSellerMemberSinceMonthYear(ru, DateTime.utc(2026, 5, 15)),
      'мая 2026',
    );
  });

  test('January uses genitive января', () {
    expect(
      formatSellerMemberSinceMonthYear(ru, DateTime.utc(2026, 1, 3)),
      'января 2026',
    );
  });

  test('full member-since line uses Carzon branding', () {
    final fragment = formatSellerMemberSinceMonthYear(
      ru,
      DateTime.utc(2026, 5, 1),
    );
    expect(ru.sellerMemberSince(fragment), 'На Carzon с мая 2026');
  });
}
