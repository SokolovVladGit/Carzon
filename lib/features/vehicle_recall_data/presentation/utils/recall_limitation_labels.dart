import '../../../../l10n/app_localizations.dart';

const List<String> kRecallDefaultLimitationCodes = [
  'us_market_data_only',
  'model_level_not_exact_vehicle',
  'not_vin_verified_recall_status',
  'may_differ_by_trim_engine_market',
  'verify_with_official_dealer_or_nhtsa',
];

/// Maps Recall limitation codes to buyer-safe localized bullets.
List<String> localizedRecallLimitationBullets(
  AppLocalizations l10n,
  List<String> rawCodes,
) {
  final codes = rawCodes
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();
  final effective = codes.isEmpty ? kRecallDefaultLimitationCodes : codes;

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
    final generic = l10n.listingRecallLimitationGeneric;
    if (!out.contains(generic)) out.add(generic);
  }

  if (out.isEmpty) {
    for (final code in kRecallDefaultLimitationCodes) {
      final label = _labelForCode(l10n, code);
      if (label != null && !out.contains(label)) out.add(label);
    }
  }

  return out;
}

String? _labelForCode(AppLocalizations l10n, String code) {
  switch (code) {
    case 'us_market_data_only':
      return l10n.listingRecallLimitationUsMarketDataOnly;
    case 'model_level_not_exact_vehicle':
      return l10n.listingRecallLimitationModelLevelNotExactVehicle;
    case 'not_vin_verified_recall_status':
      return l10n.listingRecallLimitationNotVinVerifiedRecallStatus;
    case 'may_differ_by_trim_engine_market':
      return l10n.listingRecallLimitationMayDifferByTrimEngineMarket;
    case 'verify_with_official_dealer_or_nhtsa':
      return l10n.listingRecallLimitationVerifyWithOfficialDealerOrNhtsa;
    case 'multiple_campaigns_listed':
      return l10n.listingRecallLimitationMultipleCampaignsListed;
    case 'source_data_unavailable':
      return l10n.listingRecallLimitationGeneric;
    default:
      return null;
  }
}
