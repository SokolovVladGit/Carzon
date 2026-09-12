import '../../../../core/utils/result.dart';
import '../entities/manual_smart_fill_result.dart';

abstract interface class ManualSmartFillRepository {
  Future<Result<ManualSmartFillResult>> resolveByIdentity({
    required String make,
    required String model,
    required int year,
    ManualSmartFillAnswer? answer,
  });
}
