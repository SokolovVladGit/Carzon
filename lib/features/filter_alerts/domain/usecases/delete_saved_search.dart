import '../../../../core/utils/result.dart';
import '../repositories/saved_searches_repository.dart';

class DeleteSavedSearch {
  DeleteSavedSearch(this._repository);

  final SavedSearchesRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}
