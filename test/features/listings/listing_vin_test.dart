import 'package:carzon/features/listings/domain/validation/listing_vin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListingVin', () {
    test('blank input is valid optional', () {
      expect(ListingVin.isOptionalInputValid(null), isTrue);
      expect(ListingVin.isOptionalInputValid(''), isTrue);
      expect(ListingVin.isOptionalInputValid('   '), isTrue);
    });

    test('normalizeOptional uppercases and strips spaces/hyphens', () {
      expect(ListingVin.normalizeOptional('  ab-cd ef \n'), 'ABCDEF');
    });

    test('rejects wrong length', () {
      expect(ListingVin.isOptionalInputValid('1HGBH41JXMN10918'), isFalse);
    });

    test('rejects I O Q', () {
      expect(ListingVin.isOptionalInputValid('1HGBH41JXON109186'), isFalse);
      expect(ListingVin.isOptionalInputValid('1HGBH41JXMN10918I'), isFalse);
    });

    test('accepts syntactically valid 17-char VIN without checksum', () {
      expect(ListingVin.isOptionalInputValid('1HGBH41JXMN109186'), isTrue);
      expect(
        ListingVin.normalizeOptional('1hgbh41-jx mn109186'),
        '1HGBH41JXMN109186',
      );
    });
  });
}
