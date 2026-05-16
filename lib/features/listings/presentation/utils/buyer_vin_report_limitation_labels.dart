import '../../../../l10n/app_localizations.dart';

/// Maps worker [limitation_codes] to buyer-safe Russian explanations.
/// Unknown codes are not shown verbatim; a generic line is appended instead.
List<String> localizedBuyerVinReportLimitationBullets(
  AppLocalizations l10n,
  List<String> rawCodes,
) {
  if (rawCodes.isEmpty) return const [];

  final codes = rawCodes.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  if (codes.isEmpty) return const [];

  var unknown = false;
  final idx = <int>{};

  for (final c in codes) {
    switch (c) {
      case 'basic_decode_only':
        break;
      case 'not_md_pmr_official_verification':
      case 'not_registration_check':
        idx.add(0);
        break;
      case 'not_ownership_check':
        idx.add(1);
        break;
      case 'not_accident_history':
        idx.add(2);
        break;
      case 'not_insurance_check':
        idx.add(3);
        break;
      case 'not_mileage_check':
        idx.add(4);
        break;
      default:
        unknown = true;
    }
  }

  if (idx.isEmpty && !unknown) {
    for (var i = 0; i <= 5; i++) {
      idx.add(i);
    }
  } else if (idx.isNotEmpty) {
    idx.add(5);
  }

  final labels = [
    l10n.listingBuyerVinReportLimitationRegistrationMdPmr,
    l10n.listingBuyerVinReportLimitationOwner,
    l10n.listingBuyerVinReportLimitationAccidentHistory,
    l10n.listingBuyerVinReportLimitationInsurance,
    l10n.listingBuyerVinReportLimitationMileage,
    l10n.listingBuyerVinReportLimitationLegalEncumbrances,
  ];

  final out = <String>[];
  for (var i = 0; i < 6; i++) {
    if (idx.contains(i)) {
      out.add(labels[i]);
    }
  }

  if (unknown) {
    out.add(l10n.listingBuyerVinReportLimitationUnknownFallback);
  }

  return out;
}
