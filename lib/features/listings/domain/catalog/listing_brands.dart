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
