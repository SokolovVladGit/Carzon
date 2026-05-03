import 'package:equatable/equatable.dart';

import '../../../create_listing/domain/constants/listing_gallery_limits.dart';
import '../../../listings/domain/entities/listing_image.dart';

/// Distinguishes remote rows vs local picks (Phase 4C upload flow).
enum EditableListingImageKind { remote, localDraft }

/// Canonical ordered gallery slots for Edit Listing rebuild (future UI).
/// Index `0` is cover; maximum length is [kMaxListingPhotos].
class EditableListingImage extends Equatable {
  /// Existing `listing_images` row (or reconstructed from RPC metadata).
  const EditableListingImage.remote({
    required this.listingImageId,
    required this.publicUrl,
    this.storagePath,
  }) : kind = EditableListingImageKind.remote,
       localDraftKey = null;

  /// Placeholder until local bytes upload in Phase 4C.
  ///
  /// [localDraftKey] must be stable and unique among concurrent drafts so
  /// [Equatable] distinguishes two unpersisted picks.
  const EditableListingImage.localDraft({required this.localDraftKey})
    : kind = EditableListingImageKind.localDraft,
      listingImageId = null,
      publicUrl = null,
      storagePath = null;

  factory EditableListingImage.fromListingImage(ListingImage row) {
    return EditableListingImage.remote(
      listingImageId: row.id,
      publicUrl: row.publicUrl,
      storagePath: row.storagePath,
    );
  }

  final EditableListingImageKind kind;
  final String? listingImageId;
  final String? publicUrl;
  final String? storagePath;

  /// Non-null only when [kind] is [EditableListingImageKind.localDraft].
  final String? localDraftKey;

  @override
  List<Object?> get props => [
    kind,
    listingImageId,
    publicUrl,
    storagePath,
    localDraftKey,
  ];
}

/// True when [slots] respects the listing gallery ceiling.
bool isEditableListingGalleryWithinCap(List<EditableListingImage> slots) =>
    slots.length <= kMaxListingPhotos;
