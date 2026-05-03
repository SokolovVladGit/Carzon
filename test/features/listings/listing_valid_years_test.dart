import 'package:carzon/features/listings/domain/validation/listing_valid_years.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listingYearMaxInclusive', () {
    test('is calendar year plus one ', () {
      final now = DateTime.utc(2026, 6, 1);
      expect(listingYearMaxInclusive(now: now), 2027);
    });
  });

  group('isListingYearValid', () {
    test('accepts inclusive bounds', () {
      final now = DateTime.utc(2026, 1, 1);
      expect(isListingYearValid(1900, now: now), isTrue);
      expect(isListingYearValid(2027, now: now), isTrue);
      expect(isListingYearValid(null, now: now), isFalse);
      expect(isListingYearValid(1899, now: now), isFalse);
      expect(isListingYearValid(2028, now: now), isFalse);
    });
  });

  group('listingYearsOrderedNewestFirst', () {
    test('starts at max and decreases with step 1', () {
      final now = DateTime.utc(2026, 5, 1);
      final years = listingYearsOrderedNewestFirst(now: now);
      expect(years.first, 2027);
      expect(years.last, kListingYearMinInclusive);
      expect(years.length, 2027 - kListingYearMinInclusive + 1);
      for (var i = 1; i < years.length; i++) {
        expect(years[i - 1], years[i] + 1);
      }
    });
  });
}
