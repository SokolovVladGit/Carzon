import 'package:equatable/equatable.dart';

import '../../domain/entities/seller_analytics_daily_point.dart';
import '../../domain/entities/seller_analytics_period.dart';
import '../../domain/entities/seller_analytics_summary.dart';
import '../../domain/entities/seller_engagement_summary.dart';
import '../../domain/entities/seller_inventory_demand.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_engagement.dart';
import '../../domain/entities/seller_listing_performance.dart';

enum SellerAnalyticsStatus { initial, loading, loaded, error }

enum SellerDemandLoadStatus { idle, loading, loaded, unavailable }

class SellerAnalyticsState extends Equatable {
  const SellerAnalyticsState({
    this.status = SellerAnalyticsStatus.initial,
    this.period = SellerAnalyticsPeriod.defaultPeriod,
    this.summary,
    this.daily = const [],
    this.listings = const [],
    this.engagementSummary,
    this.listingEngagements = const {},
    this.demandStatus = SellerDemandLoadStatus.idle,
    this.inventoryDemand,
    this.listingDemands = const {},
  });

  final SellerAnalyticsStatus status;
  final SellerAnalyticsPeriod period;
  final SellerAnalyticsSummary? summary;
  final List<SellerAnalyticsDailyPoint> daily;
  final List<SellerListingPerformance> listings;
  final SellerEngagementSummary? engagementSummary;
  final Map<String, SellerListingEngagement> listingEngagements;
  final SellerDemandLoadStatus demandStatus;
  final SellerInventoryDemand? inventoryDemand;
  final Map<String, SellerListingDemand> listingDemands;

  bool get isEmptySeller {
    final current = summary;
    if (current == null) return false;
    return !current.hasListingUniverse && listings.isEmpty;
  }

  SellerListingEngagement engagementFor(String listingId) {
    return listingEngagements[listingId] ??
        SellerListingEngagement.zero(listingId);
  }

  SellerListingDemand? demandFor(String listingId) {
    return listingDemands[listingId];
  }

  SellerAnalyticsState copyWith({
    SellerAnalyticsStatus? status,
    SellerAnalyticsPeriod? period,
    SellerAnalyticsSummary? summary,
    List<SellerAnalyticsDailyPoint>? daily,
    List<SellerListingPerformance>? listings,
    SellerEngagementSummary? engagementSummary,
    Map<String, SellerListingEngagement>? listingEngagements,
    SellerDemandLoadStatus? demandStatus,
    SellerInventoryDemand? inventoryDemand,
    Map<String, SellerListingDemand>? listingDemands,
    bool clearPayload = false,
    bool clearDemand = false,
  }) {
    return SellerAnalyticsState(
      status: status ?? this.status,
      period: period ?? this.period,
      summary: clearPayload ? null : (summary ?? this.summary),
      daily: clearPayload ? const [] : (daily ?? this.daily),
      listings: clearPayload ? const [] : (listings ?? this.listings),
      engagementSummary: clearPayload
          ? null
          : (engagementSummary ?? this.engagementSummary),
      listingEngagements: clearPayload
          ? const {}
          : (listingEngagements ?? this.listingEngagements),
      demandStatus: clearDemand
          ? SellerDemandLoadStatus.idle
          : (demandStatus ?? this.demandStatus),
      inventoryDemand: clearDemand
          ? null
          : (inventoryDemand ?? this.inventoryDemand),
      listingDemands: clearDemand
          ? const {}
          : (listingDemands ?? this.listingDemands),
    );
  }

  @override
  List<Object?> get props => [
    status,
    period,
    summary,
    daily,
    listings,
    engagementSummary,
    listingEngagements,
    demandStatus,
    inventoryDemand,
    listingDemands,
  ];
}
