import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listingCurrencyFromDbString', () {
    test('maps eur/usd variants', () {
      expect(listingCurrencyFromDbString('eur'), ListingCurrency.eur);
      expect(listingCurrencyFromDbString('EUR'), ListingCurrency.eur);
      expect(listingCurrencyFromDbString('usd'), ListingCurrency.usd);
      expect(listingCurrencyFromDbString('USD'), ListingCurrency.usd);
    });

    test('defaults to EUR when null/empty/unknown', () {
      expect(listingCurrencyFromDbString(null), ListingCurrency.eur);
      expect(listingCurrencyFromDbString(''), ListingCurrency.eur);
      expect(listingCurrencyFromDbString('  '), ListingCurrency.eur);
      expect(listingCurrencyFromDbString('sek'), ListingCurrency.eur);
    });
  });

  group('listingCurrencyToDbString', () {
    test('uses enum names', () {
      expect(listingCurrencyToDbString(ListingCurrency.eur), 'eur');
      expect(listingCurrencyToDbString(ListingCurrency.usd), 'usd');
    });
  });

  test('Listing.priceAmount mirrors priceEur', () {
    final listing = Listing(
      id: 'i',
      title: 't',
      make: 'm',
      model: 'm',
      year: 2020,
      priceEur: 42,
      mileageKm: 1,
      type: ListingType.sale,
      city: 'c',
      marketRegion: MarketRegion.moldova,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    expect(listing.priceAmount, listing.priceEur);
  });
}
