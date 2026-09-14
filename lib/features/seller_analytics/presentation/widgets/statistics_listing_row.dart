import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
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
    final meta = <String>[
      l10n.statisticsListingViews(listing.periodViews),
      l10n.statisticsListingFavorites(listing.currentFavorites),
      l10n.statisticsListingInquiries(listing.periodInquiries),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.displayTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatStatus(l10n, listing.status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                meta.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (engagement != null) ...[
                const SizedBox(height: 4),
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
                    height: 1.35,
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
                    height: 1.35,
                  ),
                ),
              ],
              if (age != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.statisticsListedForDays(age),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.86),
                  ),
                ),
              ] else if (soldDays != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.statisticsSoldAfterDays(soldDays),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.86),
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
