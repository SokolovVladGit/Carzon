import '../entities/uploaded_listing_image.dart';

/// Maximum photos per listing (aligned with Postgres `listing_images` and RPC).
const int kMaxListingPhotos = 9;

bool isUploadedListingGalleryWithinLimit(List<UploadedListingImage>? gallery) =>
    gallery == null || gallery.length <= kMaxListingPhotos;
