import '../../../../l10n/app_localizations.dart';

String fuelPriceFuelLabel(AppLocalizations l10n, String fuelCode) {
  return switch (fuelCode) {
    'gasoline_95' => l10n.fuelPricesFuelGasoline95,
    'diesel' => l10n.fuelPricesFuelDiesel,
    'ai_98' => l10n.fuelPricesFuelAi98,
    'ai_95_premium' => l10n.fuelPricesFuelAi95Premium,
    'ai_95' => l10n.fuelPricesFuelAi95,
    'diesel_euro' => l10n.fuelPricesFuelDieselEuro,
    _ => fuelCode,
  };
}

String fuelPriceUnitLabel(AppLocalizations l10n, String currency) {
  return switch (currency) {
    'MDL' => l10n.fuelPricesUnitMdlPerLiter,
    'PMR_RUB' => l10n.fuelPricesUnitPmrRubPerLiter,
    _ => currency,
  };
}

String formatFuelPriceAmount(double price) {
  final rounded = (price * 100).roundToDouble() / 100;
  if (rounded == rounded.roundToDouble()) {
    return rounded.toStringAsFixed(0);
  }
  return rounded.toStringAsFixed(2);
}

String? fuelPriceDateLabel({
  required AppLocalizations l10n,
  required String? effectiveDate,
  required DateTime? fetchedAt,
}) {
  if (effectiveDate != null && effectiveDate.isNotEmpty) {
    return l10n.fuelPricesEffectiveDate(effectiveDate);
  }
  if (fetchedAt != null) {
    final local = fetchedAt.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    return l10n.fuelPricesLastFetched(date);
  }
  return null;
}

String fuelPriceScopeNote(AppLocalizations l10n, String territory) {
  return switch (territory) {
    'moldova' => l10n.fuelPricesMoldovaScopeNote,
    'pmr' => l10n.fuelPricesPmrScopeNote,
    _ => '',
  };
}
