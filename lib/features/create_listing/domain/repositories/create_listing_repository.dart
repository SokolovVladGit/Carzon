import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../entities/new_listing_input.dart';

abstract interface class CreateListingRepository {
  Future<Result<Listing>> create(NewListingInput input);
}
