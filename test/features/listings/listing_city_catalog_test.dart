import 'package:carzon/features/listings/domain/catalog/listing_city_catalog.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const moldova = [
    'Chișinău',
    'Bălți',
    'Ungheni',
    'Orhei',
    'Cahul',
    'Soroca',
    'Comrat',
    'Edineț',
    'Hîncești',
    'Căușeni',
    'Strășeni',
    'Ceadîr-Lunga',
  ];
  const transnistria = [
    'Тирасполь',
    'Бендеры',
    'Рыбница',
    'Дубоссары',
    'Слободзея',
    'Григориополь',
    'Каменка',
    'Днестровск',
  ];

  test('canonical lists and ordering exactly match the approved catalog', () {
    expect(
      listingCitiesForRegion(
        MarketRegion.moldova,
      ).map((entry) => entry.canonicalValue),
      moldova,
    );
    expect(
      listingCitiesForRegion(
        MarketRegion.transnistria,
      ).map((entry) => entry.canonicalValue),
      transnistria,
    );
  });

  test('canonical and aliases resolve case/space/diacritics safely', () {
    expect(
      resolveListingCity(MarketRegion.moldova, 'Bălți')?.canonicalValue,
      'Bălți',
    );
    expect(
      resolveListingCity(MarketRegion.moldova, '  CHIŞINĂU  ')?.canonicalValue,
      'Chișinău',
    );
    expect(
      resolveListingCity(MarketRegion.moldova, 'hincesti')?.canonicalValue,
      'Hîncești',
    );
    expect(
      resolveListingCity(MarketRegion.moldova, 'Кишинёв')?.canonicalValue,
      'Chișinău',
    );
    expect(
      resolveListingCity(
        MarketRegion.transnistria,
        '  ribnita  ',
      )?.canonicalValue,
      'Рыбница',
    );
  });

  test('lookup never crosses the selected region', () {
    expect(resolveListingCity(MarketRegion.moldova, 'Tiraspol'), isNull);
    expect(resolveListingCity(MarketRegion.transnistria, 'Chisinau'), isNull);
  });

  test('search matches canonical values and aliases in catalog order', () {
    expect(
      searchListingCities(
        MarketRegion.moldova,
        'stras',
      ).map((entry) => entry.canonicalValue),
      ['Strășeni'],
    );
    expect(
      searchListingCities(
        MarketRegion.transnistria,
        'Dnestrov',
      ).map((entry) => entry.canonicalValue),
      ['Днестровск'],
    );
    expect(
      searchListingCities(
        MarketRegion.moldova,
        '',
      ).map((entry) => entry.canonicalValue),
      moldova,
    );
  });

  test('returned catalogs are immutable', () {
    expect(
      () => listingCitiesForRegion(
        MarketRegion.moldova,
      ).add(listingCitiesForRegion(MarketRegion.moldova).first),
      throwsUnsupportedError,
    );
  });
}
