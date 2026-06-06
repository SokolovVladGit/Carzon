import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_image.dart';
import '../repositories/edit_listing_repository.dart';

class GetOwnerListingImagesForEdit {
  GetOwnerListingImagesForEdit(this._repository);

  final EditListingRepository _repository;

  Future<Result<List<ListingImage>>> call(String listingId) =>
      _repository.fetchOwnerListingImagesForEdit(listingId);
}
