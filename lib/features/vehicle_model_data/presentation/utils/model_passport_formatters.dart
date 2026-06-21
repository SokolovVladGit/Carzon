import '../../../../l10n/app_localizations.dart';

/// One metric row for Model Passport listing details.
class ModelPassportMetricDisplay {
  const ModelPassportMetricDisplay({
    required this.label,
    required this.value,
    this.unit,
    this.isPrimaryHighlight = false,
  });

  final String label;
  final String value;
  final String? unit;
  final bool isPrimaryHighlight;
}

double? readModelPassportDouble(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) {
    final v = raw.toDouble();
    return v.isFinite && v > 0 ? v : null;
  }
  final parsed = double.tryParse(raw.toString().trim());
  if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
  return parsed;
}

String? readModelPassportText(dynamic raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  return text.isEmpty ? null : text;
}

bool modelPassportSummaryHasDisplayableFields(Map<String, dynamic>? summary) {
  if (summary == null || summary.isEmpty) return false;
  return readModelPassportDouble(summary['combined_l_per_100km']) != null ||
      readModelPassportDouble(summary['city_l_per_100km']) != null ||
      readModelPassportDouble(summary['highway_l_per_100km']) != null ||
      readModelPassportDouble(summary['co2_g_per_km']) != null ||
      readModelPassportText(summary['fuel_type']) != null;
}

String formatModelPassportConsumption(double value) {
  final rounded = (value * 10).round() / 10.0;
  return rounded.toStringAsFixed(1);
}

String formatModelPassportCo2(int value) => '$value';

String formatModelPassportDate(DateTime dt) {
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString().padLeft(4, '0');
  return '$d.$m.$y';
}

String resolveModelPassportSourceLabel(
  AppLocalizations l10n,
  String? sourceLabel,
) {
  final trimmed = sourceLabel?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return l10n.listingModelPassportSourceEpa;
}

DateTime? resolveModelPassportLastUpdated({
  DateTime? fetchedAt,
  DateTime? updatedAt,
}) => fetchedAt ?? updatedAt;

List<ModelPassportMetricDisplay> buildModelPassportMetricRows(
  AppLocalizations l10n,
  Map<String, dynamic>? summary,
) {
  if (summary == null || summary.isEmpty) return const [];

  final rows = <ModelPassportMetricDisplay>[];

  void addConsumption(String label, String key) {
    final value = readModelPassportDouble(summary[key]);
    if (value == null) return;
    rows.add(
      ModelPassportMetricDisplay(
        label: label,
        value: formatModelPassportConsumption(value),
        unit: l10n.listingModelPassportUnitLPer100km,
      ),
    );
  }

  addConsumption(
    l10n.listingModelPassportCombinedConsumption,
    'combined_l_per_100km',
  );
  addConsumption(l10n.listingModelPassportCityConsumption, 'city_l_per_100km');
  addConsumption(
    l10n.listingModelPassportHighwayConsumption,
    'highway_l_per_100km',
  );

  final co2 = readModelPassportDouble(summary['co2_g_per_km']);
  if (co2 != null) {
    rows.add(
      ModelPassportMetricDisplay(
        label: l10n.listingModelPassportCo2Emissions,
        value: formatModelPassportCo2(co2.round()),
        unit: l10n.listingModelPassportUnitGPerKm,
      ),
    );
  }

  final fuelType = readModelPassportText(summary['fuel_type']);
  if (fuelType != null) {
    rows.add(
      ModelPassportMetricDisplay(
        label: l10n.listingModelPassportFuelType,
        value: formatModelPassportFuelTypeDisplay(l10n, fuelType),
      ),
    );
  }

  return rows;
}

/// Primary fuel-economy tiles for the premium stat grid (excludes CO₂).
List<ModelPassportMetricDisplay> buildModelPassportPrimaryMetricTiles(
  AppLocalizations l10n,
  Map<String, dynamic>? summary,
) {
  if (summary == null || summary.isEmpty) return const [];

  final rows = <ModelPassportMetricDisplay>[];

  void addConsumption(
    String label,
    String key, {
    bool isPrimaryHighlight = false,
  }) {
    final value = readModelPassportDouble(summary[key]);
    if (value == null) return;
    rows.add(
      ModelPassportMetricDisplay(
        label: label,
        value: formatModelPassportConsumption(value),
        unit: l10n.listingModelPassportUnitLPer100km,
        isPrimaryHighlight: isPrimaryHighlight,
      ),
    );
  }

  addConsumption(
    l10n.listingModelPassportCombinedConsumption,
    'combined_l_per_100km',
    isPrimaryHighlight: true,
  );
  addConsumption(l10n.listingModelPassportCityConsumption, 'city_l_per_100km');
  addConsumption(
    l10n.listingModelPassportHighwayConsumption,
    'highway_l_per_100km',
  );

  final fuelType = readModelPassportText(summary['fuel_type']);
  if (fuelType != null) {
    rows.add(
      ModelPassportMetricDisplay(
        label: l10n.listingModelPassportFuelType,
        value: formatModelPassportFuelTypeDisplay(l10n, fuelType),
      ),
    );
  }

  return rows;
}

ModelPassportMetricDisplay? buildModelPassportCo2MetricTile(
  AppLocalizations l10n,
  Map<String, dynamic>? summary,
) {
  if (summary == null || summary.isEmpty) return null;
  final co2 = readModelPassportDouble(summary['co2_g_per_km']);
  if (co2 == null) return null;
  return ModelPassportMetricDisplay(
    label: l10n.listingModelPassportCo2Emissions,
    value: formatModelPassportCo2(co2.round()),
    unit: l10n.listingModelPassportUnitGPerKm,
  );
}

String _normalizeModelPassportFuelTypeKey(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Maps EPA/source fuel type codes to buyer-safe localized labels.
String formatModelPassportFuelTypeDisplay(AppLocalizations l10n, String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  final key = _normalizeModelPassportFuelTypeKey(trimmed);
  final mapped = switch (key) {
    'regular gasoline' || 'regular' =>
      l10n.listingModelPassportFuelRegularGasoline,
    'premium gasoline' || 'premium' =>
      l10n.listingModelPassportFuelPremiumGasoline,
    'midgrade gasoline' || 'midgrade' =>
      l10n.listingModelPassportFuelMidgradeGasoline,
    'diesel' => l10n.listingModelPassportFuelDiesel,
    'electricity' || 'electric' => l10n.listingModelPassportFuelElectricity,
    'hybrid' => l10n.listingModelPassportFuelHybrid,
    'plug in hybrid' || 'plug-in hybrid' =>
      l10n.listingModelPassportFuelPlugInHybrid,
    _ => null,
  };
  if (mapped != null) return mapped;

  if (trimmed.contains('_')) {
    return l10n.listingModelPassportFuelTypeGeneric;
  }

  return trimmed.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ');
}
