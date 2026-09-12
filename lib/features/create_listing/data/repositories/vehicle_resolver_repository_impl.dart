import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/vehicle_resolve_result.dart';

import '../../domain/repositories/vehicle_resolver_repository.dart';
import '../datasources/vehicle_resolver_remote_datasource.dart';

class VehicleResolverRepositoryImpl implements VehicleResolverRepository {
  VehicleResolverRepositoryImpl(this._remote);

  final VehicleResolverRemoteDataSource _remote;

  @override
  Future<Result<VehicleResolveResult>> resolveVehicle({
    required String vin,
  }) async {
    try {
      final result = await _remote.resolveVehicle(vin: vin);
      return Success(result);
    } on VehicleResolveServerException catch (e) {
      return FailureResult(VehicleResolveFailure(e.kind));
    } catch (_) {
      return const FailureResult(
        VehicleResolveFailure(VehicleResolveFailureKind.internalError),
      );
    }
  }
}
