import '../../../../core/utils/result.dart';
import '../entities/filter_alert_settings.dart';
import '../repositories/filter_alerts_repository.dart';

class ClearFilterAlertCriteria {
  ClearFilterAlertCriteria(this._repository);

  final FilterAlertsRepository _repository;

  Future<Result<FilterAlertSettings>> call() =>
      _repository.clearPersistedCriteria();
}
