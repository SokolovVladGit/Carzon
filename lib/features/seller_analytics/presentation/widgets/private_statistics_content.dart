import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../bloc/seller_analytics_cubit.dart';
import '../bloc/seller_analytics_state.dart';
import 'statistics_chart_card.dart';
import 'statistics_listing_row.dart';
import 'statistics_period_selector.dart';
import 'statistics_summary_metrics.dart';

class PrivateStatisticsContent extends StatelessWidget {
  const PrivateStatisticsContent({super.key, required this.state});

  final SellerAnalyticsState state;

  static const Key rootKey = ValueKey<String>('statistics_private_dashboard');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final summary = state.summary!;

    return ListView(
      key: rootKey,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        kFloatingCapsuleNavClearance,
      ),
      children: [
        StatisticsPeriodSelector(
          selected: state.period,
          onChanged: (next) =>
              context.read<SellerAnalyticsCubit>().selectPeriod(next),
        ),
        const SizedBox(height: 16),
        StatisticsSummaryMetrics(summary: summary),
        const SizedBox(height: 16),
        StatisticsChartCard(
          points: state.daily,
          semanticLabel: l10n.statisticsChartSemantics(summary.periodViews),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.statisticsYourListings,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.08,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppTheme.softCardShadow(scheme),
          ),
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: BorderSide(color: AppTheme.softCardBorderColor(scheme)),
            ),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.softCardGroupedGradient(scheme),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < state.listings.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 18,
                        endIndent: 18,
                        color: scheme.outline.withValues(
                          alpha: scheme.brightness == Brightness.dark
                              ? 0.10
                              : 0.06,
                        ),
                      ),
                    StatisticsListingRow(
                      key: ValueKey<String>(
                        'statistics_listing_${state.listings[i].listingId}',
                      ),
                      listing: state.listings[i],
                      now: now,
                      onTap: () => context.push(
                        AppRoutes.listingDetailsPath(
                          state.listings[i].listingId,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
