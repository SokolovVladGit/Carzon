import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/seller_inventory_demand.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_performance.dart';
import '../bloc/seller_analytics_state.dart';

class StatisticsDemandCard extends StatelessWidget {
  const StatisticsDemandCard({
    super.key,
    required this.status,
    required this.demand,
    this.onRetry,
  });

  static const Key rootKey = ValueKey<String>('statistics_buyer_demand');
  static const Key valueKey = ValueKey<String>('statistics_demand_value');
  static const Key retryKey = ValueKey<String>('statistics_demand_retry');

  final SellerDemandLoadStatus status;
  final SellerInventoryDemand? demand;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _DemandSectionCard(
      cardKey: rootKey,
      title: l10n.statisticsDemandTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsDemandExplanation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          switch (status) {
            SellerDemandLoadStatus.loading => const _DemandLoading(),
            SellerDemandLoadStatus.unavailable => _DemandUnavailable(
              onRetry: onRetry,
            ),
            SellerDemandLoadStatus.loaded when demand != null => _DemandBody(
              demand: demand!,
            ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class StatisticsTopDemandCard extends StatelessWidget {
  const StatisticsTopDemandCard({
    super.key,
    required this.listings,
    required this.demands,
    required this.onTapListing,
  });

  static const Key rootKey = ValueKey<String>('statistics_top_demand');

  final List<SellerListingPerformance> listings;
  final Map<String, SellerListingDemand> demands;
  final ValueChanged<String> onTapListing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _DemandSectionCard(
      cardKey: rootKey,
      title: l10n.statisticsDemandTop,
      child: Column(
        children: [
          for (var i = 0; i < listings.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _TopDemandRow(
              listing: listings[i],
              count: demands[listings[i].listingId]!.matchingUsers!,
              onTap: () => onTapListing(listings[i].listingId),
            ),
          ],
        ],
      ),
    );
  }
}

class _DemandBody extends StatelessWidget {
  const _DemandBody({required this.demand});

  final SellerInventoryDemand demand;

  @override
  Widget build(BuildContext context) {
    if (demand.isPrivacySuppressed) {
      return const _SuppressedDemand();
    }
    if (demand.isZero) {
      return const _ZeroDemand();
    }
    if (demand.isVisibleCount) {
      return _VisibleDemand(count: demand.matchingUsers!);
    }
    return const SizedBox.shrink();
  }
}

class _VisibleDemand extends StatelessWidget {
  const _VisibleDemand({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Semantics(
      label: '${l10n.statisticsDemandMatchingUsers}: $count',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            key: StatisticsDemandCard.valueKey,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statisticsDemandMatchingUsers,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeroDemand extends StatelessWidget {
  const _ZeroDemand();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Semantics(
      label: '0. ${l10n.statisticsDemandZeroBody}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0',
            key: StatisticsDemandCard.valueKey,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statisticsDemandMatchingUsers,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.statisticsDemandZeroBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuppressedDemand extends StatelessWidget {
  const _SuppressedDemand();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Semantics(
      label:
          '${l10n.statisticsDemandInsufficient}. ${l10n.statisticsDemandPrivacyBody}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsDemandInsufficient,
            key: StatisticsDemandCard.valueKey,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.statisticsDemandPrivacyBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandLoading extends StatelessWidget {
  const _DemandLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.statisticsDemandLoading,
      child: const SizedBox(
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _DemandUnavailable extends StatelessWidget {
  const _DemandUnavailable({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statisticsDemandUnavailable,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          TextButton(
            key: StatisticsDemandCard.retryKey,
            onPressed: onRetry,
            child: Text(l10n.commonRetry),
          ),
        ],
      ],
    );
  }
}

class _TopDemandRow extends StatelessWidget {
  const _TopDemandRow({
    required this.listing,
    required this.count,
    required this.onTap,
  });

  final SellerListingPerformance listing;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  listing.displayTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.statisticsListingDemandVisible(count),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemandSectionCard extends StatelessWidget {
  const _DemandSectionCard({
    required this.cardKey,
    required this.title,
    required this.child,
  });

  final Key cardKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: cardKey,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.08,
                  ),
                ),
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String listingDemandLabel(AppLocalizations l10n, SellerListingDemand demand) {
  if (demand.isPrivacySuppressed) {
    return l10n.statisticsListingDemandSuppressed;
  }
  if (demand.isZero) {
    return l10n.statisticsListingDemandZero;
  }
  if (demand.isVisibleCount) {
    return l10n.statisticsListingDemandVisible(demand.matchingUsers!);
  }
  return '';
}
