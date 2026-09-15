import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../bloc/seller_analytics_cubit.dart';
import '../bloc/seller_analytics_state.dart';
import 'statistics_listing_row.dart';
import 'statistics_summary_metrics.dart';
import 'statistics_surface.dart';

class PrivateStatisticsContent extends StatelessWidget {
  const PrivateStatisticsContent({super.key, required this.state});

  final SellerAnalyticsState state;

  static const Key rootKey = ValueKey<String>('statistics_private_dashboard');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final summary = state.summary!;

    return ListView(
      key: rootKey,
      padding: StatisticsLayout.pagePadding,
      children: [
        StatisticsSummaryMetrics(
          summary: summary,
          points: state.daily,
          chartSemanticLabel: l10n.statisticsChartSemantics(
            summary.periodViews,
          ),
          period: state.period,
          onPeriodChanged: (next) =>
              context.read<SellerAnalyticsCubit>().selectPeriod(next),
        ),
        const SizedBox(height: StatisticsLayout.sectionGap),
        StatisticsSectionTitle(title: l10n.statisticsYourListings),
        const SizedBox(height: StatisticsLayout.listingsTitleGap),
        for (var i = 0; i < state.listings.length; i++) ...[
          if (i > 0) const SizedBox(height: StatisticsLayout.listingGap),
          StatisticsListingCard(
            child: StatisticsListingRow(
              key: ValueKey<String>(
                'statistics_listing_${state.listings[i].listingId}',
              ),
              listing: state.listings[i],
              now: now,
              onTap: () => context.push(
                AppRoutes.listingDetailsPath(state.listings[i].listingId),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
