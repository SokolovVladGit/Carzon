import '../../../../core/utils/result.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_image.dart';

/// Resolves ordered public URLs shown in Listing Details carousel.
///
/// * When [imagesResult] is a successful non-empty ordered gallery, uses those
///   URLs only (no duplicate append of `listings.cover_image_url`).
/// * On empty gallery rows, failed fetch, or blank URLs → falls back to
///   [Listing.coverImageUrl].
List<String> listingDetailsHeroImageUrls({
  required Listing listing,
  required Result<List<ListingImage>> imagesResult,
}) {
  void addDistinct(List<String> out, String raw) {
    final u = raw.trim();
    if (u.isEmpty) return;
    if (!out.contains(u)) out.add(u);
  }

  if (imagesResult is Success<List<ListingImage>>) {
    final rows = [...imagesResult.value];
    rows.sort((a, b) => a.position.compareTo(b.position));

    final fromGallery = <String>[];
    for (final img in rows) {
      addDistinct(fromGallery, img.publicUrl);
    }
    if (fromGallery.isNotEmpty) return fromGallery;
  }

  final cover = listing.coverImageUrl?.trim();
  if (cover != null && cover.isNotEmpty) {
    return [cover];
  }
  return const [];
}
