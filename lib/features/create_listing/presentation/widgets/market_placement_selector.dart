import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import 'compose_choice_card.dart';

class MarketPlacementSelector extends StatelessWidget {
  const MarketPlacementSelector({
    super.key,
    required this.l10n,
    required this.theme,
    required this.value,
    required this.submitting,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final MarketRegion value;
  final bool submitting;
  final ValueChanged<MarketRegion> onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = submitting;
    return LayoutBuilder(
      builder: (context, c) {
        final gap = 10.0;
        final half = (c.maxWidth - gap) / 2;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: half,
                child: ComposeChoiceCard(
                  label: l10n.regionTransnistria,
                  selected: value == MarketRegion.transnistria,
                  enabled: !disabled,
                  onTap: () => onChanged(MarketRegion.transnistria),
                  theme: theme,
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: half,
                child: ComposeChoiceCard(
                  label: l10n.regionMoldova,
                  selected: value == MarketRegion.moldova,
                  enabled: !disabled,
                  onTap: () => onChanged(MarketRegion.moldova),
                  theme: theme,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
