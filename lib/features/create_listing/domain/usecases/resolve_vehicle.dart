import '../../../../core/utils/result.dart';
import '../entities/vehicle_resolve_result.dart';
import '../repositories/vehicle_resolver_repository.dart';

class ResolveVehicle {
  ResolveVehicle(this._repository);

  final VehicleResolverRepository _repository;

  Future<Result<VehicleResolveResult>> call({required String vin}) =>
      _repository.resolveVehicle(vin: vin);
}
