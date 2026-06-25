import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';

/// Compact editorial intro above the territory board module.
class FuelPricesIntroHeader extends StatelessWidget {
  const FuelPricesIntroHeader({super.key});

  static const Key eyebrowKey = ValueKey<String>('fuel_prices_intro_eyebrow');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTheme.editorialAccentColor(scheme);

    return Column(
      key: const ValueKey<String>('fuel_prices_intro_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key: eyebrowKey,
          l10n.fuelPricesIntroEyebrow.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            height: 1.2,
            color: accent.withValues(alpha: isDark ? 0.78 : 0.74),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.fuelPricesIntroLine,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            height: 1.4,
            color: scheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.84 : 0.88,
            ),
          ),
        ),
      ],
    );
  }
}
