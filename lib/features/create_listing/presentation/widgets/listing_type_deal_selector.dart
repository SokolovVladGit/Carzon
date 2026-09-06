import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import 'create_listing_segmented_control.dart';

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
    return CreateListingSegmentedControl<ListingType>(
      value: value,
      enabled: !submitting,
      onChanged: onChanged,
      options: [
        CreateListingSegmentOption(
          value: ListingType.sale,
          label: l10n.formatTypeSale,
        ),
        CreateListingSegmentOption(
          value: ListingType.exchange,
          label: l10n.formatTypeExchange,
        ),
        CreateListingSegmentOption(
          value: ListingType.both,
          label: l10n.formatTypeBoth,
        ),
      ],
    );
  }
}
