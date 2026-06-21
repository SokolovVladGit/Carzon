import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../entities/saved_search.dart';
import '../repositories/saved_searches_repository.dart';

class CreateSavedSearch {
  CreateSavedSearch(this._repository);

  final SavedSearchesRepository _repository;

  Future<Result<SavedSearch>> call({
    required String name,
    required ListingDiscoveryCriteria criteria,
    required bool alertsEnabled,
  }) {
    return _repository.create(
      name: name,
      criteria: criteria,
      alertsEnabled: alertsEnabled,
    );
  }
}
