import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/manual_smart_fill_refinement.dart';
import '../../domain/entities/manual_smart_fill_result.dart';
import '../../domain/repositories/manual_smart_fill_repository.dart';
import '../datasources/manual_smart_fill_remote_datasource.dart';

class ManualSmartFillRepositoryImpl implements ManualSmartFillRepository {
  ManualSmartFillRepositoryImpl(this._remote);

  final ManualSmartFillRemoteDataSource _remote;

  @override
  Future<Result<ManualSmartFillResult>> resolveByIdentity({
    required String make,
    required String model,
    required int year,
    List<ManualSmartFillRefinementAnswer> answers = const [],
    List<ManualSmartFillRefinementKind> skippedKinds = const [],
  }) async {
    try {
      final result = await _remote.resolveByIdentity(
        make: make,
        model: model,
        year: year,
        answers: answers,
        skippedKinds: skippedKinds,
      );
      return Success(result);
    } on ManualSmartFillServerException {
      return const FailureResult(ManualSmartFillFailure());
    } catch (_) {
      return const FailureResult(ManualSmartFillFailure());
    }
  }
}
