import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';

/// Premium editorial safety note placed below the price board.
class FuelPricesDisclaimerCallout extends StatelessWidget {
  const FuelPricesDisclaimerCallout({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTheme.editorialAccentColor(scheme);

    return Column(
      key: const ValueKey<String>('fuel_prices_disclaimer_callout'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 0.5,
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.14 : 0.2),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.5 : 0.44),
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: const SizedBox(width: 3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fuelPricesDisclaimerTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.04,
                        height: 1.25,
                        color: scheme.onSurface.withValues(
                          alpha: isDark ? 0.88 : 0.86,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.fuelPricesDisclaimer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.48,
                        color: scheme.onSurfaceVariant.withValues(
                          alpha: isDark ? 0.74 : 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
