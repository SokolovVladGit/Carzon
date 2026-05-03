import 'package:carzon/features/create_listing/domain/constants/listing_gallery_limits.dart';
import 'package:carzon/features/create_listing/domain/entities/uploaded_listing_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows null and up to kMaxListingPhotos items', () {
    expect(isUploadedListingGalleryWithinLimit(null), isTrue);
    expect(
      isUploadedListingGalleryWithinLimit(<UploadedListingImage>[]),
      isTrue,
    );
    final nine = List.generate(
      kMaxListingPhotos,
      (i) => UploadedListingImage(publicUrl: 'https://example.com/$i'),
    );
    expect(isUploadedListingGalleryWithinLimit(nine), isTrue);
    final ten = [...nine, const UploadedListingImage(publicUrl: 'https://z')];
    expect(isUploadedListingGalleryWithinLimit(ten), isFalse);
  });
}
