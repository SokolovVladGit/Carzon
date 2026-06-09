import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../utils/vin_manual_source_cards.dart';
import 'buyer_vin_report_collapsible_section.dart';
import 'buyer_vin_report_sheet_ui.dart';

/// Informational manual/external source cards (collapsed by default).
class BuyerVinManualSourceCardsSection extends StatelessWidget {
  const BuyerVinManualSourceCardsSection({
    super.key,
    required this.l10n,
    required this.theme,
    this.collapsedByDefault = true,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final bool collapsedByDefault;

  @override
  Widget build(BuildContext context) {
    final cards = buildBuyerVinManualSourceCards(l10n);
    if (cards.isEmpty) return const SizedBox.shrink();

    return BuyerVinReportCollapsibleSection(
      theme: theme,
      sectionKey: 'buyer_vin_report_manual_sources',
      title: l10n.listingBuyerVinReportManualSourcesSectionTitle,
      initiallyExpanded: !collapsedByDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.listingBuyerVinReportManualSourcesIntro,
            style: buyerVinReportMicrocopyStyle(theme),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ManualSourceCardTile(theme: theme, card: cards[i]),
          ],
        ],
      ),
    );
  }
}

class _ManualSourceCardTile extends StatelessWidget {
  const _ManualSourceCardTile({required this.theme, required this.card});

  final ThemeData theme;
  final VinManualSourceCardDefinition card;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      key: ValueKey('buyer_vin_manual_card_${card.sourceId}'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.45)
            : scheme.surface.withValues(alpha: 0.85),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.26 : 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              card.title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.body,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.42,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.86 : 0.95,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
