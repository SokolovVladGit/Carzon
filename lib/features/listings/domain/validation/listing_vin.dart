/// VIN syntax plus a conservative North-American check-digit helper.
///
/// [isValidNormalized] / [isOptionalInputValid] stay syntactic so submit/RPC
/// contracts do not change. Check-digit gating is opt-in via
/// [canAttemptResolve].
class ListingVin {
  ListingVin._();

  static final RegExp _allowedChars = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  /// ISO 3780 WMI region digits used by FMVSS 115 / NA check-digit VINs:
  /// 1/4/5 United States, 2 Canada, 3 Mexico.
  static final RegExp _northAmericanWmi = RegExp(r'^[1-5]');

  static const _weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];

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
  static bool isBlankInput(String? raw) => raw == null || raw.trim().isEmpty;

  /// Non-null normalized string must satisfy [isValidNormalized].
  static bool isOptionalInputValid(String? raw) {
    final n = normalizeOptional(raw);
    if (n == null) return true;
    return isValidNormalized(n);
  }

  /// Normalized VIN for RPC after UI validation, or `null` when omitted.
  static String? normalizedOrNullForCreate(String? raw) =>
      normalizeOptional(raw);

  /// True only for syntactically valid NA-region VINs (WMI 1–5).
  static bool isCheckDigitApplicable(String normalized) =>
      isValidNormalized(normalized) && _northAmericanWmi.hasMatch(normalized);

  static ListingVinCheckDigitStatus checkDigitStatus(String normalized) {
    if (!isValidNormalized(normalized)) {
      return ListingVinCheckDigitStatus.notApplicable;
    }
    if (!isCheckDigitApplicable(normalized)) {
      return ListingVinCheckDigitStatus.notApplicable;
    }
    return _computedCheckDigit(normalized) == normalized[8]
        ? ListingVinCheckDigitStatus.valid
        : ListingVinCheckDigitStatus.invalid;
  }

  /// Syntax-valid and either non-NA or NA with a matching check digit.
  static bool canAttemptResolve(String normalized) {
    if (!isValidNormalized(normalized)) return false;
    return checkDigitStatus(normalized) != ListingVinCheckDigitStatus.invalid;
  }

  /// Position-9 check digit, or `null` when the VIN is not 17 valid chars.
  static String? computedCheckDigit(String normalized) {
    if (!isValidNormalized(normalized)) return null;
    return _computedCheckDigit(normalized);
  }

  static String _computedCheckDigit(String normalized) {
    var sum = 0;
    for (var i = 0; i < 17; i++) {
      sum += _transliterate(normalized.codeUnitAt(i)) * _weights[i];
    }
    final rem = sum % 11;
    return rem == 10 ? 'X' : '$rem';
  }

  static int _transliterate(int unit) {
    if (unit >= 48 && unit <= 57) return unit - 48;
    return switch (String.fromCharCode(unit)) {
      'A' || 'J' => 1,
      'B' || 'K' || 'S' => 2,
      'C' || 'L' || 'T' => 3,
      'D' || 'M' || 'U' => 4,
      'E' || 'N' || 'V' => 5,
      'F' || 'W' => 6,
      'G' || 'P' || 'X' => 7,
      'H' || 'Y' => 8,
      'R' || 'Z' => 9,
      _ => 0,
    };
  }
}

enum ListingVinCheckDigitStatus { notApplicable, valid, invalid }
