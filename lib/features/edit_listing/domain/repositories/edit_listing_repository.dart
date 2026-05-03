import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/edit_listing_input.dart';

/// Narrow repository for owner-only listing edits. Backed by the
/// `update_listing_details` (+ v2 currency) RPCs in the data layer.
abstract interface class EditListingRepository {
  /// Updates mutable fields of the caller's own listing. The RPC
  /// rejects non-owners, invalid input, and unauthenticated calls; a
  /// [Failure] is returned in those cases.
  Future<Result<Listing>> updateDetails(EditListingInput input);

  /// Updates mutable fields INCLUDING [EditListingInput.priceCurrency] via
  /// `update_listing_details_v2`. Same ownership rules as [updateDetails].
  Future<Result<Listing>> updateDetailsV2(EditListingInput input);

  /// Replaces gallery metadata (and synced cover) atomically via
  /// `replace_listing_images`. Does not upload storage objects.
  ///
  /// [storagePaths] may be omitted (null RPC array). When non-null its
  /// length must match [imagePublicUrls]; entries may be null when unknown.
  Future<Result<Listing>> replaceListingImages({
    required String listingId,
    required List<String> imagePublicUrls,
    List<String?>? storagePaths,
  });

  /// Replaces (or removes, when [coverImageUrl] is null) the cover
  /// image URL on the caller's own listing via the narrow
  /// `update_listing_cover_image` RPC. Returns the refreshed listing.
  Future<Result<Listing>> updateCoverImage({
    required String listingId,
    required String? coverImageUrl,
  });
}
