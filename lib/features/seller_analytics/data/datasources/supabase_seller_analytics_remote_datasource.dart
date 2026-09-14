import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/seller_analytics_daily_point.dart';
import '../../domain/entities/seller_analytics_period.dart';
import '../../domain/entities/seller_analytics_summary.dart';
import '../../domain/entities/seller_engagement_summary.dart';
import '../../domain/entities/seller_inventory_demand.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_engagement.dart';
import '../../domain/entities/seller_listing_performance.dart';
import '../mappers/seller_analytics_mapper.dart';
import 'seller_analytics_remote_datasource.dart';

class SupabaseSellerAnalyticsRemoteDataSource
    implements SellerAnalyticsRemoteDataSource {
  SupabaseSellerAnalyticsRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String _rpcSummary = 'get_my_seller_analytics_summary';
  static const String _rpcDaily = 'get_my_seller_analytics_daily';
  static const String _rpcListings = 'get_my_seller_analytics_listings';
  static const String _rpcEngagementSummary =
      'get_my_seller_engagement_summary';
  static const String _rpcEngagementListings =
      'get_my_seller_engagement_listings';
  static const String _rpcListingDemand = 'get_my_seller_listing_demand';
  static const String _rpcInventoryDemand = 'get_my_seller_inventory_demand';

  @override
  Future<SellerAnalyticsSummary> fetchSummary(
    SellerAnalyticsPeriod period,
  ) async {
    try {
      final row = _requireRow(
        await _supabase.client.rpc(_rpcSummary, params: _periodParams(period)),
        _rpcSummary,
      );
      return sellerAnalyticsSummaryFromRow(row);
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load seller analytics summary',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<SellerAnalyticsDailyPoint>> fetchDaily(
    SellerAnalyticsPeriod period,
  ) async {
    try {
      final rows = _rows(
        await _supabase.client.rpc(_rpcDaily, params: _periodParams(period)),
        _rpcDaily,
      );
      return [for (final row in rows) sellerAnalyticsDailyPointFromRow(row)];
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load seller analytics daily series',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<SellerListingPerformance>> fetchListings(
    SellerAnalyticsPeriod period,
  ) async {
    try {
      final rows = _rows(
        await _supabase.client.rpc(_rpcListings, params: _periodParams(period)),
        _rpcListings,
      );
      return [for (final row in rows) sellerListingPerformanceFromRow(row)];
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load seller analytics listings',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<SellerEngagementSummary> fetchEngagementSummary(
    SellerAnalyticsPeriod period,
  ) async {
    try {
      final row = _requireRow(
        await _supabase.client.rpc(
          _rpcEngagementSummary,
          params: _periodParams(period),
        ),
        _rpcEngagementSummary,
      );
      return sellerEngagementSummaryFromRow(row);
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load seller engagement summary',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<SellerListingEngagement>> fetchEngagementListings(
    SellerAnalyticsPeriod period,
  ) async {
    try {
      final rows = _rows(
        await _supabase.client.rpc(
          _rpcEngagementListings,
          params: _periodParams(period),
        ),
        _rpcEngagementListings,
      );
      return [for (final row in rows) sellerListingEngagementFromRow(row)];
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load seller engagement listings',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<SellerInventoryDemand> fetchInventoryDemand() async {
    try {
      final row = _requireRow(
        await _supabase.client.rpc(_rpcInventoryDemand),
        _rpcInventoryDemand,
      );
      return sellerInventoryDemandFromRow(row);
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load seller inventory demand',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<SellerListingDemand>> fetchListingDemand() async {
    try {
      final rows = _rows(
        await _supabase.client.rpc(_rpcListingDemand),
        _rpcListingDemand,
      );
      return [for (final row in rows) sellerListingDemandFromRow(row)];
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load seller listing demand',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static Map<String, dynamic> _periodParams(SellerAnalyticsPeriod period) {
    return <String, dynamic>{'p_period_days': period.days};
  }

  static Map<String, dynamic> _requireRow(dynamic data, String rpc) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    throw ServerException('Unexpected response from $rpc.');
  }

  static List<Map<String, dynamic>> _rows(dynamic data, String rpc) {
    if (data == null) return const [];
    if (data is! List) {
      throw ServerException('Unexpected response from $rpc.');
    }
    final rows = <Map<String, dynamic>>[];
    for (final item in data) {
      if (item is! Map) {
        throw ServerException('Unexpected row from $rpc.');
      }
      rows.add(Map<String, dynamic>.from(item));
    }
    return rows;
  }
}
