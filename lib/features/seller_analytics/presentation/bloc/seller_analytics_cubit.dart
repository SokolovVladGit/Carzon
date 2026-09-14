import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../sellers/domain/entities/seller_type.dart';
import '../../domain/entities/seller_analytics_daily_point.dart';
import '../../domain/entities/seller_analytics_period.dart';
import '../../domain/entities/seller_analytics_summary.dart';
import '../../domain/entities/seller_engagement_summary.dart';
import '../../domain/entities/seller_inventory_demand.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_engagement.dart';
import '../../domain/entities/seller_listing_performance.dart';
import '../../domain/usecases/get_seller_analytics.dart';
import '../../domain/usecases/get_seller_demand.dart';
import '../../domain/usecases/get_seller_engagement.dart';
import '../utils/statistics_demand.dart';
import '../utils/statistics_engagement.dart';
import 'seller_analytics_state.dart';

class SellerAnalyticsCubit extends Cubit<SellerAnalyticsState> {
  SellerAnalyticsCubit({
    required GetSellerAnalytics getSellerAnalytics,
    required GetSellerEngagement getSellerEngagement,
    required GetSellerDemand getSellerDemand,
  }) : _getSellerAnalytics = getSellerAnalytics,
       _getSellerEngagement = getSellerEngagement,
       _getSellerDemand = getSellerDemand,
       super(const SellerAnalyticsState());

  final GetSellerAnalytics _getSellerAnalytics;
  final GetSellerEngagement _getSellerEngagement;
  final GetSellerDemand _getSellerDemand;
  int _generation = 0;

  Future<void> load({
    SellerAnalyticsPeriod? period,
    bool retainDemand = false,
  }) async {
    final nextPeriod = period ?? state.period;
    final generation = ++_generation;
    final retainedStatus = retainDemand
        ? state.demandStatus
        : SellerDemandLoadStatus.idle;
    final retainedInventory = retainDemand ? state.inventoryDemand : null;
    final retainedListings = retainDemand
        ? state.listingDemands
        : const <String, SellerListingDemand>{};

    emit(
      SellerAnalyticsState(
        status: SellerAnalyticsStatus.loading,
        period: nextPeriod,
        demandStatus: retainedStatus,
        inventoryDemand: retainedInventory,
        listingDemands: retainedListings,
      ),
    );

    final result = await _getSellerAnalytics(nextPeriod);
    if (isClosed || generation != _generation) return;

    switch (result) {
      case FailureResult():
        emit(
          SellerAnalyticsState(
            status: SellerAnalyticsStatus.error,
            period: nextPeriod,
          ),
        );
      case Success(:final value):
        final analytics = value;
        if (analytics.summary.sellerType != SellerType.dealer) {
          emit(
            SellerAnalyticsState(
              status: SellerAnalyticsStatus.loaded,
              period: nextPeriod,
              summary: analytics.summary,
              daily: analytics.daily,
              listings: analytics.listings,
            ),
          );
          return;
        }

        final engagementResult = await _getSellerEngagement(nextPeriod);
        if (isClosed || generation != _generation) return;
        switch (engagementResult) {
          case FailureResult():
            emit(
              SellerAnalyticsState(
                status: SellerAnalyticsStatus.error,
                period: nextPeriod,
              ),
            );
          case Success(:final value):
            final engagements = indexListingEngagements(value.listings);
            final shouldFetchDemand = analytics.summary.activeCount > 0;
            if (!shouldFetchDemand) {
              emit(
                _dealerLoaded(
                  period: nextPeriod,
                  summary: analytics.summary,
                  daily: analytics.daily,
                  listings: analytics.listings,
                  engagementSummary: value.summary,
                  listingEngagements: engagements,
                ),
              );
              return;
            }

            final canReuseDemand =
                retainDemand &&
                (retainedStatus == SellerDemandLoadStatus.loaded ||
                    retainedStatus == SellerDemandLoadStatus.unavailable);
            if (canReuseDemand) {
              emit(
                _dealerLoaded(
                  period: nextPeriod,
                  summary: analytics.summary,
                  daily: analytics.daily,
                  listings: analytics.listings,
                  engagementSummary: value.summary,
                  listingEngagements: engagements,
                  demandStatus: retainedStatus,
                  inventoryDemand: retainedInventory,
                  listingDemands: retainedListings,
                ),
              );
              return;
            }

            emit(
              _dealerLoaded(
                period: nextPeriod,
                summary: analytics.summary,
                daily: analytics.daily,
                listings: analytics.listings,
                engagementSummary: value.summary,
                listingEngagements: engagements,
                demandStatus: SellerDemandLoadStatus.loading,
              ),
            );

            await _resolveDemand(
              generation: generation,
              period: nextPeriod,
              summary: analytics.summary,
              daily: analytics.daily,
              listings: analytics.listings,
              engagementSummary: value.summary,
              listingEngagements: engagements,
            );
        }
    }
  }

