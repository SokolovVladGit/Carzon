import 'package:carzon/features/listings/presentation/utils/feed_home_body_chips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feed body-type quick-filter icon optical scale', () {
    test('balanced body types use default scale 1.0', () {
      for (final chipId in ['all', 'sedan', 'suv', 'hatchback']) {
        expect(
          listingBodyTypeQuickFilterIconScale(chipId),
          1.0,
          reason: chipId,
        );
      }
    });

    test('narrow silhouettes receive modest optical boost', () {
      const boosted = {
        'wagon': 1.04,
        'pickup': 1.04,
        'coupe': 1.02,
        'minivan': 1.02,
      };
      for (final entry in boosted.entries) {
        expect(
          listingBodyTypeQuickFilterIconScale(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('override map keys match feed chip ids', () {
      const feedChipIds = {
        'all',
        'sedan',
        'suv',
        'hatchback',
        'wagon',
        'minivan',
        'pickup',
        'coupe',
      };
      for (final chipId
          in kListingBodyTypeQuickFilterIconOpticalScaleByChipId.keys) {
        expect(feedChipIds, contains(chipId), reason: chipId);
      }
    });
  });
}
