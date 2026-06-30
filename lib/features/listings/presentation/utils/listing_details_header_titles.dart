import '../../domain/entities/listing.dart';

/// Normalizes text for deterministic header comparisons:
/// lowercase, trimmed, punctuation → spaces, hyphen-like dashes → spaces,
/// internal whitespace collapsed.
String normalizeListingHeaderForComparison(String raw) {
  var s = raw.toLowerCase().trim();
  if (s.isEmpty) return '';
  // Hyphens commonly differ between structured fields vs seller title typing.
  s = s.replaceAll(RegExp(r'[-–—]'), ' ');
  // Other light punctuation clusters become word separators.
  s = s.replaceAll(RegExp(r'''[,.;:!?·•'"`\\/]+'''), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.trim();
}

String _squeezeSpaces(String v) => v.replaceAll(RegExp(r'\s+'), ' ').trim();

/// True when [char] ends a leading make token in model display dedupe (space only).
///
/// Hyphens are not boundaries so `Mercedes` does not strip `Mercedes-Benz`.
bool _isMakeModelDisplayTokenBoundary(String char) =>
    RegExp(r'\s').hasMatch(char);

/// When [model] repeats [make] as a whole leading token, returns the remainder
/// of [model] after that prefix (original casing). Null when no safe strip.
String? _modelRemainderAfterLeadingMakeToken(String make, String model) {
  if (make.isEmpty || model.isEmpty) return null;

  final makeLower = make.toLowerCase();
  if (!model.toLowerCase().startsWith(makeLower)) return null;

  final boundaryIndex = make.length;
  if (boundaryIndex >= model.length) return '';

  if (!_isMakeModelDisplayTokenBoundary(model[boundaryIndex])) return null;

  return model.substring(boundaryIndex).trimLeft();
}

/// Display-only make + model headline for cards, taglines, and structured copy.
///
/// Never mutates stored listing fields. Strips a repeated leading make token in
/// [modelRaw] when it matches [makeRaw] as a whole word (case-insensitive).
String listingDetailsVehicleIdentityLine(String makeRaw, String modelRaw) {
  final make = _squeezeSpaces(makeRaw);
  final model = _squeezeSpaces(modelRaw);
  if (make.isEmpty && model.isEmpty) return '';
  if (make.isEmpty) return model;
  if (model.isEmpty) return make;

  final remainder = _modelRemainderAfterLeadingMakeToken(make, model);
  if (remainder != null) {
    if (remainder.isEmpty) return make;
    return _squeezeSpaces('$make $remainder');
  }
  return _squeezeSpaces('$make $model');
}

String _squeezeTitle(String raw) => _squeezeSpaces(raw);

/// True when `c` separates the listing year digits from preceding text (comma,
/// dot, middot, spaces, slashes, hyphen-style dashes), not alphanumeric glue.
bool _isStructuralYearSeparatorBeforeListingYear(String char) =>
    RegExp(r'''^[,\s;:!?.·\-–—/]+$''').hasMatch(char);

/// Removes a trailing `[separators?]listingYear` suffix only when a separator
/// boundary exists immediately before the year ([char] glue like `coupe2023`
/// yields null). Returns peeled prefix trimmed of trailing separator run.
String? peelRawTitleTrailingListingYearIfSeparated(
  String squeezedTitle,
  int year,
) {
  final trimmed = squeezedTitle.trim();
  final yStr = year.toString();
  if (!trimmed.endsWith(yStr)) return null;

  final yearStart = trimmed.length - yStr.length;
  if (yearStart > 0 &&
      !_isStructuralYearSeparatorBeforeListingYear(trimmed[yearStart - 1])) {
    return null;
  }

  var prefix = trimmed.substring(0, yearStart);
  prefix = prefix.replaceAll(RegExp(r'''[,;:!?.·\-–—/\s]+$'''), '').trim();
  return prefix;
}

/// If [squeezedTitle] is structured make/model plus listing year only, returns
/// canonical [vehicleLine]; otherwise returns null (caller keeps custom title).
String? listingStructuredDisplayTitleTrimYearIfRedundant({
  required String squeezedTitle,
  required int listingYear,
  required String vehicleLine,
}) {
  if (vehicleLine.isEmpty) return null;

  final peeled = peelRawTitleTrailingListingYearIfSeparated(
    squeezedTitle,
    listingYear,
  );
  if (peeled == null || peeled.isEmpty) return null;

  final peelNorm = normalizeListingHeaderForComparison(peeled);
  final idNorm = normalizeListingHeaderForComparison(vehicleLine);
  if (peelNorm == idNorm && peelNorm.isNotEmpty) return vehicleLine;

  return null;
}

/// Primary headline shown in listing details: strips redundant trailing year when
/// the stored title equals structured identity plus that year only.
String listingDetailsDisplayPrimaryTitle(Listing listing) {
  final squeezed = _squeezeTitle(listing.title);
  final vehicleLine = listingDetailsVehicleIdentityLine(
    listing.make,
    listing.model,
  );

  final canonical = listingStructuredDisplayTitleTrimYearIfRedundant(
    squeezedTitle: squeezed,
    listingYear: listing.year,
    vehicleLine: vehicleLine,
  );
  return canonical ?? squeezed;
}

/// True when showing a structured subtitle would only echo make/model/year
/// the user already reads in the primary title (year also appears in chips).
bool listingDetailsTitleAlreadyEmbedsStructuredIdentity({
  required String rawTitle,
  required String vehicleLine,
  required int year,
}) {
  if (vehicleLine.isEmpty) return true;

  final idNorm = normalizeListingHeaderForComparison(vehicleLine);
  if (idNorm.isEmpty) return true;

  final titleNorm = normalizeListingHeaderForComparison(rawTitle);
  if (titleNorm.isEmpty) return false;

  if (titleNorm == idNorm) return true;

  final trimmedOfYear = _stripNormalizedTrailingListingYear(
    titleNorm,
    year.toString(),
  );
  if (trimmedOfYear.isNotEmpty && trimmedOfYear == idNorm) return true;

  if (titleNorm.contains(idNorm)) return true;

  return false;
}

String _stripNormalizedTrailingListingYear(String normalizedTitle, String y) {
  if (!normalizedTitle.endsWith(y)) return normalizedTitle;
  var prefix = normalizedTitle
      .substring(0, normalizedTitle.length - y.length)
      .trim();
  // Drop trailing commas / middots / filler left after stripping the year.
  prefix = prefix
      .replaceAll(RegExp(r'''[,·\s]+$'''), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return prefix;
}

String? listingDetailsStructuredHeaderTagline(Listing listing) {
  final rawTitle = listing.title.trim();
  if (rawTitle.isEmpty) return null;

  final vehicleLine = listingDetailsVehicleIdentityLine(
    listing.make,
    listing.model,
  );
  if (vehicleLine.isEmpty) return null;

  if (listingDetailsTitleAlreadyEmbedsStructuredIdentity(
    rawTitle: listing.title,
    vehicleLine: vehicleLine,
    year: listing.year,
  )) {
    return null;
  }

  return '$vehicleLine · ${listing.year}';
}

/// Listing details panel header: seller title whenever set; optional structured line.
class ListingDetailsHeaderDisplay {
  const ListingDetailsHeaderDisplay({required this.primaryLine, this.tagline});

  final String primaryLine;
  final String? tagline;

  factory ListingDetailsHeaderDisplay.fromListing(Listing listing) {
    final vehicleLine = listingDetailsVehicleIdentityLine(
      listing.make,
      listing.model,
    );
    final raw = listing.title.trim();

    final primaryLine = raw.isNotEmpty
        ? listingDetailsDisplayPrimaryTitle(listing)
        : vehicleLine;

    final tagline = listingDetailsStructuredHeaderTagline(listing);

    return ListingDetailsHeaderDisplay(
      primaryLine: primaryLine,
      tagline: tagline,
    );
  }
}
