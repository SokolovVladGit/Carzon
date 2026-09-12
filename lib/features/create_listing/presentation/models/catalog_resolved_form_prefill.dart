import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/manual_smart_fill_result.dart';

/// Persistable optional specs from Manual Smart Fill consensus.
/// Independent of VIN taxonomy mapping.
class CatalogResolvedFormPrefill {
  const CatalogResolvedFormPrefill({
    this.bodyType,
    this.fuelType,
    this.engineDisplacementLiters,
    this.enginePowerHp,
    this.transmissionType,
  });

  final ListingBodyType? bodyType;
  final ListingFuelType? fuelType;
  final double? engineDisplacementLiters;
  final int? enginePowerHp;
  final ListingTransmissionType? transmissionType;

  bool get isEmpty =>
      bodyType == null &&
      fuelType == null &&
      engineDisplacementLiters == null &&
      enginePowerHp == null &&
      transmissionType == null;
}

CatalogResolvedFormPrefill catalogResolvedFormPrefill(
  ManualSmartFillConsensusSpecs specs,
) {
  return CatalogResolvedFormPrefill(
    bodyType: catalogResolvedBodyType(specs.bodyType),
    fuelType: catalogResolvedFuelType(specs.fuelType),
    engineDisplacementLiters: catalogResolvedDisplacementLiters(
      specs.engineDisplacementLiters,
    ),
    enginePowerHp: catalogResolvedPowerHp(specs.enginePowerHp),
    transmissionType: catalogResolvedTransmissionType(specs.transmissionType),
  );
}

ListingTransmissionType? catalogResolvedTransmissionType(String? raw) {
  return listingTransmissionTypeFromDb(raw);
}

ListingBodyType? catalogResolvedBodyType(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  return switch (hay) {
    'sedan' || 'saloon' => ListingBodyType.sedan,
    'hatchback' || 'hatch' => ListingBodyType.hatchback,
    'wagon' || 'estate' || 'combi' => ListingBodyType.wagon,
    'suv' || 'sport utility vehicle' => ListingBodyType.suv,
    'coupe' || 'coupé' => ListingBodyType.coupe,
    'convertible' || 'cabriolet' || 'cabrio' => ListingBodyType.convertible,
    'pickup' || 'pick-up' || 'pick up' => ListingBodyType.pickup,
    'van' => ListingBodyType.van,
    'minivan' || 'mpv' => ListingBodyType.minivan,
    _ => null,
  };
}

ListingFuelType? catalogResolvedFuelType(String? raw) {
  final hay = _norm(raw);
  if (hay == null) return null;
  return switch (hay) {
    'petrol' || 'gasoline' => ListingFuelType.petrol,
    'diesel' => ListingFuelType.diesel,
    'hybrid' => ListingFuelType.hybrid,
    'plug_in_hybrid' ||
    'plugin_hybrid' ||
    'phev' => ListingFuelType.plugInHybrid,
    'electric' || 'bev' => ListingFuelType.electric,
    'lpg' => ListingFuelType.lpg,
    'cng' => ListingFuelType.cng,
    _ => null,
  };
}

double? catalogResolvedDisplacementLiters(num? raw) {
  if (raw == null || !raw.isFinite || raw <= 0 || raw > 30) return null;
  return (raw.toDouble() * 1000).round() / 1000;
}

int? catalogResolvedPowerHp(num? raw) {
  if (raw == null || !raw.isFinite) return null;
  final hp = raw.round();
  if (hp <= 0 || hp > 3000) return null;
  return hp;
}

String formatCatalogDisplacementField(double liters) {
  return liters.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}

bool catalogMayFillField({
  required bool isEmpty,
  required bool vinOwned,
  bool catalogOwned = false,
}) {
  if (vinOwned) return false;
  return isEmpty || catalogOwned;
}

bool vinMayReplaceField({required bool isEmpty, required bool catalogOwned}) {
  return isEmpty || catalogOwned;
}

String? _norm(String? raw) {
  if (raw == null) return null;
  final t = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return t.isEmpty ? null : t;
}
