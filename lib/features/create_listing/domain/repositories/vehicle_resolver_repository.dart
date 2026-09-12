import '../../../../core/utils/result.dart';
import '../entities/vehicle_resolve_result.dart';

abstract interface class VehicleResolverRepository {
  Future<Result<VehicleResolveResult>> resolveVehicle({required String vin});
}
