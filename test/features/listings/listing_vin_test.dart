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

    test('NA VIN with matching check digit is applicable and valid', () {
      const vin = '1HGBH41JXMN109186';
      expect(ListingVin.isCheckDigitApplicable(vin), isTrue);
      expect(ListingVin.computedCheckDigit(vin), 'X');
      expect(
        ListingVin.checkDigitStatus(vin),
        ListingVinCheckDigitStatus.valid,
      );
      expect(ListingVin.canAttemptResolve(vin), isTrue);
    });

    test('Honda NA VIN uses numeric check digit 3', () {
      const vin = '1HGCM82633A004352';
      expect(ListingVin.computedCheckDigit(vin), '3');
      expect(
        ListingVin.checkDigitStatus(vin),
        ListingVinCheckDigitStatus.valid,
      );
    });

    test('syntax-valid NA VIN with wrong check digit is resolvable-false', () {
      const vin = '1HGBH41JXMN109187';
      expect(ListingVin.isValidNormalized(vin), isTrue);
      expect(ListingVin.isOptionalInputValid(vin), isTrue);
      expect(
        ListingVin.checkDigitStatus(vin),
        ListingVinCheckDigitStatus.invalid,
      );
      expect(ListingVin.canAttemptResolve(vin), isFalse);
    });

    test('European WMI is not rejected by NA checksum', () {
      const vin = 'WVWZZZ1JZXW000001';
      expect(ListingVin.isValidNormalized(vin), isTrue);
      expect(ListingVin.isCheckDigitApplicable(vin), isFalse);
      expect(
        ListingVin.checkDigitStatus(vin),
        ListingVinCheckDigitStatus.notApplicable,
      );
      expect(ListingVin.canAttemptResolve(vin), isTrue);
    });
  });
}
