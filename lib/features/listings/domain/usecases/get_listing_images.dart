import '../../../../core/utils/result.dart';
import '../entities/listing_image.dart';
import '../repositories/listings_repository.dart';

class GetListingImages {
  GetListingImages(this._repository);
  final ListingsRepository _repository;

  Future<Result<List<ListingImage>>> call(String listingId) =>
      _repository.getListingImages(listingId);
}
