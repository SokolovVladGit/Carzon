import '../../../../shared/brands/brand_icon_resolver.dart';

/// Static brand catalog for make selection (Moldova / Pridnestrovian region).
///
/// **Single source of truth** for vehicle make / brand across the app:
/// - [kListingBrandCatalog] — create listing, edit listing, advanced filter sheet,
///   filter-alert editor ([ListingsFilterForm] / [ListingBrandPickSheet]), and
///   make normalization ([listingBrandNormalizeForLookup]).
/// - [kListingBrandFeedQuickFilterCatalog] — home feed horizontal quick filters
///   only (same brands except [kListingBrandCatalogOther]).
///
/// Stored value remains plain text; pickers submit canonical catalog spellings
/// (e.g. `Mercedes-Benz`, `Lynk & Co`). Callers may normalize unknown makes via
/// [listingBrandNormalizeForLookup].
///
/// Logo assets (optional): `assets/brands/svg/{slug}.svg` where [slug] is the
/// kebab-case resolver slug from [getBrandIconPath] (e.g. `mercedes-benz`,
/// `great-wall`, `lynk-co`, `li-auto`). Missing assets fall back to Home-feed
/// initials monograms — no runtime asset errors.
const List<String> kListingBrandCatalog = [
  'Toyota',
  'Volkswagen',
  'Skoda',
  'Opel',
  'BMW',
  'Mercedes-Benz',
  'Audi',
  'Volvo',
  'Ford',
  'Fiat',
  'Honda',
  'Hyundai',
  'Kia',
  'Nissan',
  'Renault',
  'Peugeot',
  'Citroen',
  'Dacia',
  'Mazda',
  'Mitsubishi',
  'Subaru',
  'Suzuki',
  'Seat',
  'Cupra',
  'Chevrolet',
  'Tesla',
  'Lexus',
  'Land Rover',
  'Jeep',
  'Porsche',
  'Mini',
  'Smart',
  'Alfa Romeo',
  'Jaguar',
  'Chrysler',
  'Dodge',
  'Ram',
  'GMC',
  'Lincoln',
  'Buick',
  'Hummer',
  'Cadillac',
  'Infiniti',
  'Acura',
  'DS Automobiles',
  'Genesis',
  'Polestar',
  'SsangYong',
  'KGM',
  'Isuzu',
  'Daihatsu',
  'Daewoo',
  'Datsun',
  'Abarth',
  'Lancia',
  'BYD',
  'Chery',
  'Geely',
  'Haval',
  'Great Wall',
  'MG',
  'Omoda',
  'Jaecoo',
  'Exeed',
  'Changan',
  'Dongfeng',
  'BAIC',
  'GAC',
  'FAW',
  'JAC',
  'Jetour',
  'Hongqi',
  'Tank',
  'Wey',
  'Lynk & Co',
  'Zeekr',
  'NIO',
  'XPeng',
  'Leapmotor',
  'Li Auto',
  'ORA',
  'Maxus',
  'Seres',
  'Voyah',
  'Aion',
  'Bestune',
  'DFSK',
  'Foton',
  'VinFast',
  'Lada',
  'UAZ',
  'Moskvich',
  'Other',
];

/// Sentinel catalog value for free-text / unknown makes (always last).
const String kListingBrandCatalogOther = 'Other';

/// Home feed quick-filter brands: full seller catalog except [kListingBrandCatalogOther].
final List<String> kListingBrandFeedQuickFilterCatalog = List.unmodifiable([
  for (final brand in kListingBrandCatalog)
    if (brand != kListingBrandCatalogOther) brand,
]);

/// Catalog makes that always use initials on Home even when an SVG slug exists.
const Set<String> kListingBrandFeedQuickFilterMonogramFallback = {};

/// Whether [catalogBrand] uses the Home monogram fallback (no dedicated SVG).
bool listingBrandFeedQuickFilterUsesMonogramFallback(String catalogBrand) =>
    kListingBrandFeedQuickFilterMonogramFallback.contains(catalogBrand);

/// True when the Home row should render initials instead of an SVG asset.
bool listingBrandFeedQuickFilterShouldUseMonogram(String catalogBrand) =>
    listingBrandFeedQuickFilterUsesMonogramFallback(catalogBrand) ||
    isBrandIconDefaultAssetPath(getBrandIconPath(catalogBrand));

/// Per-slug optical scale for Home feed brand chips.
///
/// Most brands use the default [BrandLogoGlyph] size (1.0). Listed slugs have
/// wide marks, heavy viewBox padding, or compact emblems that read too small
/// inside the square chip — a modest boost normalizes perceived size only.
const Map<String, double> kListingBrandFeedQuickFilterLogoOpticalScaleBySlug = {
  'abarth': 1.15,
  'acura': 1.20,
  'cadillac': 1.40,
  'datsun': 1.22,
  'ds-automobiles': 1.18,
  'genesis': 1.22,
  'jaecoo': 1.30,
  'lancia': 1.12,
  'land-rover': 1.46,
  'mini': 1.40,
  'moskvich': 1.26,
  'omoda': 1.28,
  'polestar': 1.12,
  'uaz': 1.24,
  'fiat': 1.28,
  'jaguar': 1.30,
  'hummer': 1.32,
  'isuzu': 1.30,
  'ram': 1.30,
  'haval': 1.30,
};

/// Optical size multiplier for feed quick-filter brand SVG logos (default 1.0).
double listingBrandFeedQuickFilterLogoScale(String catalogBrand) {
  final assetPath = getBrandIconPath(catalogBrand);
  if (isBrandIconDefaultAssetPath(assetPath)) return 1.0;

  final slug = brandIconSlugFromAssetPath(assetPath);
  if (slug == null) return 1.0;

  return kListingBrandFeedQuickFilterLogoOpticalScaleBySlug[slug] ?? 1.0;
}

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
    .replaceAll(RegExp(r'[-–—]'), '')
    .replaceAll('&', '');

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
