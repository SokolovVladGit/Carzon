/// Brand-icon resolver.
///
/// Maps free-text `make` values (user-entered, possibly Cyrillic, possibly
/// messy) to a deterministic SVG asset path under `assets/brands/svg/`.
///
/// The resolver is total: it never throws and always returns a valid,
/// renderable asset path. Unknown or empty inputs yield the neutral
/// fallback asset `assets/brands/svg/default.svg`.
library;

import 'package:meta/meta.dart';

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

  // Cupra
  'cupra': 'cupra',

  // Smart
  'smart': 'smart',
  'смарт': 'smart',

  // Chrysler
  'chrysler': 'chrysler',
  'крайслер': 'chrysler',

  // Dodge
  'dodge': 'dodge',
  'додж': 'dodge',

  // Infiniti
  'infiniti': 'infiniti',
  'инфинити': 'infiniti',

  // Acura
  'acura': 'acura',
  'акура': 'acura',

  // Lada
  'lada': 'lada',
  'лада': 'lada',

  // BYD
  'byd': 'byd',

  // Chery
  'chery': 'chery',
  'чери': 'chery',

  // Geely
  'geely': 'geely',
  'джили': 'geely',

  // Haval
  'haval': 'haval',
  'хавал': 'haval',

  // Great Wall
  'great wall': 'great-wall',
  'great-wall': 'great-wall',

  // MG
  'mg': 'mg',

  // Omoda
  'omoda': 'omoda',

  // Jaecoo
  'jaecoo': 'jaecoo',

  // Exeed
  'exeed': 'exeed',

  // Changan
  'changan': 'changan',

  // Dongfeng
  'dongfeng': 'dongfeng',

  // BAIC
  'baic': 'baic',

  // GAC
  'gac': 'gac',

  // FAW
  'faw': 'faw',

  // JAC
  'jac': 'jac',

  // Jetour
  'jetour': 'jetour',

  // Hongqi
  'hongqi': 'hongqi',

  // Tank
  'tank': 'tank',

  // Wey
  'wey': 'wey',

  // Lynk & Co
  'lynk co': 'lynk-co',
  'lynk & co': 'lynk-co',
  'lynk-co': 'lynk-co',

  // Zeekr
  'zeekr': 'zeekr',

  // NIO
  'nio': 'nio',

  // XPeng
  'xpeng': 'xpeng',

  // Leapmotor
  'leapmotor': 'leapmotor',

  // Li Auto
  'li auto': 'li-auto',
  'li-auto': 'li-auto',

  // DS Automobiles
  'ds automobiles': 'ds-automobiles',
  'ds-automobiles': 'ds-automobiles',

  // Genesis
  'genesis': 'genesis',
  'дженезис': 'genesis',

  // Polestar
  'polestar': 'polestar',

  // SsangYong
  'ssangyong': 'ssangyong',
  'ssang yong': 'ssangyong',

  // KGM
  'kgm': 'kgm',

  // Isuzu
  'isuzu': 'isuzu',
  'исузу': 'isuzu',

  // Daihatsu
  'daihatsu': 'daihatsu',

  // Daewoo
  'daewoo': 'daewoo',
  'дэу': 'daewoo',

  // Datsun
  'datsun': 'datsun',
  'датсун': 'datsun',

  // Abarth
  'abarth': 'abarth',

  // Lancia
  'lancia': 'lancia',

  // Ram
  'ram': 'ram',

  // GMC
  'gmc': 'gmc',

  // Lincoln
  'lincoln': 'lincoln',

  // Buick
  'buick': 'buick',

  // Hummer
  'hummer': 'hummer',

  // ORA
  'ora': 'ora',

  // Maxus
  'maxus': 'maxus',

  // Seres
  'seres': 'seres',

  // Voyah
  'voyah': 'voyah',

  // Aion
  'aion': 'aion',

  // Bestune
  'bestune': 'bestune',

  // DFSK
  'dfsk': 'dfsk',

  // Foton
  'foton': 'foton',

  // VinFast
  'vinfast': 'vinfast',

  // UAZ
  'uaz': 'uaz',
  'уаз': 'uaz',

  // Moskvich
  'moskvich': 'moskvich',
  'москвич': 'moskvich',

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

