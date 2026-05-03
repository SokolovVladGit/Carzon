import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _stub({
  num price = 8900,
  ListingCurrency currency = ListingCurrency.eur,
}) => Listing(
  id: 'i',
  title: 't',
  make: 'm',
  model: 'm',
  year: 2020,
  priceEur: price,
  priceCurrency: currency,
  mileageKm: 1,
  type: ListingType.sale,
  city: 'c',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  test('EUR integer matches legacy thousands style', () {
    expect(formatListingPrice(8900, ListingCurrency.eur), '€8 900');
    expect(formatEur(8900), '€8 900');
  });

  test('USD applies dollar prefix with same grouping', () {
    expect(formatListingPrice(12345, ListingCurrency.usd), '\$12 345');
  });

  test('decimals stay ungrouped fractional part', () {
    expect(formatListingPrice(10.5, ListingCurrency.eur), '€10.50');
    expect(formatListingPrice(10.5, ListingCurrency.usd), '\$10.50');
  });

  test('formatListingPriceFromListing reads listing fields', () {
    expect(
      formatListingPriceFromListing(_stub(currency: ListingCurrency.usd)),
      '\$8 900',
    );
  });
}
