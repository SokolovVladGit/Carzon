import 'package:carzon/features/create_listing/data/utils/create_listing_v2_vin_params.dart';
import 'package:carzon/features/listings/domain/validation/listing_vin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyOptionalVinToCreateListingV2Params', () {
    test('omits p_vin when vin is null (no VIN)', () {
      final params = <String, dynamic>{'p_title': 'x'};
      applyOptionalVinToCreateListingV2Params(params, null);
      expect(params.containsKey('p_vin'), isFalse);
    });

    test('adds p_vin when vin is non-null', () {
      final params = <String, dynamic>{'p_title': 'x'};
      applyOptionalVinToCreateListingV2Params(params, '1HGBH41JXMN109186');
      expect(params['p_vin'], '1HGBH41JXMN109186');
    });
  });

  group('create listing VIN normalization (ListingVin)', () {
    test(
      'normalizedOrNullForCreate uppercases and strips spaces/hyphens for RPC',
      () {
        expect(
          ListingVin.normalizedOrNullForCreate('  1hgbh41-jx mn109186  '),
          '1HGBH41JXMN109186',
        );
      },
    );

    test('blank field yields null so p_vin is omitted via datasource', () {
      expect(ListingVin.normalizedOrNullForCreate(''), isNull);
      expect(ListingVin.normalizedOrNullForCreate(' \t '), isNull);
    });
  });

  group('create listing invalid-VIN gate (mirrors create_listing_page)', () {
    test('non-empty invalid VIN fails isOptionalInputValid before submit', () {
      expect(
        ListingVin.isOptionalInputValid('1HGBH41JXON109186'),
        isFalse,
      );
    });
  });
}
