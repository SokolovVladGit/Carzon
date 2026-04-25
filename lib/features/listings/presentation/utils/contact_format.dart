/// Small pure helpers for seller-contact input and contact-link building.
///
/// Intentionally permissive: full phone-number parsing is out of scope
/// for MVP. These helpers are UI-layer utilities — they do not know
/// anything about Supabase.
library;

import '../../../../l10n/app_localizations.dart';

/// Default country code used when the seller entered a local phone
/// without a leading `+` / country prefix. Carzon's initial markets
/// (Moldova and the Transnistrian region) both use +373.
const String kDefaultCountryCode = '373';

/// Minimum count of digits required in a phone, after stripping
/// non-digit characters. Matches the DB-level CHECK constraint so
/// that client-side validation never sends a row the DB rejects.
const int kMinPhoneDigits = 7;

/// Extracts the digits-only form of a phone number.
String digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

/// Validates a seller-entered phone number.
///
/// Rules:
/// * allows `+`, digits, spaces, parentheses, dashes, and dots;
/// * requires at least [kMinPhoneDigits] digits after stripping;
/// * does not enforce strict E.164.
///
/// Returns `null` when valid, or a short error message when invalid.
String? validatePhone(AppLocalizations l10n, String? raw) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return l10n.phoneRequired;
  // Reject characters that are neither digits nor conventional phone
  // punctuation. Early guard against accidental paste of full text.
  if (!RegExp(r'^[+0-9()\-\s.]+$').hasMatch(v)) {
    return l10n.phoneInvalidChars;
  }
  if (digitsOnly(v).length < kMinPhoneDigits) {
    return l10n.phoneInvalid;
  }
  return null;
}

/// Validates an optional Telegram username.
///
/// Rules (applied only when the field has content):
/// * optional leading `@`,
/// * 5–32 chars after the optional `@`,
/// * letters, numbers, underscores only.
///
/// Returns `null` when valid or empty, or a short error message when
/// invalid. Empty input is valid because Telegram is optional.
String? validateTelegramUsername(AppLocalizations l10n, String? raw) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return null;
  if (!RegExp(r'^@?[A-Za-z0-9_]{5,32}$').hasMatch(v)) {
    return l10n.telegramInvalid;
  }
  return null;
}

/// Normalizes a Telegram username to the form stored in the DB and
/// used in `https://t.me/<username>` links: leading `@` stripped and
/// surrounding whitespace removed. Returns `null` if the input is
/// empty after trimming.
String? normalizeTelegramUsername(String? raw) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return null;
  final stripped = v.startsWith('@') ? v.substring(1) : v;
  return stripped.isEmpty ? null : stripped;
}

/// Builds the digits-only phone form used by WhatsApp links
/// (`https://wa.me/<digits>`).
///
/// * If the input already includes a country code (leading `+` or 10+
///   digits that look like an international number), the digits are
///   returned as-is.
/// * Otherwise [kDefaultCountryCode] (373) is prepended to treat the
///   number as a Moldova/Transnistria local number.
///
/// Returns `null` when the input is empty or has fewer than
/// [kMinPhoneDigits] digits (i.e. not a usable number).
String? whatsappDigits(String? raw) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return null;
  final digits = digitsOnly(v);
  if (digits.length < kMinPhoneDigits) return null;
  final hasPlus = v.startsWith('+');
  if (hasPlus) return digits;
  // Already starts with the default country code → keep as-is.
  if (digits.startsWith(kDefaultCountryCode)) return digits;
  // Heuristic: treat 10+ digit numbers as already international.
  if (digits.length >= 10) return digits;
  // Local form: strip a single leading "0" trunk prefix (standard for
  // Moldova/Transnistria mobile numbers) before prepending the
  // country code.
  final local = digits.startsWith('0') ? digits.substring(1) : digits;
  return '$kDefaultCountryCode$local';
}

/// Builds the `tel:` URI string for a raw phone value. Returns `null`
/// when the input is empty or unusable. The result preserves the
/// leading `+` when present, because dialers handle it correctly.
String? telUriString(String? raw) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return null;
  final digits = digitsOnly(v);
  if (digits.length < kMinPhoneDigits) return null;
  return v.startsWith('+') ? 'tel:+$digits' : 'tel:$digits';
}
