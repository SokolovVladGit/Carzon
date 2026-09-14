import '../../../../core/utils/result.dart';
import '../entities/seller_analytics_period.dart';
import '../entities/seller_analytics_snapshot.dart';
import '../repositories/seller_analytics_repository.dart';

class GetSellerAnalytics {
  const GetSellerAnalytics(this._repository);

  final SellerAnalyticsRepository _repository;

  Future<Result<SellerAnalyticsSnapshot>> call(SellerAnalyticsPeriod period) =>
      _repository.load(period);
}
