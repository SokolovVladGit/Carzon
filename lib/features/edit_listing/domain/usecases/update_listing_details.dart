import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/edit_listing_input.dart';
import '../repositories/edit_listing_repository.dart';

/// Pure pass-through so presentation never imports the repository
/// directly.
class UpdateListingDetails {
  UpdateListingDetails(this._repository);
  final EditListingRepository _repository;

  Future<Result<Listing>> call(EditListingInput input) =>
      _repository.updateDetails(input);
}
