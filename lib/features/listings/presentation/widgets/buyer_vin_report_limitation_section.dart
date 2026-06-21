import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../utils/buyer_vin_report_limitation_labels.dart';
import 'buyer_vin_report_collapsible_section.dart';

/// Compact buyer-facing limitations (collapsed by default).
class BuyerVinReportLimitationSection extends StatelessWidget {
  const BuyerVinReportLimitationSection({
    super.key,
    required this.l10n,
    required this.theme,
    required this.limitationCodes,
    this.wrapInCard = true,
    this.collapsedByDefault = true,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final List<String> limitationCodes;

  /// When false, only the bullet list is returned (no collapsible shell).
  final bool wrapInCard;

  /// Secondary section starts collapsed to keep decoded data primary.
  final bool collapsedByDefault;

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
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bullets.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < bullets.length - 1 ? 6 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullets[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: theme.brightness == Brightness.dark
                            ? 0.88
                            : 0.95,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (!wrapInCard) return body;

    return BuyerVinReportCollapsibleSection(
      theme: theme,
      sectionKey: 'buyer_vin_report_limitations_card',
      title: l10n.listingBuyerVinReportNotVerifiedSectionTitle,
      initiallyExpanded: !collapsedByDefault,
      child: body,
    );
  }
}
