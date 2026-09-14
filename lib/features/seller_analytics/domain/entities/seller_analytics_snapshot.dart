import 'package:equatable/equatable.dart';

import 'seller_analytics_daily_point.dart';
import 'seller_analytics_period.dart';
import 'seller_analytics_summary.dart';
import 'seller_listing_performance.dart';

/// One consistent load of period-scoped seller analytics.
class SellerAnalyticsSnapshot extends Equatable {
  const SellerAnalyticsSnapshot({
    required this.period,
    required this.summary,
    required this.daily,
    required this.listings,
  });

  final SellerAnalyticsPeriod period;
  final SellerAnalyticsSummary summary;
  final List<SellerAnalyticsDailyPoint> daily;
  final List<SellerListingPerformance> listings;

  bool get isEmptySeller => !summary.hasListingUniverse && listings.isEmpty;

  @override
  List<Object?> get props => [period, summary, daily, listings];
}