  Future<void> selectPeriod(SellerAnalyticsPeriod period) {
    if (period == state.period &&
        state.status == SellerAnalyticsStatus.loaded) {
      return Future<void>.value();
    }
    return load(period: period, retainDemand: true);
  }

  Future<void> retry() => load(period: state.period);

  Future<void> retryDemand() async {
    if (isClosed) return;
    if (state.status != SellerAnalyticsStatus.loaded) return;
    final summary = state.summary;
    final engagementSummary = state.engagementSummary;
    if (summary == null || engagementSummary == null) return;
    if (summary.sellerType != SellerType.dealer) return;
    if (summary.activeCount <= 0) return;
    final generation = _generation;
    emit(
      _dealerLoaded(
        period: state.period,
        summary: summary,
        daily: state.daily,
        listings: state.listings,
        engagementSummary: engagementSummary,
        listingEngagements: state.listingEngagements,
        demandStatus: SellerDemandLoadStatus.loading,
      ),
    );
    await _resolveDemand(
      generation: generation,
      period: state.period,
      summary: summary,
      daily: state.daily,
      listings: state.listings,
      engagementSummary: engagementSummary,
      listingEngagements: state.listingEngagements,
    );
  }

  Future<void> _resolveDemand({
    required int generation,
    required SellerAnalyticsPeriod period,
    required SellerAnalyticsSummary summary,
    required List<SellerAnalyticsDailyPoint> daily,
    required List<SellerListingPerformance> listings,
    required SellerEngagementSummary engagementSummary,
    required Map<String, SellerListingEngagement> listingEngagements,
  }) async {
    final demandResult = await _getSellerDemand();
    if (isClosed || generation != _generation) return;
    switch (demandResult) {
      case FailureResult():
        emit(
          _dealerLoaded(
            period: period,
            summary: summary,
            daily: daily,
            listings: listings,
            engagementSummary: engagementSummary,
            listingEngagements: listingEngagements,
            demandStatus: SellerDemandLoadStatus.unavailable,
          ),
        );
      case Success(:final value):
        emit(
          _dealerLoaded(
            period: period,
            summary: summary,
            daily: daily,
            listings: listings,
            engagementSummary: engagementSummary,
            listingEngagements: listingEngagements,
            demandStatus: SellerDemandLoadStatus.loaded,
            inventoryDemand: value.inventory,
            listingDemands: indexListingDemands(value.listings),
          ),
        );
    }
  }

  static SellerAnalyticsState _dealerLoaded({
    required SellerAnalyticsPeriod period,
    required SellerAnalyticsSummary summary,
    required List<SellerAnalyticsDailyPoint> daily,
    required List<SellerListingPerformance> listings,
    required SellerEngagementSummary engagementSummary,
    required Map<String, SellerListingEngagement> listingEngagements,
    SellerDemandLoadStatus demandStatus = SellerDemandLoadStatus.idle,
    SellerInventoryDemand? inventoryDemand,
    Map<String, SellerListingDemand> listingDemands = const {},
  }) {
    return SellerAnalyticsState(
      status: SellerAnalyticsStatus.loaded,
      period: period,
      summary: summary,
      daily: daily,
      listings: listings,
      engagementSummary: engagementSummary,
      listingEngagements: listingEngagements,
      demandStatus: demandStatus,
      inventoryDemand: inventoryDemand,
      listingDemands: listingDemands,
    );
  }
}
