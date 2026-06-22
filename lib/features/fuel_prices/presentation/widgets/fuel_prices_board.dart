import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/fuel_price_snapshot.dart';
import '../utils/fuel_price_formatters.dart';

class FuelPricesBoard extends StatelessWidget {
  const FuelPricesBoard({
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
    final unitLabel = fuelPriceUnitLabel(l10n, snapshot.currency);

    return DecoratedBox(
      decoration: AppTheme.filterAlertManagementSurface(
        scheme,
        borderRadius: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              fuelPriceScopeNote(l10n, snapshot.territory),
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.86 : 0.92,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < snapshot.items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 20,
                  thickness: 0.5,
                  color: scheme.outlineVariant.withValues(
                    alpha: isDark ? 0.16 : 0.22,
                  ),
                ),
              _FuelPriceBoardRow(
                label: fuelPriceFuelLabel(l10n, snapshot.items[i].fuelCode),
                price: snapshot.items[i].price,
                unitLabel: unitLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FuelPriceBoardRow extends StatelessWidget {
  const _FuelPriceBoardRow({
    required this.label,
    required this.price,
    required this.unitLabel,
  });

  final String label;
  final double price;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final amount = formatFuelPriceAmount(price);
    final parts = amount.split('.');
    final whole = parts.first;
    final fraction = parts.length > 1 ? parts.last : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.15,
              color: scheme.onSurface.withValues(alpha: isDark ? 0.96 : 1),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              whole,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1,
                color: AppTheme.editorialAccentColor(scheme),
              ),
            ),
            if (fraction != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '.$fraction',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1,
                    color: AppTheme.editorialAccentColor(scheme),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                unitLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant.withValues(
                    alpha: isDark ? 0.82 : 0.88,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
