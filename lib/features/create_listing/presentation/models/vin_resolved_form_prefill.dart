import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/vehicle_resolve_result.dart';

/// Persistable optional specs from a confirmed VIN suggestion.
/// Display mapping lives in [vin_resolve_display.dart] and is not used here.
class VinResolvedFormPrefill {
  const VinResolvedFormPrefill({
    this.bodyType,
    this.fuelType,
    this.transmissionType,
    this.drivetrain,
    this.engineDisplacementLiters,
    this.engineCylinders,
    this.doors,
    this.seats,
  });

  final ListingBodyType? bodyType;
  final ListingFuelType? fuelType;
  final ListingTransmissionType? transmissionType;
  final ListingDrivetrain? drivetrain;
  final double? engineDisplacementLiters;
  final int? engineCylinders;
  final int? doors;
  final int? seats;

  bool get isEmpty =>
      bodyType == null &&
      fuelType == null &&
      transmissionType == null &&
      drivetrain == null &&
      engineDisplacementLiters == null &&
      engineCylinders == null &&
      doors == null &&
      seats == null;
}

VinResolvedFormPrefill vinResolvedFormPrefill(
  VehicleResolveSuggestion vehicle, {
  List<String> warnings = const [],
}) {
  if (warnings.contains('nhtsa_catalog_decode_caution')) {
    return const VinResolvedFormPrefill();
  }
  return VinResolvedFormPrefill(
    bodyType: vinResolvedBodyType(vehicle.bodyType),
    fuelType: vinResolvedFuelType(
      vehicle.fuelType,
      secondary: vehicle.fuelTypeSecondary,
      electrification: vehicle.electrificationLevel,
    ),
    transmissionType: vinResolvedTransmissionType(vehicle.transmission),
    drivetrain: vinResolvedDrivetrain(vehicle.driveType),
    engineDisplacementLiters: vinResolvedDisplacementLiters(
      vehicle.displacement,
    ),
    engineCylinders: vinResolvedCount(vehicle.cylinders, max: 16),
    doors: vinResolvedCount(vehicle.doors, max: 6),
    seats: vinResolvedCount(vehicle.seats, max: 15),
  );
}

/// Exact NHTSA `BodyClass` strings only. No substring matching.
ListingBodyType? vinResolvedBodyType(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  return switch (hay) {
    'sedan' || 'saloon' || 'sedan/saloon' => ListingBodyType.sedan,
    'hatchback' || 'hatchback/liftback/notchback' => ListingBodyType.hatchback,
    'wagon' => ListingBodyType.wagon,
    'suv' ||
    'sport utility vehicle' ||
    'sport utility vehicle (suv)/multi-purpose vehicle (mpv)' =>
      ListingBodyType.suv,
    'coupe' => ListingBodyType.coupe,
    'convertible' ||
    'cabriolet' ||
    'convertible/cabriolet' => ListingBodyType.convertible,
    'minivan' => ListingBodyType.minivan,
    'pickup' || 'pick-up' || 'pick up' => ListingBodyType.pickup,
    'van' || 'cargo van' => ListingBodyType.van,
    _ => null,
  };
}

/// Deterministic fuel from primary, secondary, and electrification.
///
/// A non-empty value that is not in the explicit tables is unknown.
/// Disagreeing fuels stay null. Electrification never invents a hybrid
/// from a model name.
ListingFuelType? vinResolvedFuelType(
  String? primary, {
  String? secondary,
  String? electrification,
}) {
  final primaryCategory = _explicitFuel(primary);
  final secondaryCategory = _explicitFuel(secondary);
  final electrified = _explicitElectrification(electrification);
  if (_presentUnmapped(primary, primaryCategory)) return null;
  if (_presentUnmapped(secondary, secondaryCategory)) return null;
  if (_presentUnmapped(electrification, electrified)) return null;
  if (primaryCategory != null &&
      secondaryCategory != null &&
      primaryCategory != secondaryCategory) {
    return null;
  }
  final base = primaryCategory ?? secondaryCategory;
  if (electrified == null) return base;
  if (!_electrificationCompatible(electrified, base)) return null;
  return electrified;
}

