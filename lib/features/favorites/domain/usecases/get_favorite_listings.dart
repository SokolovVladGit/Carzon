import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../repositories/favorites_repository.dart';

class GetFavoriteListings {
  GetFavoriteListings(this._repository);
  final FavoritesRepository _repository;

  Future<Result<List<Listing>>> call() => _repository.getFavoriteListings();
}
