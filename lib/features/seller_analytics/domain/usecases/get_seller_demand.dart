import '../../../../core/utils/result.dart';
import '../entities/seller_demand_snapshot.dart';
import '../repositories/seller_analytics_repository.dart';

class GetSellerDemand {
  const GetSellerDemand(this._repository);

  final SellerAnalyticsRepository _repository;

  Future<Result<SellerDemandSnapshot>> call() => _repository.loadDemand();
}
