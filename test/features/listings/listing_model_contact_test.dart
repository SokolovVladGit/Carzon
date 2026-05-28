import 'package:carzon/features/listings/data/models/listing_model.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> baseJson() => <String, dynamic>{
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
  };

  group('ListingModel.fromJson — price_currency', () {
    test('defaults to EUR when column missing', () {
      final m = ListingModel.fromJson(baseJson());
      expect(m.priceCurrency, ListingCurrency.eur);
    });

    test('parses usd', () {
      final m = ListingModel.fromJson(baseJson()..['price_currency'] = 'usd');
      expect(m.priceCurrency, ListingCurrency.usd);
    });

    test('toJson includes price_currency', () {
      final m = ListingModel.fromJson(baseJson()..['price_currency'] = 'usd');
      expect(m.toJson()['price_currency'], 'usd');
    });
  });

  group('ListingModel.fromJson — contact fields', () {
    test('parses all three fields when present', () {
      final json = baseJson()
        ..addAll({
          'contact_phone': '+373 690 00001',
          'telegram_username': 'carzon_dev',
          'whatsapp_enabled': true,
        });
      final m = ListingModel.fromJson(json);
      expect(m.contactPhone, '+373 690 00001');
      expect(m.telegramUsername, 'carzon_dev');
      expect(m.whatsappEnabled, true);
    });

    test('defaults whatsappEnabled to false when missing', () {
      final m = ListingModel.fromJson(baseJson());
      expect(m.contactPhone, isNull);
      expect(m.telegramUsername, isNull);
      expect(m.whatsappEnabled, false);
    });

    test('parses whatsapp_enabled from 1 and string true', () {
      expect(
        ListingModel.fromJson(
          baseJson()..['whatsapp_enabled'] = 1,
        ).whatsappEnabled,
        true,
      );
      expect(
        ListingModel.fromJson(
          baseJson()..['whatsapp_enabled'] = 'true',
        ).whatsappEnabled,
        true,
      );
    });

    test('nulls round-trip cleanly', () {
      final json = baseJson()
        ..addAll({
          'contact_phone': null,
          'telegram_username': null,
          'whatsapp_enabled': false,
        });
      final m = ListingModel.fromJson(json);
      expect(m.contactPhone, isNull);
      expect(m.telegramUsername, isNull);
      expect(m.whatsappEnabled, false);
    });
  });
}
