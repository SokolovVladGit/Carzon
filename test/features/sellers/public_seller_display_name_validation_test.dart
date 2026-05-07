import 'package:carzon/features/sellers/domain/seller_display_name_constraints.dart';
import 'package:carzon/features/sellers/presentation/utils/public_seller_display_name_validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();

  test('rejects longer than maxLength', () {
    final tooLong = List.filled(
      SellerDisplayNameConstraints.maxLength + 1,
      'x',
    ).join();
    expect(
      validatePublicSellerDisplayName(tooLong, ru),
      ru.profilePublicSellerNameTooLong,
    );
  });

  test('rejects email-shaped display name', () {
    expect(
      validatePublicSellerDisplayName('seller@example.com', ru),
      ru.profilePublicSellerNameLooksLikeEmail,
    );
  });

  test('allows empty', () {
    expect(validatePublicSellerDisplayName('', ru), isNull);
    expect(validatePublicSellerDisplayName('   ', ru), isNull);
  });
}
