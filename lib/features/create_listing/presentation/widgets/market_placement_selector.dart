import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import 'create_listing_segmented_control.dart';

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
    return CreateListingSegmentedControl<MarketRegion>(
      value: value,
      enabled: !submitting,
      onChanged: onChanged,
      options: [
        CreateListingSegmentOption(
          key: const ValueKey('market_region_transnistria'),
          value: MarketRegion.transnistria,
          label: l10n.regionTransnistria,
        ),
        CreateListingSegmentOption(
          key: const ValueKey('market_region_moldova'),
          value: MarketRegion.moldova,
          label: l10n.regionMoldova,
        ),
      ],
    );
  }
}
