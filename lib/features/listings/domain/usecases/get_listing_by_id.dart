import '../../../../core/utils/result.dart';
import '../entities/listing.dart';
import '../repositories/listings_repository.dart';

class GetListingById {
  GetListingById(this._repository);
  final ListingsRepository _repository;

  Future<Result<Listing>> call(String id) => _repository.getById(id);
}
