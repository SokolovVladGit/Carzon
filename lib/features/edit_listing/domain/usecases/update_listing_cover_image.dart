import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../repositories/edit_listing_repository.dart';

/// Narrow domain entry point for replacing or removing a listing's
/// cover image. Pass a non-null [coverImageUrl] to replace the cover
/// with the given public URL; pass `null` to remove the cover entirely.
///
/// Backend-agnostic: the caller only sees a plain `String?` URL. The
/// data layer is responsible for the narrow `update_listing_cover_image`
/// RPC and for any best-effort Storage cleanup; neither leaks here.
class UpdateListingCoverImage {
  UpdateListingCoverImage(this._repository);
  final EditListingRepository _repository;

  Future<Result<Listing>> call({
    required String listingId,
    required String? coverImageUrl,
  }) => _repository.updateCoverImage(
    listingId: listingId,
    coverImageUrl: coverImageUrl,
  );
}
