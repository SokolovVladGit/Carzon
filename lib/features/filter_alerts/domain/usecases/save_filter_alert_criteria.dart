import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../entities/filter_alert_settings.dart';
import '../repositories/filter_alerts_repository.dart';

class SaveFilterAlertCriteria {
  SaveFilterAlertCriteria(this._repository);

  final FilterAlertsRepository _repository;

  Future<Result<FilterAlertSettings>> call(
    ListingDiscoveryCriteria criteria, {
    required bool notificationsEnabled,
  }) =>
      _repository.saveCriteria(
        criteria,
        notificationsEnabled: notificationsEnabled,
      );
}
