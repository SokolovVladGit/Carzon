import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/listing_share_text.dart';
import 'package:carzon/features/listings/presentation/utils/listing_share_url.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

Listing _listing({
  String id = 'listing-007',
  String title = 'Skoda Octavia 1.8 TSI',
  String make = 'Skoda',
  String model = 'Octavia',
  int year = 2017,
  String city = 'Tiraspol',
  MarketRegion region = MarketRegion.transnistria,
  String? contactPhone = '+373 000 000 001',
  String? telegramUsername = 'carzon_demo_01',
  String? sellerId = 'seller-secret-99',
  ListingVinStatus vinStatus = ListingVinStatus.formatValid,
}) => Listing(
  id: id,
  title: title,
  make: make,
  model: model,
  year: year,
  priceEur: 10800,
  mileageKm: 132000,
  type: ListingType.sale,
  city: city,
  marketRegion: region,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: sellerId,
  contactPhone: contactPhone,
  telegramUsername: telegramUsername,
  whatsappEnabled: true,
  vinStatus: vinStatus,
);

void main() {
  group('buildListingShareText', () {
    test('includes localized intro and public title', () {
      final l10n = ruStrings();
      final text = buildListingShareText(l10n, _listing());

      expect(text, contains(l10n.listingShareIntro));
      expect(text, contains('Skoda Octavia 1.8 TSI'));
    });

    test('includes formatted price and city/region', () {
      final l10n = ruStrings();
      final text = buildListingShareText(l10n, _listing());

      expect(text, contains('€10 800'));
      expect(text, contains('Tiraspol'));
      expect(text, contains(l10n.regionTransnistria));
    });

    test('includes URL line when shareUrl is provided', () {
      final l10n = ruStrings();
      const url = 'https://carzon.example/listings/listing-007';
      final text = buildListingShareText(l10n, _listing(), shareUrl: url);

      expect(text, contains(url));
      expect(
        text,
        isNot(contains(l10n.listingShareFallbackLine('listing-007'))),
      );
    });

    test('uses in-app fallback when shareUrl is null', () {
      final l10n = ruStrings();
      final text = buildListingShareText(l10n, _listing());

      expect(text, contains(l10n.listingShareOpenInCarzon));
      expect(text, contains(l10n.listingShareFallbackLine('listing-007')));
      expect(text, isNot(contains('https://')));
    });

    test('trims cleanly without double blank lines', () {
      final l10n = ruStrings();
      final text = buildListingShareText(
        l10n,
        _listing(city: '', title: '  '),
        shareUrl: 'https://carzon.example/listings/listing-007',
      );

      expect(text, isNot(contains('\n\n\n')));
      expect(text.trim(), text);
      expect(text.split('\n').every((line) => line.trim().isNotEmpty), isTrue);
    });

    test('excludes seller contact, seller id, and VIN-related fields', () {
      final l10n = ruStrings();
      final text = buildListingShareText(l10n, _listing());

      expect(text, isNot(contains('+373')));
      expect(text, isNot(contains('carzon_demo_01')));
      expect(text, isNot(contains('seller-secret-99')));
      expect(text, isNot(contains('vin')));
      expect(text, isNot(contains('VIN')));
    });

    test('RO smoke: localized intro and fallback', () {
      final l10n = roStrings();
      final text = buildListingShareText(l10n, _listing());

      expect(text, contains(l10n.listingShareIntro));
      expect(text, contains(l10n.listingShareFallbackLine('listing-007')));
    });
  });

  group('buildListingShareUrl', () {
    test('builds normalized listing URL from base', () {
      const listingId = 'c476a9b2-9c42-4cee-b0f1-f95923dcce01';
      expect(
        buildListingShareUrl('https://carzon.md/', listingId),
        'https://carzon.md/listings/$listingId',
      );
    });

    test('returns null for invalid base URL', () {
      expect(buildListingShareUrl('not-a-url', 'listing-007'), isNull);
      expect(buildListingShareUrl('', 'listing-007'), isNull);
    });
  });
}
