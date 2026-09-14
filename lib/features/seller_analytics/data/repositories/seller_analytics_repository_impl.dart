import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/seller_analytics_daily_point.dart';
import '../../domain/entities/seller_analytics_period.dart';
import '../../domain/entities/seller_analytics_snapshot.dart';
import '../../domain/entities/seller_analytics_summary.dart';
import '../../domain/entities/seller_demand_snapshot.dart';
import '../../domain/entities/seller_engagement_snapshot.dart';
import '../../domain/entities/seller_engagement_summary.dart';
import '../../domain/entities/seller_inventory_demand.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_engagement.dart';
import '../../domain/entities/seller_listing_performance.dart';
import '../../domain/repositories/seller_analytics_repository.dart';
import '../datasources/seller_analytics_remote_datasource.dart';

class SellerAnalyticsRepositoryImpl implements SellerAnalyticsRepository {
  SellerAnalyticsRepositoryImpl(this._remote)
    : _logger = AppLogger('SellerAnalyticsRepository');

  final SellerAnalyticsRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<SellerAnalyticsSnapshot>> load(
    SellerAnalyticsPeriod period,
  ) async {
    try {
      final results = await Future.wait<Object>([
        _remote.fetchSummary(period),
        _remote.fetchDaily(period),
        _remote.fetchListings(period),
      ]);
      return Success(
        SellerAnalyticsSnapshot(
          period: period,
          summary: results[0] as SellerAnalyticsSummary,
          daily: results[1] as List<SellerAnalyticsDailyPoint>,
          listings: results[2] as List<SellerListingPerformance>,
        ),
      );
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('load seller analytics unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load seller analytics.'),
      );
    }
  }

  @override
  Future<Result<SellerEngagementSnapshot>> loadEngagement(
    SellerAnalyticsPeriod period,
  ) async {
    try {
      final results = await Future.wait<Object>([
        _remote.fetchEngagementSummary(period),
        _remote.fetchEngagementListings(period),
      ]);
      return Success(
        SellerEngagementSnapshot(
          summary: results[0] as SellerEngagementSummary,
          listings: results[1] as List<SellerListingEngagement>,
        ),
      );
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('load seller engagement unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load seller engagement.'),
      );
    }
  }

  @override
  Future<Result<SellerDemandSnapshot>> loadDemand() async {
    try {
      final results = await Future.wait<Object>([
        _remote.fetchInventoryDemand(),
        _remote.fetchListingDemand(),
      ]);
      return Success(
        SellerDemandSnapshot(
          inventory: results[0] as SellerInventoryDemand,
          listings: results[1] as List<SellerListingDemand>,
        ),
      );
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('load seller demand unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load seller demand.'),
      );
    }
  }
}
