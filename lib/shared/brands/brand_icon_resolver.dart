/// Brand-icon resolver.
///
/// Maps free-text `make` values (user-entered, possibly Cyrillic, possibly
/// messy) to a deterministic SVG asset path under `assets/brands/svg/`.
///
/// The resolver is total: it never throws and always returns a valid,
/// renderable asset path. Unknown or empty inputs yield the neutral
/// fallback asset `assets/brands/svg/default.svg`.
library;

const String _assetDir = 'assets/brands/svg';
const String _defaultSlug = 'default';

/// Normalized alias -> canonical slug.
///
/// Keys MUST already be in normalized form (see [_normalize]): trimmed,
/// lowercased, single-spaced, no dots. Both Latin and Cyrillic spellings
/// are accepted for brands common in the RU-speaking market.
const Map<String, String> _aliases = {
  // BMW
  'bmw': 'bmw',
  'бмв': 'bmw',

  // Mercedes
  'mercedes': 'mercedes-benz',
  'mercedes benz': 'mercedes-benz',
  'mercedes-benz': 'mercedes-benz',
  'мерседес': 'mercedes-benz',

  // Audi
  'audi': 'audi',
  'ауди': 'audi',

  // Volkswagen
  'vw': 'volkswagen',
  'volkswagen': 'volkswagen',
  'фольксваген': 'volkswagen',

  // Toyota
  'toyota': 'toyota',
  'тойота': 'toyota',

  // Honda
  'honda': 'honda',
  'хонда': 'honda',

  // Hyundai
  'hyundai': 'hyundai',
  'хендай': 'hyundai',
  'хёндай': 'hyundai',

  // Kia
  'kia': 'kia',
  'киа': 'kia',

  // Ford
  'ford': 'ford',
  'форд': 'ford',

  // Chevrolet
  'chevrolet': 'chevrolet',
  'шевроле': 'chevrolet',

  // Nissan
  'nissan': 'nissan',
  'ниссан': 'nissan',

  // Mazda
  'mazda': 'mazda',
  'мазда': 'mazda',

  // Lexus
  'lexus': 'lexus',
  'лексус': 'lexus',

  // Subaru
  'subaru': 'subaru',
  'субару': 'subaru',

  // Mitsubishi
  'mitsubishi': 'mitsubishi',
  'мицубиси': 'mitsubishi',
  'мицубиши': 'mitsubishi',

  // Volvo
  'volvo': 'volvo',
  'вольво': 'volvo',

  // Renault
  'renault': 'renault',
  'рено': 'renault',

  // Peugeot
  'peugeot': 'peugeot',
  'пежо': 'peugeot',

  // Skoda
  'skoda': 'skoda',
  'škoda': 'skoda',
  'шкода': 'skoda',

  // Seat
  'seat': 'seat',

  // Opel
  'opel': 'opel',
  'опель': 'opel',

  // Porsche
  'porsche': 'porsche',
  'порше': 'porsche',

  // Tesla
  'tesla': 'tesla',
  'тесла': 'tesla',

  // Suzuki
  'suzuki': 'suzuki',
  'сузуки': 'suzuki',

  // Dacia
  'dacia': 'dacia',
  'дачия': 'dacia',

  // Citroen
  'citroen': 'citroen',
  'citroën': 'citroen',
  'ситроен': 'citroen',

  // Fiat
  'fiat': 'fiat',
  'фиат': 'fiat',

  // Alfa Romeo
  'alfa romeo': 'alfa-romeo',
  'alfa-romeo': 'alfa-romeo',
  'альфа ромео': 'alfa-romeo',

  // Land Rover
  'land rover': 'land-rover',
  'land-rover': 'land-rover',
  'ленд ровер': 'land-rover',

  // Jaguar
  'jaguar': 'jaguar',
  'ягуар': 'jaguar',

  // Mini
  'mini': 'mini',
  'мини': 'mini',

  // Jeep
  'jeep': 'jeep',
  'джип': 'jeep',

  // Cadillac
  'cadillac': 'cadillac',
  'кадиллак': 'cadillac',

  // Ferrari
  'ferrari': 'ferrari',
  'феррари': 'ferrari',

  // Lamborghini
  'lamborghini': 'lamborghini',
  'ламборгини': 'lamborghini',
  'ламборджини': 'lamborghini',

  // Bentley
  'bentley': 'bentley',
  'бентли': 'bentley',

  // Rolls-Royce
  'rolls royce': 'rolls-royce',
  'rolls-royce': 'rolls-royce',
  'роллс ройс': 'rolls-royce',
};

