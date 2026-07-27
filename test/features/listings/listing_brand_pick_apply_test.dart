import 'package:carzon/features/listings/domain/catalog/listing_brands.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_brand_pick_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  group('applyListingBrandPick', () {
    test('maps catalog brand to canonical key', () {
      final applied = applyListingBrandPick('Toyota');
      expect(applied.catalogKey, 'Toyota');
      expect(applied.customMakeText, isEmpty);
    });

    test('maps manual custom text to Other + custom field', () {
      final applied = applyListingBrandPick('  Zaporozhets ');
      expect(applied.catalogKey, kListingBrandCatalogOther);
      expect(applied.customMakeText, 'Zaporozhets');
    });

    test('maps catalog Other sentinel without custom text', () {
      final applied = applyListingBrandPick('Other');
      expect(applied.catalogKey, kListingBrandCatalogOther);
      expect(applied.customMakeText, isEmpty);
    });
  });

  group('effectiveListingMakeForSubmit', () {
    test('returns trimmed custom make for Other', () {
      expect(
        effectiveListingMakeForSubmit(
          catalogKey: kListingBrandCatalogOther,
          customMakeText: '  Rare Motors ',
        ),
        'Rare Motors',
      );
    });

    test('returns empty string for Other with blank custom make', () {
      expect(
        effectiveListingMakeForSubmit(
          catalogKey: kListingBrandCatalogOther,
          customMakeText: '   ',
        ),
        '',
      );
    });
  });

  group('validateListingCustomMakeField', () {
    final l10n = ruStrings();

    test('requires non-empty custom make when Other selected', () {
      expect(
        validateListingCustomMakeField(
          l10n,
          catalogKey: kListingBrandCatalogOther,
          customMakeText: '',
        ),
        l10n.validationRequired,
      );
    });

    test('rejects literal Other as custom make', () {
      expect(
        validateListingCustomMakeField(
          l10n,
          catalogKey: kListingBrandCatalogOther,
          customMakeText: 'Other',
        ),
        l10n.createListingCustomBrandInvalid,
      );
    });

    test('accepts legitimate rare brand names', () {
      expect(
        validateListingCustomMakeField(
          l10n,
          catalogKey: kListingBrandCatalogOther,
          customMakeText: 'Zaporozhets',
        ),
        isNull,
      );
    });
  });
}
