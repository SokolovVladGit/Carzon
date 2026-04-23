import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/new_listing_input.dart';
import '../repositories/create_listing_repository.dart';

class CreateListing {
  CreateListing(this._repository);
  final CreateListingRepository _repository;

  Future<Result<Listing>> call(NewListingInput input) =>
      _repository.create(input);
}
