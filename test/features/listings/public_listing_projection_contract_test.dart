import 'dart:io';

import 'package:carzon/features/listings/data/models/listing_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('public listing projection contract', () {
    test('public DTO ignores contact fields from stale payloads', () {
      final listing = ListingModel.fromPublicJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'title': 'BMW 320d',
        'make': 'BMW',
        'model': '320',
        'year': 2019,
        'price_eur': 18750,
        'mileage_km': 95000,
        'type': 'sale',
        'city': 'Chișinău',
        'market_region': 'moldova',
        'created_at': '2026-01-01T00:00:00Z',
        'status': 'active',
        'seller_id': 'seller-1',
        'contact_phone': '+373 690 00001',
        'telegram_username': 'carzon_dev',
        'whatsapp_enabled': true,
      });

      expect(listing.sellerId, 'seller-1');
      expect(listing.contactPhone, isNull);
      expect(listing.telegramUsername, isNull);
      expect(listing.whatsappEnabled, false);
    });

    test('public listing datasource uses explicit listing/image projections', () {
      final sql = File(
        'lib/features/listings/data/datasources/listings_remote_datasource.dart',
      ).readAsStringSync();

      expect(sql, contains('select(_publicListingColumns)'));
      expect(sql, contains('select(_publicListingImageColumns)'));
      expect(sql, isNot(contains('.select()')));
      expect(sql, isNot(contains('storage_path')));
      expect(sql, contains('get_listing_public_contact'));
    });
  });
}
