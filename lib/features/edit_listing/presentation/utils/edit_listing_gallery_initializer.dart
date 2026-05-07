import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_image.dart';
import '../models/edit_listing_gallery_slot.dart';

/// Builds the initial editable gallery snapshot after a listing load completes.
///
/// * When [galleryLoadSucceeded] is false, returns empty — callers must not run
///   `replace_listing_images`; the UI may still preview [Listing.coverImageUrl].
/// * When succeeded and rows exist — ordered copies of [prefetchedGallery].
/// * When succeeded, no rows — single legacy-remote slot using cover URL if present.
/// * Otherwise empty.
List<EditListingGallerySlot> buildInitialEditListingGallerySlots({
  required Listing listing,
  required List<ListingImage> prefetchedGallery,
  required bool galleryLoadSucceeded,
}) {
  if (!galleryLoadSucceeded) return const <EditListingGallerySlot>[];

  final sorted = List<ListingImage>.from(prefetchedGallery)
    ..sort((a, b) => a.position.compareTo(b.position));

  if (sorted.isNotEmpty) {
    return [
      for (final row in sorted) EditListingGalleryRemoteSlot.fromRow(row),
    ];
  }

  final cover = listing.coverImageUrl?.trim();
  if (cover != null && cover.isNotEmpty) {
    return [EditListingGalleryRemoteSlot.legacyCover(cover)];
  }

  return const <EditListingGallerySlot>[];
}
