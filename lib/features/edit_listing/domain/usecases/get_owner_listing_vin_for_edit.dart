import '../../../../core/utils/result.dart';
import '../entities/owner_listing_vin_lookup_result.dart';
import '../repositories/edit_listing_repository.dart';

class GetOwnerListingVinForEdit {
  GetOwnerListingVinForEdit(this._repository);

  final EditListingRepository _repository;

  Future<Result<OwnerListingVinLookupResult>> call(String listingId) =>
      _repository.fetchOwnerVin(listingId);
}
