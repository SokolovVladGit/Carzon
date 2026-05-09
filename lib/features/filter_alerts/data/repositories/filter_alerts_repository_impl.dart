import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../domain/entities/filter_alert_settings.dart';
import '../../domain/repositories/filter_alerts_repository.dart';
import '../datasources/filter_alerts_remote_datasource.dart';

class FilterAlertsRepositoryImpl implements FilterAlertsRepository {
  FilterAlertsRepositoryImpl(this._remote)
      : _logger = AppLogger('FilterAlertsRepository');

  final FilterAlertsRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<FilterAlertSettings?>> loadMine() async {
    try {
      final row = await _remote.fetchMine();
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('loadMine failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load filter alert settings.'),
      );
    }
  }

  @override
  Future<Result<FilterAlertSettings>> saveCriteria(
    ListingDiscoveryCriteria criteria,
  ) async {
    try {
      final row = await _remote.upsertCriteria(criteria);
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('saveCriteria failed', e, st);
      return const FailureResult(UnknownFailure('Failed to save filter.'));
    }
  }

  @override
  Future<Result<FilterAlertSettings>> clearPersistedCriteria() async {
    try {
      final row = await _remote.upsertClearsCriteria();
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('clearPersistedCriteria failed', e, st);
      return const FailureResult(UnknownFailure('Failed to clear filter.'));
    }
  }
}
