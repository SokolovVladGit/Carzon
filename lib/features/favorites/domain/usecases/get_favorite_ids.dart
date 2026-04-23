import '../../../../core/utils/result.dart';
import '../repositories/favorites_repository.dart';

class GetFavoriteIds {
  GetFavoriteIds(this._repository);
  final FavoritesRepository _repository;

  Future<Result<Set<String>>> call() => _repository.getFavoriteIds();
}
