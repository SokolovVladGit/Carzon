import '../../domain/entities/listing.dart';

/// Display formatters shared by the listings tile and details page.
/// Kept feature-local — not promoted to core until a second feature needs them.

String formatEur(num value) {
  if (value == value.truncate()) {
    return '€${_thousands(value.toInt().toString())}';
  }
  return '€${value.toStringAsFixed(2)}';
}

String formatKm(int km) => '${_thousands(km.toString())} km';

String formatType(ListingType type) {
  switch (type) {
    case ListingType.sale:
      return 'For sale';
    case ListingType.exchange:
      return 'Exchange';
    case ListingType.both:
      return 'Sale or exchange';
  }
}

String formatStatus(ListingStatus status) {
  switch (status) {
    case ListingStatus.active:
      return 'Active';
    case ListingStatus.hidden:
      return 'Hidden';
    case ListingStatus.sold:
      return 'Sold';
    case ListingStatus.archived:
      return 'Archived';
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
