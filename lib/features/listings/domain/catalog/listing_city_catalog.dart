import '../entities/listing.dart';

/// One approved marketplace locality.
///
/// [canonicalValue] is both the picker label and the persisted `listings.city`
/// value. [aliases] are accepted only for search and historical hydration.
class ListingCityCatalogEntry {
  const ListingCityCatalogEntry({
    required this.canonicalValue,
    required this.region,
    this.aliases = const [],
  });

  final String canonicalValue;
  final MarketRegion region;
  final List<String> aliases;
}

const List<ListingCityCatalogEntry> _moldovaCities = [
  ListingCityCatalogEntry(
    canonicalValue: 'Chișinău',
    region: MarketRegion.moldova,
    aliases: ['Chisinau', 'Chişinău', 'Кишинёв', 'Кишинев'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Bălți',
    region: MarketRegion.moldova,
    aliases: ['Balti', 'Bălţi', 'Бельцы'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Ungheni',
    region: MarketRegion.moldova,
    aliases: ['Унгены'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Orhei',
    region: MarketRegion.moldova,
    aliases: ['Оргеев'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Cahul',
    region: MarketRegion.moldova,
    aliases: ['Кагул'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Soroca',
    region: MarketRegion.moldova,
    aliases: ['Сороки'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Comrat',
    region: MarketRegion.moldova,
    aliases: ['Комрат'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Edineț',
    region: MarketRegion.moldova,
    aliases: ['Edinet', 'Edineţ', 'Единцы'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Hîncești',
    region: MarketRegion.moldova,
    aliases: ['Hincesti', 'Hînceşti', 'Хынчешты'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Căușeni',
    region: MarketRegion.moldova,
    aliases: ['Causeni', 'Căuşeni', 'Каушаны'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Strășeni',
    region: MarketRegion.moldova,
    aliases: ['Straseni', 'Străşeni', 'Страшены'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Ceadîr-Lunga',
    region: MarketRegion.moldova,
    aliases: ['Ceadir-Lunga', 'Ceadâr-Lunga', 'Чадыр-Лунга'],
  ),
];

const List<ListingCityCatalogEntry> _transnistriaCities = [
  ListingCityCatalogEntry(
    canonicalValue: 'Тирасполь',
    region: MarketRegion.transnistria,
    aliases: ['Tiraspol'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Бендеры',
    region: MarketRegion.transnistria,
    aliases: ['Bender', 'Benderi', 'Tighina'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Рыбница',
    region: MarketRegion.transnistria,
    aliases: ['Ribnita', 'Rîbnița', 'Rybnitsa'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Дубоссары',
    region: MarketRegion.transnistria,
    aliases: ['Dubasari', 'Dubăsari'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Слободзея',
    region: MarketRegion.transnistria,
    aliases: ['Slobozia'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Григориополь',
    region: MarketRegion.transnistria,
    aliases: ['Grigoriopol'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Каменка',
    region: MarketRegion.transnistria,
    aliases: ['Camenca', 'Kamenka'],
  ),
  ListingCityCatalogEntry(
    canonicalValue: 'Днестровск',
    region: MarketRegion.transnistria,
    aliases: ['Dnestrovsc', 'Dnestrovsk'],
  ),
];

/// Approved entries in product order. Returned lists are immutable constants.
List<ListingCityCatalogEntry> listingCitiesForRegion(MarketRegion region) {
  return switch (region) {
    MarketRegion.moldova => _moldovaCities,
    MarketRegion.transnistria => _transnistriaCities,
  };
}

/// Deterministic comparison form for catalog lookup and search.
String normalizeListingCityText(String raw) {
  var value = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  const replacements = <String, String>{
    'ă': 'a',
    'â': 'a',
    'î': 'i',
    'ș': 's',
    'ş': 's',
    'ț': 't',
    'ţ': 't',
    'ё': 'е',
    '–': '-',
    '—': '-',
  };
  for (final replacement in replacements.entries) {
    value = value.replaceAll(replacement.key, replacement.value);
  }
  return value;
}

Iterable<String> _entrySearchValues(ListingCityCatalogEntry entry) sync* {
  yield entry.canonicalValue;
  yield* entry.aliases;
}

/// Resolves a canonical or historical value within one region.
ListingCityCatalogEntry? resolveListingCity(MarketRegion region, String raw) {
  final normalized = normalizeListingCityText(raw);
  if (normalized.isEmpty) return null;
  for (final entry in listingCitiesForRegion(region)) {
    if (_entrySearchValues(
      entry,
    ).any((value) => normalizeListingCityText(value) == normalized)) {
      return entry;
    }
  }
  return null;
}

/// Filters canonical values and aliases while preserving catalog order.
List<ListingCityCatalogEntry> searchListingCities(
  MarketRegion region,
  String query,
) {
  final normalized = normalizeListingCityText(query);
  final cities = listingCitiesForRegion(region);
  if (normalized.isEmpty) return cities;
  return List.unmodifiable(
    cities.where(
      (entry) => _entrySearchValues(
        entry,
      ).any((value) => normalizeListingCityText(value).contains(normalized)),
    ),
  );
}
