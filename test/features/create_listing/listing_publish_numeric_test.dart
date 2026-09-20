import 'package:carzon/features/create_listing/domain/validation/listing_publish_numeric.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseListingPublishMileage', () {
    test('accepts normal and int4-max values', () {
      expect(parseListingPublishMileage('120000'), 120000);
      expect(parseListingPublishMileage('0'), 0);
      expect(parseListingPublishMileage('2147483647'), 2147483647);
    });

    test('rejects empty, non-digits, and values above int4', () {
      expect(parseListingPublishMileage(''), isNull);
      expect(parseListingPublishMileage('  '), isNull);
      expect(parseListingPublishMileage('12.0'), isNull);
      expect(parseListingPublishMileage('-1'), isNull);
      expect(parseListingPublishMileage('2147483648'), isNull);
      expect(parseListingPublishMileage('120006576546546546'), isNull);
    });
  });

  group('parseListingPublishPrice', () {
    test('accepts normal decimals up to numeric(12,2) max', () {
      expect(parseListingPublishPrice('7800'), 7800);
      expect(parseListingPublishPrice('7800.50'), 7800.50);
      expect(parseListingPublishPrice('9999999999.99'), 9999999999.99);
      expect(parseListingPublishPrice('9999999999'), 9999999999);
    });

    test('rejects empty, non-positive, exponent, and overflow', () {
      expect(parseListingPublishPrice(''), isNull);
      expect(parseListingPublishPrice('0'), isNull);
      expect(parseListingPublishPrice('-1'), isNull);
      expect(parseListingPublishPrice('7.8e30'), isNull);
      expect(parseListingPublishPrice('1E10'), isNull);
      expect(parseListingPublishPrice('2e5'), isNull);
      expect(parseListingPublishPrice('NaN'), isNull);
      expect(parseListingPublishPrice('Infinity'), isNull);
      expect(parseListingPublishPrice('-Infinity'), isNull);
      expect(parseListingPublishPrice('10000000000'), isNull);
      expect(parseListingPublishPrice('9999999999.991'), isNull);
    });
  });
}