int? vinResolvedCount(String? raw, {required int max}) {
  final hay = raw?.trim();
  if (hay == null || hay.isEmpty || !RegExp(r'^\d+$').hasMatch(hay)) {
    return null;
  }
  final n = int.tryParse(hay);
  if (n == null || n < 1 || n > max) return null;
  return n;
}

ListingFuelType? _explicitFuel(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  return switch (hay) {
    'gasoline' || 'petrol' => ListingFuelType.petrol,
    'diesel' => ListingFuelType.diesel,
    'electric' || 'battery electric' || 'bev' => ListingFuelType.electric,
    'lpg' || 'liquefied petroleum gas (propane or lpg)' => ListingFuelType.lpg,
    'cng' || 'compressed natural gas (cng)' => ListingFuelType.cng,
    _ => null,
  };
}

ListingFuelType? _explicitElectrification(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  return switch (hay) {
    'bev (battery electric vehicle)' => ListingFuelType.electric,
    'hev (hybrid electric vehicle) - level unknown' ||
    'strong hev (hybrid electric vehicle)' ||
    'mild hev (hybrid electric vehicle)' => ListingFuelType.hybrid,
    'phev (plug-in hybrid electric vehicle)' => ListingFuelType.plugInHybrid,
    _ => null,
  };
}

bool _presentUnmapped(String? raw, ListingFuelType? mapped) {
  final hay = _norm(raw);
  return hay != null && mapped == null;
}

bool _electrificationCompatible(ListingFuelType electrified, ListingFuelType? base) {
  if (base == null) return true;
  return switch (electrified) {
    ListingFuelType.plugInHybrid =>
      base == ListingFuelType.petrol ||
          base == ListingFuelType.diesel ||
          base == ListingFuelType.electric ||
          base == ListingFuelType.plugInHybrid,
    ListingFuelType.hybrid =>
      base == ListingFuelType.petrol ||
          base == ListingFuelType.diesel ||
          base == ListingFuelType.hybrid,
    ListingFuelType.electric =>
      base == ListingFuelType.electric,
    _ => false,
  };
}

ListingTransmissionType? vinResolvedTransmissionType(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  if (hay.contains('automated manual') ||
      hay.contains('semi-automatic') ||
      hay.contains('dual clutch') ||
      hay.contains('dct') ||
      hay.contains('robotic')) {
    return null;
  }
  final automatic = hay.contains('automatic');
  final manual = RegExp(r'\bmanual\b').hasMatch(hay);
  final cvt =
      hay == 'cvt' || hay.startsWith('cvt ') || hay == 'continuously variable';
  if (automatic && manual) return null;
  if (cvt && !automatic && !manual) return ListingTransmissionType.cvt;
  if (automatic) return ListingTransmissionType.automatic;
  if (manual) return ListingTransmissionType.manual;
  return null;
}

ListingDrivetrain? vinResolvedDrivetrain(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  if (hay.contains('4x2') || hay.contains('4×2') || hay == '2wd') return null;
  final awd =
      hay.contains('awd') ||
      hay.contains('all-wheel') ||
      hay.contains('all wheel');
  final four =
      hay.contains('4wd') ||
      hay.contains('4x4') ||
      hay.contains('4×4') ||
      hay.contains('4-wheel') ||
      hay.contains('four-wheel') ||
      hay.contains('four wheel');
  final fwd =
      hay.contains('fwd') ||
      hay.contains('front-wheel') ||
      hay.contains('front wheel');
  final rwd =
      hay.contains('rwd') ||
      hay.contains('rear-wheel') ||
      hay.contains('rear wheel');
  final hits = [awd, four, fwd, rwd].where((hit) => hit).length;
  if (hits != 1) return null;
  if (awd) return ListingDrivetrain.awd;
  if (four) return ListingDrivetrain.fourWheel;
  if (fwd) return ListingDrivetrain.fwd;
  return ListingDrivetrain.rwd;
}

double? vinResolvedDisplacementLiters(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(hay);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (value == null || !value.isFinite || value <= 0 || value > 30) {
    return null;
  }
  return (value * 1000).round() / 1000;
}

String formatVinDisplacementField(double liters) {
  return liters.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}

String? _norm(String? raw) {
  if (raw == null) return null;
  final t = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return t.isEmpty ? null : t;
}
