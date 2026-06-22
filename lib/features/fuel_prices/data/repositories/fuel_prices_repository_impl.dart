import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/fuel_price_snapshot.dart';
import '../../domain/repositories/fuel_prices_repository.dart';
import '../datasources/fuel_prices_remote_datasource.dart';

class FuelPricesRepositoryImpl implements FuelPricesRepository {
  FuelPricesRepositoryImpl(this._remote)
    : _logger = AppLogger('FuelPricesRepository');

  final FuelPricesRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<List<FuelPriceSnapshot>>> fetchFuelPricesForApp() async {
    try {
      final rows = await _remote.fetchFuelPricesForApp();
      return Success(rows);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('fetchFuelPricesForApp unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load fuel prices.'),
      );
    }
  }
}
