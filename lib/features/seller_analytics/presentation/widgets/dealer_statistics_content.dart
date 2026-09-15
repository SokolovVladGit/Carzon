import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_engagement.dart';
import '../../domain/entities/seller_listing_performance.dart';
import '../bloc/seller_analytics_cubit.dart';
import '../bloc/seller_analytics_state.dart';
import '../utils/statistics_demand.dart';
import '../utils/statistics_inventory.dart';
import 'statistics_demand_cards.dart';
import 'statistics_engagement_cards.dart';
import 'statistics_listing_row.dart';
import 'statistics_summary_metrics.dart';
import 'statistics_surface.dart';

class DealerStatisticsContent extends StatefulWidget {
  const DealerStatisticsContent({super.key, required this.state});

  final SellerAnalyticsState state;

  static const Key rootKey = ValueKey<String>('statistics_dealer_dashboard');
  static const Key topListingsKey = ValueKey<String>('statistics_top_listings');
  static const Key inventoryKey = ValueKey<String>(
    'statistics_inventory_performance',
  );
  static const Key demandKey = StatisticsDemandCard.rootKey;
  static const Key topDemandKey = StatisticsTopDemandCard.rootKey;

  @override
  State<DealerStatisticsContent> createState() =>
      _DealerStatisticsContentState();
}

class _DealerStatisticsContentState extends State<DealerStatisticsContent> {
  StatisticsInventorySort _sort = StatisticsInventorySort.mostInquiries;
  StatisticsInventoryFilter _filter = StatisticsInventoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final summary = widget.state.summary!;
    final top = rankTopListings(widget.state.listings);
    final filtered = filterInventoryListings(widget.state.listings, _filter);
    final sorted = sortInventoryListings(filtered, sort: _sort, now: now);

    return ListView(
      key: DealerStatisticsContent.rootKey,
      padding: StatisticsLayout.pagePadding,
      children: [
        Text(
          l10n.statisticsProfessionalLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 14),
        StatisticsSummaryMetrics(
          summary: summary,
          points: widget.state.daily,
          chartSemanticLabel: l10n.statisticsChartSemantics(
            summary.periodViews,
          ),
          period: widget.state.period,
          onPeriodChanged: (next) =>
              context.read<SellerAnalyticsCubit>().selectPeriod(next),
          showInventoryTotal: true,
        ),
        if (widget.state.engagementSummary != null) ...[
          const SizedBox(height: StatisticsLayout.sectionGap),
          StatisticsGroupedSurface(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatisticsInterestFunnelCard(
                  impressions:
                      widget.state.engagementSummary!.periodImpressions,
                  views: summary.periodViews,
                  inquiries: summary.periodInquiries,
                ),
                const SizedBox(height: 18),
                const StatisticsHairline(),
                const SizedBox(height: 18),
                StatisticsContactActionsCard(
                  phoneActions:
                      widget.state.engagementSummary!.periodPhoneActions,
                  whatsappActions:
                      widget.state.engagementSummary!.periodWhatsappActions,
                  telegramActions:
                      widget.state.engagementSummary!.periodTelegramActions,
                  shares: widget.state.engagementSummary!.periodShares,
                  contactActions:
                      widget.state.engagementSummary!.periodContactActions,
                ),
              ],
            ),
          ),
        ],
        if (widget.state.demandStatus != SellerDemandLoadStatus.idle) ...[
          const SizedBox(height: StatisticsLayout.sectionGap),
          StatisticsDemandCard(
            status: widget.state.demandStatus,
            demand: widget.state.inventoryDemand,
            onRetry:
                widget.state.demandStatus == SellerDemandLoadStatus.unavailable
                ? () => context.read<SellerAnalyticsCubit>().retryDemand()
                : null,
          ),
          if (widget.state.demandStatus == SellerDemandLoadStatus.loaded) ...[
            Builder(
              builder: (context) {
                final topDemand = rankTopDemandListings(
                  widget.state.listings,
                  demands: widget.state.listingDemands,
                );
                if (topDemand.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: StatisticsTopDemandCard(
                    listings: topDemand,
                    demands: widget.state.listingDemands,
                    onTapListing: (id) =>
                        context.push(AppRoutes.listingDetailsPath(id)),
                  ),
                );
              },
            ),
          ],
        ],
        const SizedBox(height: StatisticsLayout.sectionGap),
        StatisticsSectionTitle(title: l10n.statisticsTopListings),
        const SizedBox(height: StatisticsLayout.listingsTitleGap),
        if (top.isEmpty)
          StatisticsGroupedSurface(
            key: DealerStatisticsContent.topListingsKey,
            quiet: true,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Text(
              l10n.statisticsTopListingsEmpty,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          )
        else
          _ListingsCard(
            key: DealerStatisticsContent.topListingsKey,
            listings: top,
            now: now,
            idPrefix: 'statistics_top_listing_',
            engagementFor: widget.state.engagementSummary == null
                ? null
                : widget.state.engagementFor,
            demandFor:
                widget.state.demandStatus == SellerDemandLoadStatus.loaded
                ? _demandForListing
                : null,
          ),
        const SizedBox(height: StatisticsLayout.sectionGap),
        StatisticsSectionTitle(title: l10n.statisticsInventoryPerformance),
        const SizedBox(height: StatisticsLayout.listingsTitleGap),
        _InventoryControls(
          sort: _sort,
          filter: _filter,
          onSort: (value) => setState(() => _sort = value),
          onFilter: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 10),
        _ListingsCard(
          key: DealerStatisticsContent.inventoryKey,
          listings: sorted,
          now: now,
          idPrefix: 'statistics_listing_',
          engagementFor: widget.state.engagementSummary == null
              ? null
              : widget.state.engagementFor,
          demandFor: widget.state.demandStatus == SellerDemandLoadStatus.loaded
              ? _demandForListing
              : null,
        ),
      ],
    );
  }

  SellerListingDemand? _demandForListing(SellerListingPerformance listing) {
    if (listing.status != ListingStatus.active) return null;
    return widget.state.demandFor(listing.listingId);
  }
}

