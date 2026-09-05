import '../../../l10n/app_localizations.dart';

/// Resolves the title persisted via listing RPCs (always a non-empty string).
///
/// - Non-empty trimmed user [trimmedUserTitle] is used as-is.
/// - Otherwise builds a short label from structured fields:
///   1. `make + model + year` → `{make} {model}, {year}`
///   2. `make + model` (year unset/invalid) → `{make} {model}`
///   3. `make + year` → `{make}, {year}` (model empty)
///   4. `make` only → `{make}` (model empty, year invalid)
///   5. Model present but make empty → `{model}, {year}` or `{model}` if year invalid
///   6. [AppLocalizations.listingTitleFallbackDefault] when nothing else applies.
String resolvedListingTitleForSubmit({
  required String trimmedUserTitle,
  required String make,
  required String model,
  required int year,
  required AppLocalizations l10n,
  String? variant,
}) {
  if (trimmedUserTitle.isNotEmpty) return trimmedUserTitle;
  final m = make.trim();
  final mo = model.trim();
  final vr = variant?.trim() ?? '';
  final yearOk = year > 0;

  String withYear(String identity) => yearOk ? '$identity, $year' : identity;

  if (m.isNotEmpty && mo.isNotEmpty) {
    final identity = vr.isEmpty ? '$m $mo' : '$m $mo $vr';
    return withYear(identity);
  }
  if (m.isNotEmpty) {
    return withYear(m);
  }
  if (mo.isNotEmpty) {
    return withYear(mo);
  }
  return l10n.listingTitleFallbackDefault;
}
