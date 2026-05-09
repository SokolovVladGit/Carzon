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
}) {
  if (trimmedUserTitle.isNotEmpty) return trimmedUserTitle;
  final m = make.trim();
  final mo = model.trim();
  final yearOk = year > 0;

  if (m.isNotEmpty && mo.isNotEmpty) {
    return yearOk ? '$m $mo, $year' : '$m $mo';
  }
  if (m.isNotEmpty) {
    return yearOk ? '$m, $year' : m;
  }
  if (mo.isNotEmpty) {
    return yearOk ? '$mo, $year' : mo;
  }
  return l10n.listingTitleFallbackDefault;
}
