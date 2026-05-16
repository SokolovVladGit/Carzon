/// Phase 1 VIN: syntactic validation only (no checksum, no external APIs).
class ListingVin {
  ListingVin._();

  static final RegExp _allowedChars = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  /// Uppercase A–Z except I/O/Q, digits 0–9; length 17 after normalization.
  static bool isValidNormalized(String normalized) =>
      normalized.length == 17 && _allowedChars.hasMatch(normalized);

  /// Returns `null` when input is empty after normalization (optional VIN).
  static String? normalizeOptional(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(' ', '').replaceAll('-', '');
    if (s.isEmpty) return null;
    return s.toUpperCase();
  }

  /// Whether user input is blank / whitespace-only (no VIN intent).
  static bool isBlankInput(String? raw) =>
      raw == null || raw.trim().isEmpty;

  /// Non-null normalized string must satisfy [isValidNormalized].
  static bool isOptionalInputValid(String? raw) {
    final n = normalizeOptional(raw);
    if (n == null) return true;
    return isValidNormalized(n);
  }

  /// Normalized VIN for RPC after UI validation, or `null` when omitted.
  static String? normalizedOrNullForCreate(String? raw) =>
      normalizeOptional(raw);
}
