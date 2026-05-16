import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../utils/buyer_vin_report_limitation_labels.dart';

/// Human-readable limitations for buyer VIN report (no raw worker codes).
class BuyerVinReportLimitationSection extends StatelessWidget {
  const BuyerVinReportLimitationSection({
    super.key,
    required this.l10n,
    required this.theme,
    required this.limitationCodes,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final List<String> limitationCodes;

  @override
  Widget build(BuildContext context) {
    final bullets = localizedBuyerVinReportLimitationBullets(l10n, limitationCodes);
    if (bullets.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listingBuyerVinReportNotVerifiedSectionTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final line in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
