import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';

class FuelPricesDisclaimerCallout extends StatelessWidget {
  const FuelPricesDisclaimerCallout({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      key: const ValueKey<String>('fuel_prices_disclaimer_callout'),
      decoration: AppTheme.filterAlertManagementSurface(
        scheme,
        borderRadius: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fuelPricesDisclaimerTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: isDark ? 0.96 : 1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.fuelPricesDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.86 : 0.92,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
