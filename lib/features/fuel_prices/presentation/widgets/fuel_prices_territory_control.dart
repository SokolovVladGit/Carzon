import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../listings/presentation/widgets/filters/listings_filter_segmented_control.dart';
import '../cubit/fuel_prices_cubit.dart';

class FuelPricesTerritoryControl extends StatelessWidget {
  const FuelPricesTerritoryControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final FuelPricesTerritory selected;
  final ValueChanged<FuelPricesTerritory> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListingsFilterSegmentedControl<FuelPricesTerritory>(
      variant: ListingsFilterSegmentedControlVariant.region,
      value: selected,
      onChanged: onChanged,
      entries: [
        ListingsFilterSegmentEntry(
          value: FuelPricesTerritory.moldova,
          label: Text(l10n.fuelPricesTerritoryMoldova),
          icon: Icons.flag_outlined,
        ),
        ListingsFilterSegmentEntry(
          value: FuelPricesTerritory.pmr,
          label: Text(l10n.fuelPricesTerritoryPmr),
          icon: Icons.map_outlined,
        ),
      ],
    );
  }
}
