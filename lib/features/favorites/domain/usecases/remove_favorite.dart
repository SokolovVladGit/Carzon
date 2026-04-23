import '../../../../core/utils/result.dart';
import '../repositories/favorites_repository.dart';

class RemoveFavorite {
  RemoveFavorite(this._repository);
  final FavoritesRepository _repository;

  Future<Result<void>> call(String listingId) => _repository.remove(listingId);
}
