import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../domain/entities/vehicle_resolve_result.dart';

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
  return VinResolveDisplaySpec(
    fuel: _fuelLabel(vehicle.fuelType, l10n),
    transmission: _transmissionLabel(vehicle.transmission, l10n),
    drivetrain: _drivetrainLabel(vehicle.driveType, l10n),
    displacement: _displacementLabel(vehicle.displacement, l10n),
    body: _bodyLabel(vehicle.bodyType, l10n),
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

String? _fuelLabel(String? raw, AppLocalizations l10n) {
  final hay = _norm(raw);
  if (hay == null) return null;
  if (_isAmbiguousFuel(hay)) return null;
  if (hay == 'gasoline' || hay == 'petrol') {
    return formatListingFuelType(l10n, ListingFuelType.petrol);
  }
  if (hay == 'diesel') {
    return formatListingFuelType(l10n, ListingFuelType.diesel);
  }
  if (hay == 'electric' || hay == 'battery electric' || hay == 'bev') {
    return formatListingFuelType(l10n, ListingFuelType.electric);
  }
  return null;
}

String? _transmissionLabel(String? raw, AppLocalizations l10n) {
  final hay = _norm(raw);
  if (hay == null) return null;
  final automatic = hay.contains('automatic');
  final manual = RegExp(r'\bmanual\b').hasMatch(hay);
  final cvt = hay.contains('cvt') || hay.contains('continuously variable');
  if (automatic && manual) return null;
  if (hay.contains('automated manual') || hay.contains('semi-automatic')) {
    return null;
  }
  if (cvt && !automatic && !manual) {
    return formatListingTransmissionType(l10n, ListingTransmissionType.cvt);
  }
  if (automatic) {
    return formatListingTransmissionType(
      l10n,
      ListingTransmissionType.automatic,
    );
  }
  if (manual) {
    return formatListingTransmissionType(l10n, ListingTransmissionType.manual);
  }
  return null;
}

String? _drivetrainLabel(String? raw, AppLocalizations l10n) {
  final hay = _norm(raw);
  if (hay == null) return null;
  if (hay.contains('4x2') || hay.contains('4×2')) return null;
  final awd = hay.contains('awd') || hay.contains('all-wheel') ||
      hay.contains('all wheel');
  final four = hay.contains('4wd') ||
      hay.contains('4x4') ||
      hay.contains('4×4') ||
      hay.contains('4-wheel') ||
      hay.contains('four-wheel') ||
      hay.contains('four wheel');
  final fwd = hay.contains('fwd') ||
      hay.contains('front-wheel') ||
      hay.contains('front wheel');
  final rwd = hay.contains('rwd') ||
      hay.contains('rear-wheel') ||
      hay.contains('rear wheel');
  final hits = [awd, four, fwd, rwd].where((hit) => hit).length;
  if (hits != 1) return null;
  if (awd) return formatListingDrivetrain(l10n, ListingDrivetrain.awd);
  if (four) return formatListingDrivetrain(l10n, ListingDrivetrain.fourWheel);
  if (fwd) return formatListingDrivetrain(l10n, ListingDrivetrain.fwd);
  return formatListingDrivetrain(l10n, ListingDrivetrain.rwd);
}

String? _displacementLabel(String? raw, AppLocalizations l10n) {
  final hay = _norm(raw);
  if (hay == null) return null;
  final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(hay);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (value == null || !value.isFinite || value <= 0 || value >= 80) {
    return null;
  }
  return formatEngineDisplacementForDisplay(l10n, value);
}

String? _bodyLabel(String? raw, AppLocalizations l10n) {
  final hay = _norm(raw);
  if (hay == null) return null;
  ListingBodyType? type;
  if (hay.contains('pickup') || hay.contains('pick-up') || hay.contains('pick up')) {
    type = ListingBodyType.pickup;
  } else if (hay.contains('sedan') || hay.contains('saloon')) {
    type = ListingBodyType.sedan;
  } else if (hay.contains('hatch')) {
    type = ListingBodyType.hatchback;
  } else if (hay.contains('wagon') || hay.contains('estate')) {
    type = ListingBodyType.wagon;
  } else if (hay.contains('convertible') ||
      hay.contains('cabriolet') ||
      hay.contains('cabrio')) {
    type = ListingBodyType.convertible;
  } else if (hay.contains('coupe') || hay.contains('coupé')) {
    type = ListingBodyType.coupe;
  } else if (hay.contains('minivan')) {
    type = ListingBodyType.minivan;
  } else if (hay.contains('sport utility') || hay.contains('suv')) {
    type = ListingBodyType.suv;
  } else if (hay == 'van' || hay.startsWith('van ') || hay.contains('cargo van')) {
    type = ListingBodyType.van;
  }
  if (type == null) return null;
  return formatListingBodyType(l10n, type);
}

bool _isAmbiguousFuel(String hay) {
  return hay.contains('hybrid') ||
      hay.contains('flex') ||
      hay.contains('e85') ||
      hay.contains('ethanol') ||
      hay.contains('plug') ||
      hay.contains('lpg') ||
      hay.contains('cng') ||
      hay.contains('bifuel') ||
      hay.contains('/');
}

String? _norm(String? raw) {
  if (raw == null) return null;
  final t = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return t.isEmpty ? null : t;
}
