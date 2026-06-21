import 'package:carzon/features/listings/domain/catalog/listing_brands.dart';
import 'package:carzon/shared/brands/brand_icon_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Second-wave brands added in catalog expansion pass.
const List<String> kSecondWaveListingBrands = [
  'DS Automobiles',
  'Genesis',
  'Polestar',
  'SsangYong',
  'KGM',
  'Isuzu',
  'Daihatsu',
  'Daewoo',
  'Datsun',
  'Abarth',
  'Lancia',
  'Ram',
  'GMC',
  'Lincoln',
  'Buick',
  'Hummer',
  'ORA',
  'Maxus',
  'Seres',
  'Voyah',
  'Aion',
  'Bestune',
  'DFSK',
  'Foton',
  'VinFast',
  'UAZ',
  'Moskvich',
];

void main() {
  group('listing brands', () {
    test('catalog includes required makes', () {
      expect(kListingBrandCatalog.contains('Toyota'), isTrue);
      expect(kListingBrandCatalog.contains('Other'), isTrue);
      expect(kListingBrandCatalog.contains('Lada'), isTrue);
      expect(kListingBrandCatalog.contains('BYD'), isTrue);
      expect(kListingBrandCatalog.contains('Subaru'), isTrue);
      expect(kListingBrandCatalog.contains('Lynk & Co'), isTrue);
      expect(kListingBrandCatalog.last, 'Other');
      expect(kListingBrandFeedQuickFilterCatalog.first, 'Toyota');
      expect(kListingBrandCatalog.length, 93);
      expect(kListingBrandFeedQuickFilterCatalog.length, 92);
    });

    test('catalog has no duplicate brand names', () {
      expect(kListingBrandCatalog.toSet().length, kListingBrandCatalog.length);
    });

    test('listingBrandNormalizeForLookup folds case/spacing/hyphens', () {
      expect(listingBrandNormalizeForLookup('toyota'), 'Toyota');
      expect(listingBrandNormalizeForLookup('mercedes benz'), 'Mercedes-Benz');
      expect(listingBrandNormalizeForLookup('mercedesbenz'), 'Mercedes-Benz');
      expect(listingBrandNormalizeForLookup('great wall'), 'Great Wall');
      expect(listingBrandNormalizeForLookup('lynk & co'), 'Lynk & Co');
      expect(listingBrandNormalizeForLookup('BYD'), 'BYD');
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

    group('catalog symmetry', () {
      test('every feed quick-filter brand is in full catalog', () {
        for (final brand in kListingBrandFeedQuickFilterCatalog) {
          expect(kListingBrandCatalog, contains(brand));
        }
      });

      test('Other is in full catalog only', () {
        expect(kListingBrandCatalog, contains(kListingBrandCatalogOther));
        expect(
          kListingBrandFeedQuickFilterCatalog,
          isNot(contains(kListingBrandCatalogOther)),
        );
        expect(kListingBrandCatalog.last, kListingBrandCatalogOther);
      });

      test('feed catalog equals full catalog minus Other', () {
        final expected = kListingBrandCatalog
            .where((b) => b != kListingBrandCatalogOther)
            .toList(growable: false);
        expect(kListingBrandFeedQuickFilterCatalog, expected);
        expect(
          kListingBrandFeedQuickFilterCatalog.length,
          kListingBrandCatalog.length - 1,
        );
      });

      test('canonical display names normalize consistently', () {
        final cases = <String, String>{
          'mercedes benz': 'Mercedes-Benz',
          'MERCEDES-BENZ': 'Mercedes-Benz',
          'land rover': 'Land Rover',
          'alfa romeo': 'Alfa Romeo',
          'lynk & co': 'Lynk & Co',
          'great wall': 'Great Wall',
          'li auto': 'Li Auto',
          'xpeng': 'XPeng',
          'volkswagen': 'Volkswagen',
          'citroen': 'Citroen',
          'peugeot': 'Peugeot',
          'skoda': 'Skoda',
        };
        for (final entry in cases.entries) {
          expect(
            listingBrandNormalizeForLookup(entry.key),
            entry.value,
            reason: entry.key,
          );
        }
      });

      test('newly added brands are in both catalogs where applicable', () {
        for (final brand in ['BYD', 'Cupra', 'Zeekr', 'Subaru', 'Smart']) {
          expect(kListingBrandCatalog, contains(brand));
          expect(kListingBrandFeedQuickFilterCatalog, contains(brand));
        }
      });

      test('second-wave brands are in full and feed catalogs', () {
        for (final brand in kSecondWaveListingBrands) {
          expect(kListingBrandCatalog, contains(brand), reason: brand);
          expect(kListingBrandFeedQuickFilterCatalog, contains(brand));
        }
      });

      test('second-wave brands normalize to canonical display names', () {
        final cases = <String, String>{
          'ds automobiles': 'DS Automobiles',
          'ssangyong': 'SsangYong',
          'SSANG YONG': 'SsangYong',
          'kgm': 'KGM',
          'ram': 'Ram',
          'gmc': 'GMC',
          'uaz': 'UAZ',
          'moskvich': 'Moskvich',
          'vinfast': 'VinFast',
          'VINFAST': 'VinFast',
        };
        for (final entry in cases.entries) {
          expect(
            listingBrandNormalizeForLookup(entry.key),
            entry.value,
            reason: entry.key,
          );
        }
      });

      test('all feed catalog brands use packaged SVG on feed', () {
        for (final brand in kListingBrandFeedQuickFilterCatalog) {
          expect(
            listingBrandFeedQuickFilterShouldUseMonogram(brand),
            isFalse,
            reason: brand,
          );
          expect(
            isBrandIconDefaultAssetPath(getBrandIconPath(brand)),
            isFalse,
            reason: brand,
          );
        }
        expect(
          listingBrandFeedQuickFilterShouldUseMonogram('Bestune'),
          isFalse,
        );
        expect(listingBrandFeedQuickFilterShouldUseMonogram('FAW'), isFalse);
        expect(getBrandIconPath('Bestune'), endsWith('/bestune.svg'));
        expect(getBrandIconPath('FAW'), endsWith('/faw.svg'));
      });
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