class _InventoryControls extends StatelessWidget {
  const _InventoryControls({
    required this.sort,
    required this.filter,
    required this.onSort,
    required this.onFilter,
  });

  final StatisticsInventorySort sort;
  final StatisticsInventoryFilter filter;
  final ValueChanged<StatisticsInventorySort> onSort;
  final ValueChanged<StatisticsInventoryFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _FilterBar(filter: filter, onFilter: onFilter),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StatisticsInventorySort>(
              key: const ValueKey<String>('statistics_inventory_sort'),
              value: sort,
              borderRadius: BorderRadius.circular(16),
              onChanged: (value) {
                if (value != null) onSort(value);
              },
              items: [
                DropdownMenuItem(
                  value: StatisticsInventorySort.mostInquiries,
                  child: Text(l10n.statisticsSortMostInquiries),
                ),
                DropdownMenuItem(
                  value: StatisticsInventorySort.mostViewed,
                  child: Text(l10n.statisticsSortMostViewed),
                ),
                DropdownMenuItem(
                  value: StatisticsInventorySort.mostFavorited,
                  child: Text(l10n.statisticsSortMostFavorited),
                ),
                DropdownMenuItem(
                  value: StatisticsInventorySort.newest,
                  child: Text(l10n.statisticsSortNewest),
                ),
                DropdownMenuItem(
                  value: StatisticsInventorySort.longestListed,
                  child: Text(l10n.statisticsSortLongestListed),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onFilter});

  final StatisticsInventoryFilter filter;
  final ValueChanged<StatisticsInventoryFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        _FilterChip(
          chipKey: const ValueKey<String>('statistics_filter_all'),
          label: l10n.statisticsFilterAll,
          selected: filter == StatisticsInventoryFilter.all,
          onTap: () => onFilter(StatisticsInventoryFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          chipKey: const ValueKey<String>('statistics_filter_active'),
          label: l10n.statisticsFilterActive,
          selected: filter == StatisticsInventoryFilter.active,
          onTap: () => onFilter(StatisticsInventoryFilter.active),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          chipKey: const ValueKey<String>('statistics_filter_sold'),
          label: l10n.statisticsFilterSold,
          selected: filter == StatisticsInventoryFilter.sold,
          onTap: () => onFilter(StatisticsInventoryFilter.sold),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          key: chipKey,
          color: selected
              ? AppTheme.editorialAccentColor(
                  scheme,
                ).withValues(alpha: isDark ? 0.22 : 0.12)
              : AppTheme.softCardSurface(scheme),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingsCard extends StatelessWidget {
  const _ListingsCard({
    super.key,
    required this.listings,
    required this.now,
    required this.idPrefix,
    this.engagementFor,
    this.demandFor,
  });

  final List<SellerListingPerformance> listings;
  final DateTime now;
  final String idPrefix;
  final SellerListingEngagement Function(String listingId)? engagementFor;
  final SellerListingDemand? Function(SellerListingPerformance listing)?
  demandFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < listings.length; i++) ...[
          if (i > 0) const SizedBox(height: StatisticsLayout.listingGap),
          StatisticsListingCard(
            child: StatisticsListingRow(
              key: ValueKey<String>('$idPrefix${listings[i].listingId}'),
              listing: listings[i],
              now: now,
              engagement: engagementFor?.call(listings[i].listingId),
              demand: demandFor?.call(listings[i]),
              onTap: () => context.push(
                AppRoutes.listingDetailsPath(listings[i].listingId),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
