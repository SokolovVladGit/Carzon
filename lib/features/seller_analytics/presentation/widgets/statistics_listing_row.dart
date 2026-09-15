import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_engagement.dart';
import '../../domain/entities/seller_listing_performance.dart';
import 'statistics_demand_cards.dart';

class StatisticsListingRow extends StatelessWidget {
  const StatisticsListingRow({
    super.key,
    required this.listing,
    required this.now,
    required this.onTap,
    this.engagement,
    this.demand,
  });

  final SellerListingPerformance listing;
  final DateTime now;
  final VoidCallback onTap;
  final SellerListingEngagement? engagement;
  final SellerListingDemand? demand;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final age = listing.activeListingAgeDays(now);
    final soldDays = listing.soldDurationDays();
    final metricSemantics = [
      l10n.statisticsListingViews(listing.periodViews),
      l10n.statisticsListingFavorites(listing.currentFavorites),
      l10n.statisticsListingInquiries(listing.periodInquiries),
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(status: listing.status),
                ],
              ),
              const SizedBox(height: 7),
              Semantics(
                label: metricSemantics,
                child: Row(
                  children: [
                    _IconStat(
                      icon: CarzonIcons.eye,
                      value: '${listing.periodViews}',
                    ),
                    const SizedBox(width: 16),
                    _IconStat(
                      icon: CarzonIcons.heartOutline,
                      value: '${listing.currentFavorites}',
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        '${l10n.statisticsMetricInquiries} ${listing.periodInquiries}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (engagement != null) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    l10n.statisticsListingImpressions(
                      engagement!.periodImpressions,
                    ),
                    l10n.statisticsListingContactActions(
                      engagement!.periodContactActions,
                    ),
                    l10n.statisticsListingShares(engagement!.periodShares),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.86),
                    height: 1.3,
                  ),
                ),
              ],
              if (demand != null) ...[
                const SizedBox(height: 4),
                Text(
                  listingDemandLabel(l10n, demand!),
                  key: ValueKey<String>(
                    'statistics_listing_demand_${listing.listingId}',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.86),
                    height: 1.3,
                  ),
                ),
              ],
              if (age != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.statisticsListedForDays(age),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.78),
                  ),
                ),
              ] else if (soldDays != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.statisticsSoldAfterDays(soldDays),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isActive = status == ListingStatus.active;
    final fill = isActive
        ? AppTheme.editorialAccentColor(scheme).withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.05,
          )
        : scheme.surfaceContainerHighest.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.32 : 0.38,
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          formatStatus(l10n, status),
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
