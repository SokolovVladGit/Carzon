import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../entities/filter_alert_settings.dart';

abstract interface class FilterAlertsRepository {
  Future<Result<FilterAlertSettings?>> loadMine();

  Future<Result<FilterAlertSettings>> saveCriteria(
    ListingDiscoveryCriteria criteria,
  );

  Future<Result<FilterAlertSettings>> clearPersistedCriteria();
}
