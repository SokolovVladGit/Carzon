import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../domain/entities/saved_search.dart';
import '../../domain/repositories/saved_searches_repository.dart';
import '../datasources/filter_alerts_remote_datasource.dart';

class SavedSearchesRepositoryImpl implements SavedSearchesRepository {
  SavedSearchesRepositoryImpl(this._remote)
    : _logger = AppLogger('SavedSearchesRepository');

  final SavedSearchesRemoteDataSource _remote;
  final AppLogger _logger;

  Failure _mapServer(ServerException e) {
    return switch (e.message) {
      'max_saved_searches_reached' => const ServerFailure(
        'max_saved_searches_reached',
      ),
      'duplicate_saved_search' => const ServerFailure('duplicate_saved_search'),
      'Not authenticated' => const AuthFailure('Not authenticated'),
      _ => ServerFailure(
        e.message,
        postgrestCode: e.postgrestCode,
        diagnosticsDetails: e.diagnosticsDetails,
      ),
    };
  }

  @override
  Future<Result<List<SavedSearch>>> list() async {
    try {
      final rows = await _remote.listMine();
      return Success(rows);
    } on ServerException catch (e) {
      return FailureResult(_mapServer(e));
    } catch (e, st) {
      _logger.error('list failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load saved searches.'),
      );
    }
  }

  @override
  Future<Result<SavedSearch>> create({
    required String name,
    required ListingDiscoveryCriteria criteria,
    required bool alertsEnabled,
  }) async {
    try {
      final row = await _remote.create(
        name: name,
        criteria: criteria,
        alertsEnabled: alertsEnabled,
      );
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(_mapServer(e));
    } catch (e, st) {
      _logger.error('create failed', e, st);
      return const FailureResult(UnknownFailure('Failed to save search.'));
    }
  }

  @override
  Future<Result<SavedSearch>> setAlertsEnabled(String id, bool enabled) async {
    try {
      final row = await _remote.setAlertsEnabled(id, enabled);
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(_mapServer(e));
    } catch (e, st) {
      _logger.error('setAlertsEnabled failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to update saved search alerts.'),
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _remote.delete(id);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(_mapServer(e));
    } catch (e, st) {
      _logger.error('delete failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to delete saved search.'),
      );
    }
  }

  @override
  Future<Result<SavedSearch?>> findByCriteria(
    ListingDiscoveryCriteria criteria,
  ) async {
    try {
      final row = await _remote.findByCriteria(criteria);
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(_mapServer(e));
    } catch (e, st) {
      _logger.error('findByCriteria failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to find saved search.'),
      );
    }
  }
}
