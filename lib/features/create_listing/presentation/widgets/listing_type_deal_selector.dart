import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import 'compose_choice_card.dart';

class ListingTypeDealSelector extends StatelessWidget {
  const ListingTypeDealSelector({
    super.key,
    required this.l10n,
    required this.theme,
    required this.value,
    required this.submitting,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ListingType value;
  final bool submitting;
  final ValueChanged<ListingType> onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = submitting;
    return LayoutBuilder(
      builder: (context, c) {
        final gap = 10.0;
        final maxW = c.maxWidth;
        final half = (maxW - gap) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: half,
                    child: ComposeChoiceCard(
                      label: l10n.formatTypeSale,
                      selected: value == ListingType.sale,
                      enabled: !disabled,
                      onTap: () => onChanged(ListingType.sale),
                      theme: theme,
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    width: half,
                    child: ComposeChoiceCard(
                      label: l10n.formatTypeExchange,
                      selected: value == ListingType.exchange,
                      enabled: !disabled,
                      onTap: () => onChanged(ListingType.exchange),
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
            ComposeChoiceCard(
              label: l10n.formatTypeBoth,
              selected: value == ListingType.both,
              enabled: !disabled,
              onTap: () => onChanged(ListingType.both),
              theme: theme,
              compact: true,
              labelTextAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
