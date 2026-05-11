import '../../../../core/utils/result.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_image.dart';

/// When [preferredFirstUrl] is non-empty, prepends it and skips duplicates.
///
/// Used so feed→details keeps the same first pixel URL after Supabase resolves
/// gallery rows (which may order URLs differently than catalog cover).
List<String> mergePreferredFirstHeroUrl(
  String? preferredFirstUrl,
  List<String> resolvedUrls,
) {
  final preferred = preferredFirstUrl?.trim();
  if (preferred == null || preferred.isEmpty) {
    return List<String>.from(resolvedUrls);
  }
  final out = <String>[preferred];
  for (final raw in resolvedUrls) {
    final u = raw.trim();
    if (u.isEmpty) continue;
    if (u == preferred) continue;
    if (!out.contains(u)) out.add(u);
  }
  return out;
}

/// Resolves ordered public URLs shown in Listing Details carousel.
///
/// * When [imagesResult] is a successful non-empty ordered gallery, uses those
///   URLs only (no duplicate append of `listings.cover_image_url`).
/// * On empty gallery rows, failed fetch, or blank URLs → falls back to
///   [Listing.coverImageUrl].
/// * When [preferredFirstUrl] is non-empty (typically route-extra catalog cover),
///   it becomes the first URL and gallery/fallback URLs follow without duplicates.
List<String> listingDetailsHeroImageUrls({
  required Listing listing,
  required Result<List<ListingImage>> imagesResult,
  String? preferredFirstUrl,
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
    if (fromGallery.isNotEmpty) {
      return mergePreferredFirstHeroUrl(preferredFirstUrl, fromGallery);
    }
  }

  final cover = listing.coverImageUrl?.trim();
  if (cover != null && cover.isNotEmpty) {
    return mergePreferredFirstHeroUrl(preferredFirstUrl, [cover]);
  }
  final trimmedPreferred = preferredFirstUrl?.trim();
  if (trimmedPreferred != null && trimmedPreferred.isNotEmpty) {
    return [trimmedPreferred];
  }
  return const [];
}
