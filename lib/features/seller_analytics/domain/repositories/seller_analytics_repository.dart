import '../../../../core/utils/result.dart';
import '../entities/seller_analytics_period.dart';
import '../entities/seller_analytics_snapshot.dart';
import '../entities/seller_demand_snapshot.dart';
import '../entities/seller_engagement_snapshot.dart';

abstract class SellerAnalyticsRepository {
  Future<Result<SellerAnalyticsSnapshot>> load(SellerAnalyticsPeriod period);

  Future<Result<SellerEngagementSnapshot>> loadEngagement(
    SellerAnalyticsPeriod period,
  );

  Future<Result<SellerDemandSnapshot>> loadDemand();
}
