import '../../../../l10n/app_localizations.dart';

/// One label/value row for NHTSA [normalized_summary] display (buyer or owner).
class NhtsaVinSummaryField {
  const NhtsaVinSummaryField({
    required this.label,
    required this.value,
    this.stackValue = false,
  });

  final String label;
  final String value;

  /// Label above value (wrap-friendly) for long catalog strings.
  final bool stackValue;
}

/// Grouped NHTSA fields for buyer report layout.
class NhtsaVinSummaryGroup {
  const NhtsaVinSummaryGroup({required this.title, required this.fields});

  final String title;
  final List<NhtsaVinSummaryField> fields;
}

/// Worker placeholder when a numeric field was formatted with a bad template (`$n`).
const String kNhtsaWorkerNumericPlaceholder = r'$n';

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s == kNhtsaWorkerNumericPlaceholder) return null;
  return s;
}

int? _year(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

/// Positive integer count (cylinders, doors). Repairs stored `$n` from worker bug.
String? _positiveCountDisplay(dynamic v) {
  if (v == null) return null;
  if (v is int) return v > 0 ? '$v' : null;
  if (v is num) {
    final n = v.toInt();
    return n > 0 ? '$n' : null;
  }
  final s = v.toString().trim();
  if (s.isEmpty || s == kNhtsaWorkerNumericPlaceholder) return null;
  final n = int.tryParse(s);
  if (n != null && n > 0) return '$n';
  return null;
}

bool _catalogCaution(Map<String, dynamic>? map) {
  if (map == null) return false;
  final v = map['catalog_decode_caution'];
  return v == true || v == 'true';
}

bool nhtsaVinSummaryPrefersStackedValue(String fieldKey) {
  switch (fieldKey) {
    case 'manufacturer':
    case 'body_type':
    case 'vehicle_type':
    case 'series':
    case 'plant_company':
    case 'engine':
    case 'gross_vehicle_weight_rating':
      return true;
    default:
      return false;
  }
}

String? _valueForSummaryKey(String key, Map<String, dynamic> map) {
  switch (key) {
    case 'year':
      final y = _year(map['year']);
      return y == null ? null : '$y';
    case 'cylinders':
    case 'doors':
      return _positiveCountDisplay(map[key]);
    default:
      return _str(map[key]);
  }
}

typedef _NhtsaFieldDef = ({
  String key,
  String Function(AppLocalizations l10n) label,
});

List<_NhtsaFieldDef> _coreIdentityDefs() => [
  (key: 'make', label: (l10n) => l10n.editListingVinReportDecodedMakeLabel),
  (key: 'model', label: (l10n) => l10n.editListingVinReportDecodedModelLabel),
  (key: 'year', label: (l10n) => l10n.editListingVinReportDecodedYearLabel),
  (
    key: 'manufacturer',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaManufacturerLabel,
  ),
];

List<_NhtsaFieldDef> _vehicleSpecsDefs() => [
  (
    key: 'body_type',
    label: (l10n) => l10n.editListingVinReportDecodedBodyLabel,
  ),
  (
    key: 'vehicle_type',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaVehicleTypeLabel,
  ),
  (key: 'trim', label: (l10n) => l10n.listingBuyerVinReportNhtsaTrimLabel),
  (key: 'series', label: (l10n) => l10n.listingBuyerVinReportNhtsaSeriesLabel),
  (
    key: 'fuel_type',
    label: (l10n) => l10n.editListingVinReportDecodedFuelLabel,
  ),
  (
    key: 'engine',
    label: (l10n) => l10n.listingBuyerVinReportDecodedEngineLabel,
  ),
  (
    key: 'transmission',
    label: (l10n) => l10n.listingBuyerVinReportDecodedTransmissionLabel,
  ),
  (
    key: 'drive_type',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaDriveTypeLabel,
  ),
  (
    key: 'displacement',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaDisplacementLabel,
  ),
  (
    key: 'cylinders',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaCylindersLabel,
  ),
  (key: 'doors', label: (l10n) => l10n.listingBuyerVinReportNhtsaDoorsLabel),
  (
    key: 'gross_vehicle_weight_rating',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaGvwrLabel,
  ),
];

List<_NhtsaFieldDef> _originDefs() => [
  (
    key: 'plant_country',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaPlantCountryLabel,
  ),
  (
    key: 'plant_city',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaPlantCityLabel,
  ),
  (
    key: 'plant_company',
    label: (l10n) => l10n.listingBuyerVinReportNhtsaPlantCompanyLabel,
  ),
];

NhtsaVinSummaryGroup? _buildGroup(
  AppLocalizations l10n,
  Map<String, dynamic> map,
  String title,
  List<_NhtsaFieldDef> defs,
) {
  final fields = <NhtsaVinSummaryField>[];
  for (final def in defs) {
    final value = _valueForSummaryKey(def.key, map);
    if (value == null) continue;
    fields.add(
      NhtsaVinSummaryField(
        label: def.label(l10n),
        value: value,
        stackValue: nhtsaVinSummaryPrefersStackedValue(def.key),
      ),
    );
  }
  if (fields.isEmpty) return null;
  return NhtsaVinSummaryGroup(title: title, fields: fields);
}

/// Grouped NHTSA summary for buyer report (core → specs → origin). Omits empty values.
List<NhtsaVinSummaryGroup> nhtsaVinSummaryGroupsFromMap(
  AppLocalizations l10n,
  Map<String, dynamic>? map,
) {
  if (map == null || map.isEmpty) return const [];

  final out = <NhtsaVinSummaryGroup>[];
  final core = _buildGroup(
    l10n,
    map,
    l10n.listingBuyerVinReportNhtsaGroupCoreIdentity,
    _coreIdentityDefs(),
  );
  final specs = _buildGroup(
    l10n,
    map,
    l10n.listingBuyerVinReportNhtsaGroupVehicleSpecs,
    _vehicleSpecsDefs(),
  );
  final origin = _buildGroup(
    l10n,
    map,
    l10n.listingBuyerVinReportNhtsaGroupOrigin,
    _originDefs(),
  );
  if (core != null) out.add(core);
  if (specs != null) out.add(specs);
  if (origin != null) out.add(origin);
  return out;
}

/// Flat ordered list (all groups concatenated). Used by tests and legacy callers.
List<NhtsaVinSummaryField> nhtsaVinSummaryFieldsFromMap(
  AppLocalizations l10n,
  Map<String, dynamic>? map,
) {
  return [for (final g in nhtsaVinSummaryGroupsFromMap(l10n, map)) ...g.fields];
}

/// Whether to show a conservative catalog-decode caution (no raw NHTSA error codes).
bool nhtsaVinSummaryShowsCatalogCaution(Map<String, dynamic>? map) =>
    _catalogCaution(map);
