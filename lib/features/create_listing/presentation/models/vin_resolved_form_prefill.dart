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
  });

  final ListingBodyType? bodyType;
  final ListingFuelType? fuelType;
  final ListingTransmissionType? transmissionType;
  final ListingDrivetrain? drivetrain;
  final double? engineDisplacementLiters;

  bool get isEmpty =>
      bodyType == null &&
      fuelType == null &&
      transmissionType == null &&
      drivetrain == null &&
      engineDisplacementLiters == null;
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
    fuelType: vinResolvedFuelType(vehicle.fuelType),
    transmissionType: vinResolvedTransmissionType(vehicle.transmission),
    drivetrain: vinResolvedDrivetrain(vehicle.driveType),
    engineDisplacementLiters: vinResolvedDisplacementLiters(
      vehicle.displacement,
    ),
  );
}

ListingBodyType? vinResolvedBodyType(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  return switch (hay) {
    'pickup' || 'pick-up' || 'pick up' => ListingBodyType.pickup,
    'sedan' || 'saloon' || 'sedan/saloon' => ListingBodyType.sedan,
    'suv' || 'sport utility vehicle' => ListingBodyType.suv,
    _ =>
      hay.startsWith('sport utility vehicle (suv)')
          ? ListingBodyType.suv
          : null,
  };
}

ListingFuelType? vinResolvedFuelType(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  if (_isAmbiguousFuel(hay)) return null;
  return switch (hay) {
    'gasoline' || 'petrol' => ListingFuelType.petrol,
    'diesel' => ListingFuelType.diesel,
    'electric' || 'battery electric' || 'bev' => ListingFuelType.electric,
    _ => null,
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
