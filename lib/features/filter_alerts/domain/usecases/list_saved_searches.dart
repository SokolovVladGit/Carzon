import '../../../../core/utils/result.dart';
import '../entities/saved_search.dart';
import '../repositories/saved_searches_repository.dart';

class ListSavedSearches {
  ListSavedSearches(this._repository);

  final SavedSearchesRepository _repository;

  Future<Result<List<SavedSearch>>> call() => _repository.list();
}
