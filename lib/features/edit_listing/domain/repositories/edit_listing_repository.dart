import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/edit_listing_input.dart';

/// Narrow repository for owner-only listing edits. Backed by the
/// `update_listing_details` RPC in the data layer.
abstract interface class EditListingRepository {
  /// Updates mutable fields of the caller's own listing. The RPC
  /// rejects non-owners, invalid input, and unauthenticated calls; a
  /// [Failure] is returned in those cases.
  Future<Result<Listing>> updateDetails(EditListingInput input);

  /// Replaces (or removes, when [coverImageUrl] is null) the cover
  /// image URL on the caller's own listing via the narrow
  /// `update_listing_cover_image` RPC. Returns the refreshed listing.
  Future<Result<Listing>> updateCoverImage({
    required String listingId,
    required String? coverImageUrl,
  });
}
