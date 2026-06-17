import 'package:flutter/material.dart';

import '../listing_vehicle_spec_pickers.dart';

/// Label + premium tappable row for vehicle spec filters (body / fuel / transmission).
///
/// Reuses [ListingVehicleSpecPickerRow] chrome from create/edit listing flows.
class ListingsFilterVehicleSpecSelectorField extends StatelessWidget {
  const ListingsFilterVehicleSpecSelectorField({
    super.key,
    required this.label,
    required this.valueText,
    required this.onTap,
    this.fieldKey,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ListingVehicleSpecPickerRow(
          fieldKey: fieldKey,
          valueText: valueText,
          enabled: true,
          onTap: onTap,
        ),
      ],
    );
  }
}
