import '../../../../core/utils/result.dart';
import '../entities/seller_analytics_period.dart';
import '../entities/seller_engagement_snapshot.dart';
import '../repositories/seller_analytics_repository.dart';

class GetSellerEngagement {
  const GetSellerEngagement(this._repository);

  final SellerAnalyticsRepository _repository;

  Future<Result<SellerEngagementSnapshot>> call(SellerAnalyticsPeriod period) =>
      _repository.loadEngagement(period);
}
