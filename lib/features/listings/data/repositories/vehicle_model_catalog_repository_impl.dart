import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/vehicle_model_catalog_repository.dart';
import '../datasources/vehicle_model_catalog_remote_datasource.dart';

class VehicleModelCatalogRepositoryImpl
    implements VehicleModelCatalogRepository {
  VehicleModelCatalogRepositoryImpl(this._remote)
    : _logger = AppLogger('VehicleModelCatalogRepository');

  final VehicleModelCatalogRemoteDataSource _remote;
  final AppLogger _logger;
  final Map<String, List<String>> _cache = {};

  @override
  Future<Result<List<String>>> listVehicleModelsForMake(String make) async {
    final key = make.trim().toLowerCase();
    if (key.isEmpty) {
      return const Success(<String>[]);
    }
    final cached = _cache[key];
    if (cached != null) {
      return Success(List<String>.from(cached));
    }
    try {
      final models = await _remote.listVehicleModelsForMake(make.trim());
      _cache[key] = List<String>.unmodifiable(models);
      return Success(List<String>.from(models));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('listVehicleModelsForMake unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load vehicle models.'),
      );
    }
  }
}
