import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/edit_listing_input.dart';
import '../repositories/edit_listing_repository.dart';

class UpdateListingDetailsV2 {
  UpdateListingDetailsV2(this._repository);
  final EditListingRepository _repository;

  Future<Result<Listing>> call(EditListingInput input) =>
      _repository.updateDetailsV2(input);
}
