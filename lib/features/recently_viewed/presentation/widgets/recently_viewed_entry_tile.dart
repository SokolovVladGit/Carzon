import 'package:flutter/material.dart';

import '../../../listings/presentation/utils/listing_details_header_titles.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../../listings/presentation/widgets/listing_cover_image.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recently_viewed_entry.dart';

/// Compact read-only row for a stored recently viewed listing.
class RecentlyViewedEntryTile extends StatelessWidget {
  const RecentlyViewedEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final RecentlyViewedEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final title = _titleLine();
    final subtitle = _subtitleLine(l10n);

    return Material(
      color: light
          ? Colors.white.withValues(alpha: 0.86)
          : scheme.surfaceContainerHigh.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: light ? 0.42 : 0.30),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: light
                        ? Colors.white.withValues(alpha: 0.82)
                        : scheme.outline.withValues(alpha: 0.28),
                  ),
                ),
                child: SizedBox(
                  width: 72,
                  height: 54,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: ListingCoverImage(imageUrl: entry.coverImageUrl),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _titleLine() {
    final title = entry.title.trim();
    if (title.isNotEmpty) return title;
    final identity = listingDetailsVehicleIdentityLine(entry.make, entry.model);
    if (identity.isEmpty) return null;
    return identity;
  }

  String? _subtitleLine(AppLocalizations l10n) {
    final parts = <String>[
      formatListingPrice(entry.priceEur, entry.priceCurrency),
      if (entry.year > 0) '${entry.year}',
    ];
    final city = entry.city.trim();
    if (city.isNotEmpty) parts.add(city);
    final region = formatMarketRegion(l10n, entry.marketRegion).trim();
    if (region.isNotEmpty) parts.add(region);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}
