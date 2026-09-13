import '../../../../core/utils/result.dart';
import '../entities/manual_smart_fill_refinement.dart';
import '../entities/manual_smart_fill_result.dart';
import '../repositories/manual_smart_fill_repository.dart';

class ResolveVehicleByIdentity {
  ResolveVehicleByIdentity(this._repository);

  final ManualSmartFillRepository _repository;

  Future<Result<ManualSmartFillResult>> call({
    required String make,
    required String model,
    required int year,
    List<ManualSmartFillRefinementAnswer> answers = const [],
    List<ManualSmartFillRefinementKind> skippedKinds = const [],
  }) {
    return _repository.resolveByIdentity(
      make: make,
      model: model,
      year: year,
      answers: answers,
      skippedKinds: skippedKinds,
    );
  }
}
