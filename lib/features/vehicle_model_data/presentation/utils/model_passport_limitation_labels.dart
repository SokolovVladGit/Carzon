import '../../../../l10n/app_localizations.dart';

const List<String> kModelPassportDefaultLimitationCodes = [
  'us_market_data_only',
  'may_differ_by_trim_engine_market',
  'model_level_not_exact_vehicle',
  'not_vehicle_history',
  'not_recall_data',
];

/// Maps Model Passport limitation codes to buyer-safe localized bullets.
List<String> localizedModelPassportLimitationBullets(
  AppLocalizations l10n,
  List<String> rawCodes,
) {
  final codes = rawCodes
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();
  final effective = codes.isEmpty ? kModelPassportDefaultLimitationCodes : codes;

  final out = <String>[];
  var unknown = false;

  for (final code in effective) {
    final label = _labelForCode(l10n, code);
    if (label == null) {
      unknown = true;
      continue;
    }
    if (!out.contains(label)) out.add(label);
  }

  if (unknown) {
    final generic = l10n.listingModelPassportLimitationGeneric;
    if (!out.contains(generic)) out.add(generic);
  }

  if (out.isEmpty) {
    for (final code in kModelPassportDefaultLimitationCodes) {
      final label = _labelForCode(l10n, code);
      if (label != null && !out.contains(label)) out.add(label);
    }
  }

  return out;
}

String? _labelForCode(AppLocalizations l10n, String code) {
  switch (code) {
    case 'us_market_data_only':
      return l10n.listingModelPassportLimitationUsMarketOnly;
    case 'may_differ_by_trim_engine_market':
      return l10n.listingModelPassportLimitationTrimEngineMarket;
    case 'model_level_not_exact_vehicle':
      return l10n.listingModelPassportLimitationModelLevel;
    case 'source_data_unavailable':
      return l10n.listingModelPassportLimitationSourceUnavailable;
    case 'open_data_unverified':
      return l10n.listingModelPassportLimitationOpenData;
    case 'not_vehicle_history':
      return l10n.listingModelPassportLimitationNotHistory;
    case 'not_recall_data':
      return l10n.listingModelPassportLimitationNotRecall;
    case 'multiple_configurations_possible':
      return l10n.listingModelPassportLimitationMultipleConfigurations;
    case 'basic_catalog_reference_only':
      return l10n.listingModelPassportLimitationBasicCatalogOnly;
    default:
      return null;
  }
}
