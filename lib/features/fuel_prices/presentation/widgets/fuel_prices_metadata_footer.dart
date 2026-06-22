import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../domain/entities/fuel_price_snapshot.dart';
import '../utils/fuel_price_formatters.dart';

class FuelPricesMetadataFooter extends StatelessWidget {
  const FuelPricesMetadataFooter({
    super.key,
    required this.snapshot,
  });

  final FuelPriceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dateLabel = fuelPriceDateLabel(
      l10n: l10n,
      effectiveDate: snapshot.effectiveDate,
      fetchedAt: snapshot.fetchedAt,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot.sourceLabel.isNotEmpty)
          Text(
            l10n.fuelPricesSourceLabel(snapshot.sourceLabel),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(
                alpha: isDark ? 0.86 : 0.92,
              ),
            ),
          ),
        if (dateLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(
                alpha: isDark ? 0.86 : 0.92,
              ),
            ),
          ),
        ],
        if (snapshot.isStale) ...[
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer.withValues(alpha: isDark ? 0.28 : 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                l10n.fuelPricesStaleNotice,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onTertiaryContainer,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
