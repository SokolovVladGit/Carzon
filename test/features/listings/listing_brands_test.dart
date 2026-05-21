import 'package:carzon/features/listings/domain/catalog/listing_brands.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listing brands', () {
    test('catalog includes required makes', () {
      expect(kListingBrandCatalog.contains('Toyota'), isTrue);
      expect(kListingBrandCatalog.contains('Other'), isTrue);
      expect(kListingBrandCatalog.contains('Lada'), isTrue);
      expect(kListingBrandCatalog.last, 'Other');
    });

    test('listingBrandNormalizeForLookup folds case/spacing/hyphens', () {
      expect(listingBrandNormalizeForLookup('toyota'), 'Toyota');
      expect(listingBrandNormalizeForLookup('mercedes benz'), 'Mercedes-Benz');
      expect(listingBrandNormalizeForLookup('mercedesbenz'), 'Mercedes-Benz');
    });

    test('isKnownListingBrand distinguishes catalog vs unknown', () {
      expect(isKnownListingBrand('BMW'), isTrue);
      expect(isKnownListingBrand('Citroen'), isTrue);
      expect(isKnownListingBrand('Seat'), isTrue);
      expect(isKnownListingBrand('AlienMotors'), isFalse);
      expect(isKnownListingBrand(null), isFalse);
      expect(listingBrandNormalizeForLookup('  '), isNull);
    });

    test('feed quick-filter catalog is catalog minus Other', () {
      expect(
        kListingBrandFeedQuickFilterCatalog,
        kListingBrandCatalog
            .where((b) => b != kListingBrandCatalogOther)
            .toList(growable: false),
      );
      expect(kListingBrandFeedQuickFilterCatalog, isNot(contains('Other')));
    });

    test('feed quick-filter selection uses normalization', () {
      expect(
        listingBrandFeedQuickFilterIsSelected('mercedes benz', 'Mercedes-Benz'),
        isTrue,
      );
      expect(listingBrandFeedQuickFilterAllSelected('Toyota'), isFalse);
      expect(listingBrandFeedQuickFilterAllSelected(null), isTrue);
      expect(listingBrandFeedQuickFilterAllSelected('Custom Garage'), isFalse);
      expect(
        listingBrandFeedQuickFilterSelectionUnchanged(
          'mercedes benz',
          'Mercedes-Benz',
        ),
        isTrue,
      );
    });
  });
}
