import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../repositories/edit_listing_repository.dart';

/// Owner-only RPC `replace_listing_images` ([imagePublicUrls] order = cover-first).
///
/// Passing an empty list clears gallery rows and `cover_image_url` on the server.
class ReplaceListingImages {
  ReplaceListingImages(this._repository);
  final EditListingRepository _repository;

  Future<Result<Listing>> call({
    required String listingId,
    required List<String> imagePublicUrls,
    List<String?>? storagePaths,
  }) => _repository.replaceListingImages(
    listingId: listingId,
    imagePublicUrls: imagePublicUrls,
    storagePaths: storagePaths,
  );
}
