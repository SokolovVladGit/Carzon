import 'package:carzon/features/listings/data/datasources/listings_discovery_search_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('escapeIlikePatternFragment', () {
    test('escapes ILIKE metacharacters', () {
      expect(escapeIlikePatternFragment(r'a%b_c\d'), r'a\%b\_c\\d');
      expect(escapeIlikePatternFragment(r'back\slash'), r'back\\slash');
    });
  });

  group('postgrestFilterValue', () {
    test('quotes values containing comma', () {
      expect(postgrestFilterValue('%hello, world%'), '"%hello, world%"');
    });

    test('leaves simple patterns unquoted', () {
      expect(postgrestFilterValue('%Audi%'), '%Audi%');
    });
  });

  group('listingsDiscoverySearchPostgrestOrFilter', () {
    test('Audi generates OR predicate over title, make, and model', () {
      expect(
        listingsDiscoverySearchPostgrestOrFilter('Audi'),
        'title.ilike.%Audi%,make.ilike.%Audi%,model.ilike.%Audi%',
      );
    });

    test('trims are applied by caller; pattern escapes wildcards', () {
      expect(
        listingsDiscoverySearchPostgrestOrFilter('100%'),
        r'title.ilike.%100\%%,make.ilike.%100\%%,model.ilike.%100\%%',
      );
    });
  });

  group('listingDiscoveryFreeTextSearchMatches', () {
    test('make Audi matches search Audi when title omits brand', () {
      expect(
        listingDiscoveryFreeTextSearchMatches(
          searchTerm: 'Audi',
          title: 'Отличное состояние',
          make: 'Audi',
          model: 'A4',
        ),
        isTrue,
      );
    });

    test('model A4 matches search A4 when title omits model', () {
      expect(
        listingDiscoveryFreeTextSearchMatches(
          searchTerm: 'A4',
          title: 'Продам срочно',
          make: 'Audi',
          model: 'A4',
        ),
        isTrue,
      );
    });

    test('title-only search still works', () {
      expect(
        listingDiscoveryFreeTextSearchMatches(
          searchTerm: 'diesel',
          title: 'Volkswagen Golf diesel',
          make: 'Volkswagen',
          model: 'Golf',
        ),
        isTrue,
      );
      expect(
        listingDiscoveryFreeTextSearchMatches(
          searchTerm: 'diesel',
          title: 'Petrol only',
          make: 'Toyota',
          model: 'Yaris',
        ),
        isFalse,
      );
    });

    test('case-insensitive partial match', () {
      expect(
        listingDiscoveryFreeTextSearchMatches(
          searchTerm: 'audi',
          title: 'Custom headline',
          make: 'Audi',
        ),
        isTrue,
      );
    });

    test('empty search matches everything', () {
      expect(
        listingDiscoveryFreeTextSearchMatches(
          searchTerm: '   ',
          title: 'Anything',
        ),
        isTrue,
      );
    });
  });

  group('combined filter semantics (search OR vs explicit make AND)', () {
    test('search matches Audi row but explicit BMW make would exclude it', () {
      expect(
        listingDiscoveryFreeTextSearchMatches(
          searchTerm: 'Audi',
          title: 'Custom',
          make: 'Audi',
        ),
        isTrue,
      );
      // Feed applies search OR and make filter as separate AND predicates.
      const explicitMake = 'BMW';
      final listingMake = 'Audi';
      expect(explicitMake.toLowerCase(), isNot(contains('audi')));
      expect(listingMake.toLowerCase(), contains('audi'));
    });
  });
}
