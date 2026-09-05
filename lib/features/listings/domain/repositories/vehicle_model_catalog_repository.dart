import '../../../../core/utils/result.dart';

/// Public read-only catalog of canonical passenger model lines.
abstract interface class VehicleModelCatalogRepository {
  /// Active model-line names for [make], already trimmed and de-duplicated.
  Future<Result<List<String>>> listVehicleModelsForMake(String make);
}
