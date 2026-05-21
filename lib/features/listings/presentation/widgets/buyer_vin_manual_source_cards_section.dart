import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../utils/vin_manual_source_cards.dart';

/// Informational manual/external source cards (Phase C; no live data).
class BuyerVinManualSourceCardsSection extends StatelessWidget {
  const BuyerVinManualSourceCardsSection({
    super.key,
    required this.l10n,
    required this.theme,
  });

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final cards = buildBuyerVinManualSourceCards(l10n);
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listingBuyerVinReportManualSourcesSectionTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.listingBuyerVinReportManualSourcesIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ManualSourceCardTile(theme: theme, card: cards[i]),
        ],
      ],
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
    return DecoratedBox(
      key: ValueKey('buyer_vin_manual_card_${card.sourceId}'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              card.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: _ManualSourceStatusChip(theme: theme, label: card.statusLabel),
            ),
            const SizedBox(height: 8),
            Text(
              card.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.limitationLine,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualSourceStatusChip extends StatelessWidget {
  const _ManualSourceStatusChip({required this.theme, required this.label});

  final ThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
