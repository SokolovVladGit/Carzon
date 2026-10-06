import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../domain/entities/vehicle_resolve_result.dart';
import 'vin_resolved_form_prefill.dart';

/// Display-only VIN result lines. Does not mutate listing form fields.
class VinResolveDisplaySpec {
  const VinResolveDisplaySpec({
    this.fuel,
    this.transmission,
    this.drivetrain,
    this.displacement,
    this.body,
    this.caution,
  });

  final String? fuel;
  final String? transmission;
  final String? drivetrain;
  final String? displacement;
  final String? body;
  final String? caution;

  String get line1 => joinVinSpecParts([fuel, transmission]);
  String get line2 => joinVinSpecParts([drivetrain, displacement]);

  bool get hasTechnicalLines =>
      line1.isNotEmpty || line2.isNotEmpty || (body?.isNotEmpty ?? false);
}

VinResolveDisplaySpec vinResolveDisplaySpec({
  required VehicleResolveSuggestion vehicle,
  required List<String> warnings,
  required AppLocalizations l10n,
}) {
  final cautioned = warnings.contains('nhtsa_catalog_decode_caution');
  final fuel = cautioned
      ? null
      : vinResolvedFuelType(
          vehicle.fuelType,
          secondary: vehicle.fuelTypeSecondary,
          electrification: vehicle.electrificationLevel,
        );
  final transmission = cautioned
      ? null
      : vinResolvedTransmissionType(vehicle.transmission);
  final drivetrain = cautioned
      ? null
      : vinResolvedDrivetrain(vehicle.driveType);
  final liters = cautioned
      ? null
      : vinResolvedDisplacementLiters(vehicle.displacement);
  final body = cautioned ? null : vinResolvedBodyType(vehicle.bodyType);
  return VinResolveDisplaySpec(
    fuel: fuel == null ? null : formatListingFuelType(l10n, fuel),
    transmission: transmission == null
        ? null
        : formatListingTransmissionType(l10n, transmission),
    drivetrain: drivetrain == null
        ? null
        : formatListingDrivetrain(l10n, drivetrain),
    displacement: liters == null
        ? null
        : formatEngineDisplacementForDisplay(l10n, liters),
    body: body == null ? null : formatListingBodyType(l10n, body),
    caution: warnings.isEmpty ? null : l10n.createListingVinSpecCaution,
  );
}

@visibleForTesting
String joinVinSpecParts(Iterable<String?> parts) {
  return parts
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(' · ');
}
