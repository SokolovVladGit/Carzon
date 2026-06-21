import '../../../../core/utils/result.dart';
import '../entities/saved_search.dart';
import '../repositories/saved_searches_repository.dart';

class SetSavedSearchAlertsEnabled {
  SetSavedSearchAlertsEnabled(this._repository);

  final SavedSearchesRepository _repository;

  Future<Result<SavedSearch>> call(String id, bool enabled) {
    return _repository.setAlertsEnabled(id, enabled);
  }
}
