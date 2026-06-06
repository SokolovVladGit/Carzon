import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../repositories/edit_listing_repository.dart';

class GetOwnerListingForEdit {
  GetOwnerListingForEdit(this._repository);

  final EditListingRepository _repository;

  Future<Result<Listing>> call(String listingId) =>
      _repository.fetchOwnerListingForEdit(listingId);
}
