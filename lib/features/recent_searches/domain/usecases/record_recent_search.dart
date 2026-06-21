import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../listings/domain/filter_alert_catalog_criteria_compare.dart';
import '../../presentation/cubit/recent_searches_cubit.dart';
import '../entities/recent_search_entry.dart';
import '../repositories/recent_searches_repository.dart';

/// Persists a meaningful discovery search and syncs the global cubit.
class RecordRecentSearch {
  RecordRecentSearch(this._repository, this._cubit);

  final RecentSearchesRepository _repository;
  final RecentSearchesCubit _cubit;

  Future<void> call(
    ListingDiscoveryCriteria criteria, {
    DateTime? searchedAt,
  }) async {
    if (!discoveryCriteriaEligibleForFilterAlertPersist(criteria)) {
      return;
    }
    final entry = RecentSearchEntry(
      criteria: criteria,
      searchedAt: (searchedAt ?? DateTime.now()).toUtc(),
    );
    final updated = await _repository.record(entry);
    _cubit.syncEntries(updated);
  }
}