/// Returns the asset path of the brand SVG matching [make].
///
/// Total function: never throws, always returns a valid asset string.
/// Unknown input returns the neutral fallback asset.
///
/// Example:
/// ```dart
/// getBrandIconPath('BMW');          // assets/brands/svg/bmw.svg
/// getBrandIconPath('  мерседес ');  // assets/brands/svg/mercedes-benz.svg
/// getBrandIconPath('Unknown');      // assets/brands/svg/default.svg
/// getBrandIconPath(null);           // assets/brands/svg/default.svg
/// ```
String getBrandIconPath(String? make) {
  if (make == null) return _pathFor(_defaultSlug);

  final normalized = _normalize(make);
  if (normalized.isEmpty) return _pathFor(_defaultSlug);

  final slug = _aliases[normalized];
  return _pathFor(slug ?? _defaultSlug);
}

String _pathFor(String slug) => '$_assetDir/$slug.svg';

/// Suffix of the neutral fallback asset returned for unknown makes.
const String brandIconDefaultAssetSuffix = '/default.svg';

/// True when [assetPath] is the resolver's neutral fallback (not a brand SVG).
bool isBrandIconDefaultAssetPath(String assetPath) =>
    assetPath.endsWith(brandIconDefaultAssetSuffix);

/// Canonical slug from a resolver asset path (`assets/brands/svg/toyota.svg` → `toyota`).
String? brandIconSlugFromAssetPath(String assetPath) {
  final segment = assetPath.split('/').last;
  if (!segment.endsWith('.svg')) return null;
  return segment.substring(0, segment.length - 4);
}

/// Black/gray single-fill SVG marks that need a light tint on dark surfaces.
///
/// Multi-color / gradient marks (BMW, Mercedes, Ferrari, …) are excluded so
/// brand identity stays intact.
const Set<String> _monochromeBrandSlugs = {
  'honda',
  'infiniti',
  'jaguar',
  'jeep',
  'kia',
  'lexus',
  'mazda',
  'mitsubishi',
  'peugeot',
  'renault',
  'rolls-royce',
  'suzuki',
  'toyota',
  'volvo',
};

/// True when [assetPath] is a known monochrome brand SVG (not [default.svg]).
bool isBrandIconMonochromeAssetPath(String assetPath) {
  if (isBrandIconDefaultAssetPath(assetPath)) return false;
  final slug = brandIconSlugFromAssetPath(assetPath);
  return slug != null && _monochromeBrandSlugs.contains(slug);
}

/// Normalizes a free-text brand name for alias lookup.
///
/// Steps:
/// 1. trim outer whitespace
/// 2. lowercase
/// 3. replace `ё` with `е` (common Russian typing variance)
/// 4. strip dots (handles `B.M.W` -> `bmw`)
/// 5. collapse internal whitespace (tabs, multiple spaces) to one space
///
/// Other punctuation (e.g. hyphens, diacritics) is intentionally preserved
/// because it is meaningful in alias keys (`mercedes-benz`, `citroën`,
/// `škoda`). This keeps the resolver predictable: callers can reason about
/// what the lookup key will be.
String _normalize(String input) {
  var s = input.trim().toLowerCase();
  if (s.isEmpty) return s;

  s = s.replaceAll('ё', 'е').replaceAll('.', '');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}
