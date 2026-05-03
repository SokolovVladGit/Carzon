import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';

EditListingInput _input({
  String listingId = 'l1',
  String title = 'VW Golf',
  String make = 'Volkswagen',
  String model = 'Golf',
  int year = 2016,
  num priceEur = 8900,
  int mileageKm = 120000,
  ListingType type = ListingType.sale,
  String city = 'Chișinău',
  MarketRegion marketRegion = MarketRegion.moldova,
  String contactPhone = '+373 690 00001',
  String? telegramUsername,
  bool whatsappEnabled = false,
  ListingCurrency priceCurrency = ListingCurrency.eur,
}) => EditListingInput(
  listingId: listingId,
  title: title,
  make: make,
  model: model,
  year: year,
  priceEur: priceEur,
  mileageKm: mileageKm,
  type: type,
  city: city,
  marketRegion: marketRegion,
  contactPhone: contactPhone,
  telegramUsername: telegramUsername,
  whatsappEnabled: whatsappEnabled,
  priceCurrency: priceCurrency,
);

void main() {
  group('EditListingInput', () {
    test('defaults priceCurrency to EUR', () {
      expect(_input().priceCurrency, ListingCurrency.eur);
    });

    test('differing priceCurrency breaks equality', () {
      expect(
        _input(priceCurrency: ListingCurrency.eur),
        isNot(_input(priceCurrency: ListingCurrency.usd)),
      );
    });

    test('equal instances with identical fields are equal', () {
      expect(_input(), _input());
    });

    test('differing listingId breaks equality', () {
      expect(_input(listingId: 'l1'), isNot(_input(listingId: 'l2')));
    });

    test('differing contact fields break equality', () {
      expect(
        _input(contactPhone: '+373 000 00001'),
        isNot(_input(contactPhone: '+373 000 99999')),
      );
      expect(
        _input(telegramUsername: 'alpha'),
        isNot(_input(telegramUsername: 'beta')),
      );
      expect(
        _input(whatsappEnabled: false),
        isNot(_input(whatsappEnabled: true)),
      );
    });

    test('differing market region breaks equality', () {
      expect(
        _input(marketRegion: MarketRegion.moldova),
        isNot(_input(marketRegion: MarketRegion.transnistria)),
      );
    });

    test('props cover every editable field', () {
      final a = _input();
      expect(a.props, contains(a.title));
      expect(a.props, contains(a.make));
      expect(a.props, contains(a.model));
      expect(a.props, contains(a.year));
      expect(a.props, contains(a.priceEur));
      expect(a.props, contains(a.priceCurrency));
      expect(a.props, contains(a.mileageKm));
      expect(a.props, contains(a.type));
      expect(a.props, contains(a.city));
      expect(a.props, contains(a.marketRegion));
      expect(a.props, contains(a.contactPhone));
      expect(a.props, contains(a.telegramUsername));
      expect(a.props, contains(a.whatsappEnabled));
      expect(a.props, contains(a.listingId));
    });
  });
}
