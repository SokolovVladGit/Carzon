import '../../../../core/utils/result.dart';
import '../entities/listing.dart';
import '../repositories/listings_repository.dart';

class GetListings {
  GetListings(this._repository);
  final ListingsRepository _repository;

  Future<Result<List<Listing>>> call(ListingsQuery query) =>
      _repository.getListings(query);
}
