import '../../domain/entities/listing.dart';

/// Normalizes free-text lines for semantic comparison (subtitle vs vehicle line).
String normalizeListingHeaderLine(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// How the listing details heading presents make/model vs custom title (tagline).
class ListingDetailsHeaderDisplay {
  const ListingDetailsHeaderDisplay({required this.primaryLine, this.tagline});

  final String primaryLine;
  final String? tagline;

  factory ListingDetailsHeaderDisplay.fromListing(Listing listing) {
    final rawTitle = listing.title.trim();
    final make = listing.make.trim();
    final model = listing.model.trim();

    String squeezeSpaces(String v) => v.replaceAll(RegExp(r'\s+'), ' ').trim();

    final vehicleLine = make.isEmpty && model.isEmpty
        ? rawTitle
        : make.isEmpty
        ? squeezeSpaces(model)
        : model.isEmpty
        ? squeezeSpaces(make)
        : squeezeSpaces('$make $model');

    final primary = vehicleLine.isNotEmpty ? vehicleLine : rawTitle;

    if (rawTitle.isEmpty) {
      return ListingDetailsHeaderDisplay(primaryLine: primary);
    }

    final primNorm = normalizeListingHeaderLine(primary);
    final titleNorm = normalizeListingHeaderLine(rawTitle);

    if (titleNorm == primNorm || titleNorm.isEmpty) {
      return ListingDetailsHeaderDisplay(primaryLine: primary);
    }

    return ListingDetailsHeaderDisplay(primaryLine: primary, tagline: rawTitle);
  }
}
