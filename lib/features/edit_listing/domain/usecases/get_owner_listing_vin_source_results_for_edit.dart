import '../../../../core/utils/result.dart';
import '../entities/owner_listing_vin_source_result.dart';
import '../repositories/edit_listing_repository.dart';

class GetOwnerListingVinSourceResultsForEdit {
  GetOwnerListingVinSourceResultsForEdit(this._repository);

  final EditListingRepository _repository;

  Future<Result<OwnerListingVinSourceResultsLookupResult>> call(
    String listingId,
  ) => _repository.fetchOwnerVinSourceResults(listingId);
}
