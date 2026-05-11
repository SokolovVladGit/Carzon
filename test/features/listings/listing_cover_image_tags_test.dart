import 'package:carzon/features/listings/presentation/widgets/listing_cover_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listingCoverHeroTag stays id-based listing-cover-', () {
    expect(listingCoverHeroTag('l1'), 'listing-cover-l1');
  });

  test(
    'gallery slot tags are deterministic and disjoint from listing cover',
    () {
      expect(listingDetailsGalleryHeroTag('l1', 1), 'listing-gallery-l1-1');
      expect(
        listingDetailsGalleryHeroTag('l1', 2),
        isNot(listingCoverHeroTag('l1')),
      );
    },
  );
}