/// Bundled brand SVG slugs under `assets/brands/svg/`.
///
/// Aliases may resolve to slugs not yet packaged; those yield [default.svg]
/// until a logo is added manually.
///
/// **Manual logo add flow**
/// 1. Place `assets/brands/svg/{slug}.svg` (kebab-case slug from [_aliases]).
/// 2. Append `{slug}` to [kPackagedBrandIconSlugs] below.
/// 3. Run `brand_logo_glyph_test.dart` and `feed_brand_quick_filter_test.dart`.
///
/// Only list slugs whose SVG file exists in the repo; orphaned entries cause
/// missing-asset errors at runtime.
const Set<String> kPackagedBrandIconSlugs = {
  'abarth',
  'acura',
  'aion',
  'alfa-romeo',
  'audi',
  'baic',
  'bestune',
  'bmw',
  'buick',
  'byd',
  'cadillac',
  'changan',
  'chery',
  'chevrolet',
  'chrysler',
  'citroen',
  'cupra',
  'dacia',
  'daihatsu',
  'daewoo',
  'datsun',
  'dfsk',
  'dodge',
  'dongfeng',
  'ds-automobiles',
  'exeed',
  'faw',
  'fiat',
  'ford',
  'foton',
  'gac',
  'geely',
  'genesis',
  'gmc',
  'great-wall',
  'haval',
  'honda',
  'hongqi',
  'hummer',
  'hyundai',
  'infiniti',
  'isuzu',
  'jac',
  'jaecoo',
  'jaguar',
  'jeep',
  'jetour',
  'kgm',
  'kia',
  'lada',
  'lancia',
  'land-rover',
  'leapmotor',
  'lexus',
  'li-auto',
  'lincoln',
  'lynk-co',
  'mazda',
  'maxus',
  'mercedes-benz',
  'mg',
  'mini',
  'mitsubishi',
  'moskvich',
  'nio',
  'nissan',
  'omoda',
  'opel',
  'ora',
  'peugeot',
  'polestar',
  'porsche',
  'ram',
  'renault',
  'seat',
  'seres',
  'skoda',
  'smart',
  'ssangyong',
  'subaru',
  'suzuki',
  'tank',
  'tesla',
  'toyota',
  'uaz',
  'vinfast',
  'volkswagen',
  'volvo',
  'voyah',
  'wey',
  'xpeng',
  'zeekr',
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
  if (slug == null || !kPackagedBrandIconSlugs.contains(slug)) {
    return _pathFor(_defaultSlug);
  }
  return _pathFor(slug);
}

String _pathFor(String slug) => '$_assetDir/$slug.svg';

/// Packaged brand SVG path for [slug].
@visibleForTesting
String packagedBrandIconAssetPath(String slug) => _pathFor(slug);

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
/// Multi-color / gradient marks (BMW, Mercedes, Volvo, Ferrari, …) are excluded so
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
};

/// Simple emblem silhouettes safe for moderate metallic tint on discovery feed.
///
/// Wordmarks, ovals with script, multilayer marks (Ford, Nissan, Volvo, …) are
/// excluded so [ColorFilter.srcIn] does not flatten internal detail.
const Set<String> _discoveryFeedSimpleTintSlugs = {
  'honda',
  'infiniti',
  'jaguar',
  'jeep',
  'kia',
  'lexus',
  'mazda',
  'mitsubishi',
  'renault',
  'suzuki',
  'toyota',
};

/// True when [assetPath] is a known monochrome brand SVG (not [default.svg]).
bool isBrandIconMonochromeAssetPath(String assetPath) {
  if (isBrandIconDefaultAssetPath(assetPath)) return false;
  final slug = brandIconSlugFromAssetPath(assetPath);
  return slug != null && _monochromeBrandSlugs.contains(slug);
}

/// True when a discovery feed chip may use moderate metallic [ColorFilter.srcIn].
bool isBrandIconDiscoveryFeedSimpleTintAssetPath(String assetPath) {
  if (isBrandIconDefaultAssetPath(assetPath)) return false;
  final slug = brandIconSlugFromAssetPath(assetPath);
  return slug != null && _discoveryFeedSimpleTintSlugs.contains(slug);
}

/// True when a discovery feed chip should use a porcelain backplate (native SVG).
///
/// Default-on for dark feed chips except [isBrandIconDiscoveryFeedSimpleTintAssetPath]
/// marks, which stay flat with a restrained metallic tint.
bool isBrandIconDiscoveryFeedLightBackplateAssetPath(String assetPath) {
  if (isBrandIconDefaultAssetPath(assetPath)) return false;
  return !isBrandIconDiscoveryFeedSimpleTintAssetPath(assetPath);
}

/// Default inner glyph size inside the porcelain backplate (fraction of outer slot).
const double kBrandIconDiscoveryFeedBackplateInnerFractionDefault = 0.78;

/// Per-slug inner fraction overrides for porcelain backplate marks (dark feed only).
///
/// Boosts marks whose internal detail reads too small at chip/card sizes without
/// changing outer slot or plate diameter.
const Map<String, double> kBrandIconDiscoveryFeedBackplateInnerFractionBySlug = {
  'volvo': 0.90,
};

/// Inner glyph fraction for a porcelain backplate mark at [assetPath].
double brandIconDiscoveryFeedBackplateInnerFraction(String assetPath) {
  if (isBrandIconDefaultAssetPath(assetPath)) {
    return kBrandIconDiscoveryFeedBackplateInnerFractionDefault;
  }
  final slug = brandIconSlugFromAssetPath(assetPath);
  if (slug == null) return kBrandIconDiscoveryFeedBackplateInnerFractionDefault;
  return kBrandIconDiscoveryFeedBackplateInnerFractionBySlug[slug] ??
      kBrandIconDiscoveryFeedBackplateInnerFractionDefault;
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
