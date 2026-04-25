import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NewListingInput base({
    String? coverImageUrl,
    String contactPhone = '+373 690 00001',
    String? telegramUsername,
    bool whatsappEnabled = false,
  }) =>
      NewListingInput(
        sellerId: 's1',
        title: 't',
        make: 'BMW',
        model: '320',
        year: 2019,
        priceEur: 18750,
        mileageKm: 95000,
        type: ListingType.sale,
        city: 'Tiraspol',
        marketRegion: MarketRegion.transnistria,
        coverImageUrl: coverImageUrl,
        contactPhone: contactPhone,
        telegramUsername: telegramUsername,
        whatsappEnabled: whatsappEnabled,
      );

  group('NewListingInput', () {
    test('equality considers coverImageUrl', () {
      expect(base(), equals(base()));
      expect(base(coverImageUrl: 'https://example.com/a.jpg'),
          isNot(equals(base())));
      expect(
        base(coverImageUrl: 'https://example.com/a.jpg'),
        equals(base(coverImageUrl: 'https://example.com/a.jpg')),
      );
    });

    test('equality considers contact fields', () {
      expect(
        base(telegramUsername: 'carzon_dev'),
        isNot(equals(base())),
      );
      expect(
        base(whatsappEnabled: true),
        isNot(equals(base())),
      );
      expect(
        base(contactPhone: '+373 777 00000'),
        isNot(equals(base())),
      );
      expect(
        base(telegramUsername: 'u', whatsappEnabled: true),
        equals(base(telegramUsername: 'u', whatsappEnabled: true)),
      );
    });

    test('copyWith sets coverImageUrl', () {
      final withCover = base().copyWith(coverImageUrl: 'u');
      expect(withCover.coverImageUrl, 'u');
      expect(withCover.sellerId, 's1');
      expect(withCover.title, 't');
      expect(withCover.contactPhone, '+373 690 00001');
    });

    test('copyWith sets contact fields', () {
      final updated = base().copyWith(
        contactPhone: '+373 777 11111',
        telegramUsername: 'new_user',
        whatsappEnabled: true,
      );
      expect(updated.contactPhone, '+373 777 11111');
      expect(updated.telegramUsername, 'new_user');
      expect(updated.whatsappEnabled, true);
    });
  });
}
