import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../entities/saved_search.dart';

abstract interface class SavedSearchesRepository {
  Future<Result<List<SavedSearch>>> list();

  Future<Result<SavedSearch>> create({
    required String name,
    required ListingDiscoveryCriteria criteria,
    required bool alertsEnabled,
  });

  Future<Result<SavedSearch>> setAlertsEnabled(String id, bool enabled);

  Future<Result<void>> delete(String id);

  Future<Result<SavedSearch?>> findByCriteria(
    ListingDiscoveryCriteria criteria,
  );
}
