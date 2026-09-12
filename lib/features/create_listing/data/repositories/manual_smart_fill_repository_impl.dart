import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
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
    ManualSmartFillAnswer? answer,
  }) async {
    try {
      final result = await _remote.resolveByIdentity(
        make: make,
        model: model,
        year: year,
        answer: answer,
      );
      return Success(result);
    } on ManualSmartFillServerException {
      return const FailureResult(ManualSmartFillFailure());
    } catch (_) {
      return const FailureResult(ManualSmartFillFailure());
    }
  }
}
