import 'package:carzon/features/edit_listing/domain/entities/editable_listing_image.dart';
import 'package:carzon/features/listings/domain/entities/listing_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditableListingImage', () {
    test('fromListingImage preserves identity fields', () {
      final row = ListingImage(
        id: 'ii',
        listingId: 'll',
        publicUrl: 'https://x/u.jpg',
        storagePath: 'p/x',
        position: 3,
        createdAt: DateTime.utc(2026, 2, 1),
      );
      final e = EditableListingImage.fromListingImage(row);
      expect(e.kind, EditableListingImageKind.remote);
      expect(e.publicUrl, 'https://x/u.jpg');
      expect(e.storagePath, 'p/x');
      expect(e.listingImageId, 'ii');
      expect(e.localDraftKey, isNull);
    });

    test('gallery cap helper rejects more than nine slots', () {
      expect(
        isEditableListingGalleryWithinCap([
          ...List.generate(
            9,
            (i) => EditableListingImage.localDraft(localDraftKey: '$i'),
          ),
        ]),
        isTrue,
      );
      expect(
        isEditableListingGalleryWithinCap([
          ...List.generate(
            10,
            (i) => EditableListingImage.localDraft(localDraftKey: '$i'),
          ),
        ]),
        isFalse,
      );
    });
  });
}
