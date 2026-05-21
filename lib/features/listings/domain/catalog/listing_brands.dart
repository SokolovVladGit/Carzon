import '../../../../shared/brands/brand_icon_resolver.dart';

/// Static brand catalog for make selection (Moldova / Pridnestrovian region).
/// Stored value remains plain text; callers may normalize unknown makes.
const List<String> kListingBrandCatalog = [
  'Toyota',
  'Volkswagen',
  'Skoda',
  'Opel',
  'BMW',
  'Mercedes-Benz',
  'Audi',
  'Ford',
  'Renault',
  'Dacia',
  'Hyundai',
  'Kia',
  'Nissan',
  'Mazda',
  'Honda',
  'Peugeot',
  'Citroen',
  'Chevrolet',
  'Mitsubishi',
  'Lexus',
  'Volvo',
  'Fiat',
  'Seat',
  'Land Rover',
  'Porsche',
  'Tesla',
  'Lada',
  'Other',
];

/// Sentinel catalog value for free-text / unknown makes (always last).
const String kListingBrandCatalogOther = 'Other';

/// Home feed quick-filter brands: full seller catalog except [kListingBrandCatalogOther].
final List<String> kListingBrandFeedQuickFilterCatalog = List.unmodifiable([
  for (final brand in kListingBrandCatalog)
    if (brand != kListingBrandCatalogOther) brand,
]);

/// Catalog makes shown with an initials monogram on Home when no SVG exists.
const Set<String> kListingBrandFeedQuickFilterMonogramFallback = {
  'Citroen',
  'Seat',
  'Porsche',
  'Lada',
};

/// Whether [catalogBrand] uses the Home monogram fallback (no dedicated SVG).
bool listingBrandFeedQuickFilterUsesMonogramFallback(String catalogBrand) =>
    kListingBrandFeedQuickFilterMonogramFallback.contains(catalogBrand);

/// True when the Home row should render initials instead of an SVG asset.
bool listingBrandFeedQuickFilterShouldUseMonogram(String catalogBrand) =>
    listingBrandFeedQuickFilterUsesMonogramFallback(catalogBrand) ||
    isBrandIconDefaultAssetPath(getBrandIconPath(catalogBrand));

/// Two-letter monogram for Home fallback tiles (e.g. Land Rover → LR).
String listingBrandFeedQuickFilterMonogram(String catalogBrand) {
  final parts = catalogBrand.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    return '${first.toUpperCase()}${second.toUpperCase()}';
  }
  final word = parts.single;
  if (word.length <= 2) return word.toUpperCase();
  return word.substring(0, 2).toUpperCase();
}

/// True when the feed "All brands" tile should read as selected.
bool listingBrandFeedQuickFilterAllSelected(String? currentMake) {
  final trimmed = currentMake?.trim();
  return trimmed == null || trimmed.isEmpty;
}

/// True when [catalogBrand] matches the active make filter (canonical spelling).
bool listingBrandFeedQuickFilterIsSelected(
  String? currentMake,
  String catalogBrand,
) => listingBrandNormalizeForLookup(currentMake) == catalogBrand;

/// True when [tappedBrand] would not change the active Home brand filter.
///
/// Aligns redundant-tap guards with tile selected-state: [tappedBrand] null
/// means "All" (only a no-op when [currentMake] is blank); otherwise compares
/// normalized catalog spellings.
bool listingBrandFeedQuickFilterSelectionUnchanged(
  String? currentMake,
  String? tappedBrand,
) {
  if (tappedBrand == null) {
    return listingBrandFeedQuickFilterAllSelected(currentMake);
  }
  return listingBrandFeedQuickFilterIsSelected(currentMake, tappedBrand);
}

String _normalizeBrandKey(String raw) => raw
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(RegExp(r'[-–—]'), '');

bool isKnownListingBrand(String? rawMake) =>
    listingBrandNormalizeForLookup(rawMake) != null;

/// Returns trimmed catalog label when [rawMake] matches a catalog entry
/// case-insensitively (hyphens / spaces folded);
/// otherwise `null` so callers keep free-text storage.
String? listingBrandNormalizeForLookup(String? rawMake) {
  final trimmed = rawMake?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final key = _normalizeBrandKey(trimmed);
  if (key.isEmpty) return null;

  for (final brand in kListingBrandCatalog) {
    if (_normalizeBrandKey(brand) == key) {
      return brand;
    }
  }
  return null;
}
