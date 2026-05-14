import '../../../../core/utils/result.dart';
import '../entities/filter_alert_settings.dart';
import '../repositories/filter_alerts_repository.dart';

class SetFilterAlertNotificationsEnabled {
  SetFilterAlertNotificationsEnabled(this._repository);

  final FilterAlertsRepository _repository;

  Future<Result<FilterAlertSettings>> call(bool enabled) =>
      _repository.setNotificationsEnabled(enabled);
}
