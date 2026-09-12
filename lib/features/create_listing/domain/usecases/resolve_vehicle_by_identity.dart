import '../../../../core/utils/result.dart';
import '../entities/manual_smart_fill_result.dart';
import '../repositories/manual_smart_fill_repository.dart';

class ResolveVehicleByIdentity {
  ResolveVehicleByIdentity(this._repository);

  final ManualSmartFillRepository _repository;

  Future<Result<ManualSmartFillResult>> call({
    required String make,
    required String model,
    required int year,
    ManualSmartFillAnswer? answer,
  }) {
    return _repository.resolveByIdentity(
      make: make,
      model: model,
      year: year,
      answer: answer,
    );
  }
}
