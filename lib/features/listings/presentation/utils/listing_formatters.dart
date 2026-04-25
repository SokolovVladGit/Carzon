import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing.dart';

/// Display formatters shared by the listings tile and details page.
/// Kept feature-local — not promoted to core until a second feature
/// needs them. Enum-backed label helpers accept an [AppLocalizations]
/// so they can be called from any widget without reaching out to
/// `context` themselves.

String formatEur(num value) {
  if (value == value.truncate()) {
    return '€${_thousands(value.toInt().toString())}';
  }
  return '€${value.toStringAsFixed(2)}';
}

String formatKm(int km) => '${_thousands(km.toString())} km';

String formatType(AppLocalizations l10n, ListingType type) {
  switch (type) {
    case ListingType.sale:
      return l10n.formatTypeSale;
    case ListingType.exchange:
      return l10n.formatTypeExchange;
    case ListingType.both:
      return l10n.formatTypeBoth;
  }
}

String formatMarketRegion(AppLocalizations l10n, MarketRegion region) {
  switch (region) {
    case MarketRegion.transnistria:
      return l10n.regionTransnistria;
    case MarketRegion.moldova:
      return l10n.regionMoldova;
  }
}

String formatStatus(AppLocalizations l10n, ListingStatus status) {
  switch (status) {
    case ListingStatus.active:
      return l10n.statusActive;
    case ListingStatus.hidden:
      return l10n.statusHidden;
    case ListingStatus.sold:
      return l10n.statusSold;
    case ListingStatus.archived:
      return l10n.statusArchived;
  }
}

String formatDate(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _thousands(String digits) {
  final buf = StringBuffer();
  final n = digits.length;
  for (var i = 0; i < n; i++) {
    if (i > 0 && (n - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}
