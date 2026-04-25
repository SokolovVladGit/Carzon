import '../../../../core/utils/result.dart';
import '../repositories/listings_repository.dart';

/// Owner-only permanent delete. Thin pass-through to the repository so
/// the presentation layer does not import the repository directly,
/// mirroring the [SetListingStatus] pattern.
class DeleteListing {
  DeleteListing(this._repository);
  final ListingsRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteListing(id);
}
