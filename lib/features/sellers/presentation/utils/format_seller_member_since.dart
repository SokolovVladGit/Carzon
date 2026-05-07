import '../../../../l10n/app_localizations.dart';

/// Month + year only (no day/time). Uses Russian **genitive** month names
/// (“мая”, not “май”) for phrases like «На Carzon с мая 2026».
String formatSellerMemberSinceMonthYear(
  AppLocalizations l10n,
  DateTime memberSince,
) {
  final local = memberSince.toLocal();
  final month = switch (local.month) {
    1 => l10n.sellerMonthGenitiveJanuary,
    2 => l10n.sellerMonthGenitiveFebruary,
    3 => l10n.sellerMonthGenitiveMarch,
    4 => l10n.sellerMonthGenitiveApril,
    5 => l10n.sellerMonthGenitiveMay,
    6 => l10n.sellerMonthGenitiveJune,
    7 => l10n.sellerMonthGenitiveJuly,
    8 => l10n.sellerMonthGenitiveAugust,
    9 => l10n.sellerMonthGenitiveSeptember,
    10 => l10n.sellerMonthGenitiveOctober,
    11 => l10n.sellerMonthGenitiveNovember,
    12 => l10n.sellerMonthGenitiveDecember,
    _ => throw ArgumentError.value(local.month, 'month', 'expected 1–12'),
  };
  return '$month ${local.year}';
}
