import 'package:equatable/equatable.dart';

import '../../../create_listing/domain/entities/cover_image_upload.dart';
import '../../../listings/domain/entities/listing_image.dart';

/// One ordered slot in the edit-listing staging gallery (`0` is cover).
///
/// Keeps RPC-facing metadata for existing rows alongside local picks pending
/// upload.
/// One ordered slot in the edit gallery (index 0 = cover).
sealed class EditListingGallerySlot extends Equatable {
  const EditListingGallerySlot();
}

/// Existing persisted image fetched from [`listing.images`] RPC or synthesized
/// from legacy `listing.cover_image_url` when gallery rows were empty on load.
final class EditListingGalleryRemoteSlot extends EditListingGallerySlot {
  const EditListingGalleryRemoteSlot({
    required this.publicUrl,
    this.row,
    this.storagePathOverride,
  });

  factory EditListingGalleryRemoteSlot.fromRow(ListingImage row) {
    return EditListingGalleryRemoteSlot(
      row: row,
      publicUrl: row.publicUrl,
      storagePathOverride: row.storagePath,
    );
  }

  /// Cover-only bootstrap when listing images were fetched successfully but no
  /// rows exist (`row` stays null — used only for visuals + replace ordering).
  factory EditListingGalleryRemoteSlot.legacyCover(String url) {
    return EditListingGalleryRemoteSlot(publicUrl: url, row: null);
  }

  /// Non-null canonical row when this slot originated from `listing_images`.
  final ListingImage? row;

  final String publicUrl;

  /// When [row] is null (legacy-only cover), callers may omit storage paths.
  final String? storagePathOverride;

  String? get effectiveStoragePath => storagePathOverride ?? row?.storagePath;

  @override
  List<Object?> get props => [row?.id, publicUrl, storagePathOverride];
}

/// Local blob staged for sequential upload during save (Phase 4C).
final class EditListingGalleryLocalSlot extends EditListingGallerySlot {
  const EditListingGalleryLocalSlot({required this.upload});

  final CoverImageUpload upload;

  @override
  List<Object?> get props => [upload];
}

bool listingEditGallerySlotsDeepEqual(
  List<EditListingGallerySlot> a,
  List<EditListingGallerySlot> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Set<String> _remoteUrlsInDraft(List<EditListingGallerySlot> slots) {
  final out = <String>{};
  for (final s in slots) {
    if (s case EditListingGalleryRemoteSlot(:final publicUrl)) {
      out.add(publicUrl);
    }
  }
  return out;
}

/// Remote URLs that existed at load (`[baseline]`) but are absent from [finalDraft].
Iterable<String> remoteUrlsDroppedSinceBaseline({
  required List<EditListingGallerySlot> baseline,
  required List<EditListingGallerySlot> finalDraft,
}) sync* {
  final keep = _remoteUrlsInDraft(finalDraft);
  for (final s in baseline) {
    if (s case EditListingGalleryRemoteSlot(:final publicUrl)) {
      if (!keep.contains(publicUrl)) yield publicUrl;
    }
  }
}
