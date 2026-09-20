/// Client-side representability for Create Listing publish/preview.
///
/// Matches hosted columns:
/// - `listings.mileage_km` PostgreSQL `integer` / int4
/// - `listings.price_eur` PostgreSQL `numeric(12,2)`
const int kListingMileageKmMax = 2147483647;

/// Largest positive `numeric(12,2)` value.
const String kListingPriceAmountMaxLiteral = '9999999999.99';

final _plainUnsignedInt = RegExp(r'^\d+$');
final _plainUnsignedDecimal = RegExp(r'^\d+(\.\d+)?$');

/// Digits-only mileage in `0..=[kListingMileageKmMax]`.
int? parseListingPublishMileage(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (!_plainUnsignedInt.hasMatch(trimmed)) return null;
  final n = int.tryParse(trimmed);
  if (n == null || n < 0 || n > kListingMileageKmMax) return null;
  return n;
}

/// Plain unsigned decimal price in `(0, 9999999999.99]`.
///
/// Rejects exponent notation, signs, NaN/Infinity tokens, and values that
/// cannot be stored in `numeric(12,2)`.
num? parseListingPublishPrice(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.contains('e') || trimmed.contains('E')) return null;
  if (!_plainUnsignedDecimal.hasMatch(trimmed)) return null;
  if (!_isWithinNumeric12_2(trimmed)) return null;
  final n = num.parse(trimmed);
  if (n.toDouble().isNaN || !n.toDouble().isFinite || n <= 0) return null;
  return n;
}

bool _isWithinNumeric12_2(String s) {
  final parts = s.split('.');
  var whole = parts[0];
  whole = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final frac = parts.length == 2 ? parts[1] : '';
  if (whole.length > 10) return false;
  if (whole.length < 10) return true;
  final wholeCmp = whole.compareTo('9999999999');
  if (wholeCmp < 0) return true;
  if (wholeCmp > 0) return false;
  if (frac.isEmpty) return true;
  if (frac.length <= 2) {
    return frac.padRight(2, '0').compareTo('99') <= 0;
  }
  final head = frac.substring(0, 2);
  final tail = frac.substring(2);
  final headCmp = head.compareTo('99');
  if (headCmp < 0) return true;
  if (headCmp > 0) return false;
  return tail.split('').every((c) => c == '0');
}
