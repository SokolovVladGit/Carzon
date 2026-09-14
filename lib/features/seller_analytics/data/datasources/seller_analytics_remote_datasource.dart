import '../../domain/entities/seller_analytics_daily_point.dart';
import '../../domain/entities/seller_analytics_period.dart';
import '../../domain/entities/seller_analytics_summary.dart';
import '../../domain/entities/seller_engagement_summary.dart';
import '../../domain/entities/seller_inventory_demand.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_engagement.dart';
import '../../domain/entities/seller_listing_performance.dart';

abstract class SellerAnalyticsRemoteDataSource {
  Future<SellerAnalyticsSummary> fetchSummary(SellerAnalyticsPeriod period);

  Future<List<SellerAnalyticsDailyPoint>> fetchDaily(
    SellerAnalyticsPeriod period,
  );

  Future<List<SellerListingPerformance>> fetchListings(
    SellerAnalyticsPeriod period,
  );

  Future<SellerEngagementSummary> fetchEngagementSummary(
    SellerAnalyticsPeriod period,
  );

  Future<List<SellerListingEngagement>> fetchEngagementListings(
    SellerAnalyticsPeriod period,
  );

  Future<SellerInventoryDemand> fetchInventoryDemand();

  Future<List<SellerListingDemand>> fetchListingDemand();
}
