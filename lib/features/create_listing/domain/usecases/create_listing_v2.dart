import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/new_listing_input.dart';
import '../repositories/create_listing_repository.dart';

/// Calls [CreateListingRepository.createV2]; reserved for Phase 3 multi-photo flow.
class CreateListingV2 {
  CreateListingV2(this._repository);
  final CreateListingRepository _repository;

  Future<Result<Listing>> call(NewListingInput input) =>
      _repository.createV2(input);
}
