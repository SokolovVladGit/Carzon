import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../utils/buyer_vin_report_limitation_labels.dart';
import 'buyer_vin_report_sheet_ui.dart';

/// Human-readable limitations for buyer VIN report (no raw worker codes).
class BuyerVinReportLimitationSection extends StatelessWidget {
  const BuyerVinReportLimitationSection({
    super.key,
    required this.l10n,
    required this.theme,
    required this.limitationCodes,
    this.wrapInCard = true,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final List<String> limitationCodes;
  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    final bullets = localizedBuyerVinReportLimitationBullets(
      l10n,
      limitationCodes,
    );
    if (bullets.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listingBuyerVinReportNotVerifiedSectionTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            color: isDark ? scheme.onSurface.withValues(alpha: 0.96) : null,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < bullets.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < bullets.length - 1 ? 8 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullets[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.48,
                      color: scheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (!wrapInCard) return body;

    return DecoratedBox(
      key: const ValueKey('buyer_vin_report_limitations_card'),
      decoration: buyerVinReportSectionDecoration(
        scheme,
        BuyerVinReportSectionTone.limitations,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: body,
      ),
    );
  }
}
