import '../../../../core/utils/result.dart';
import '../entities/listing.dart';
import '../repositories/listings_repository.dart';

/// Owner-only status change. Pure pass-through to the repository so the
/// presentation layer does not import the repository directly.
class SetListingStatus {
  SetListingStatus(this._repository);
  final ListingsRepository _repository;

  Future<Result<Listing>> call(String id, ListingStatus status) =>
      _repository.updateStatus(id, status);
}
