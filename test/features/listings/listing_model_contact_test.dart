import 'package:carzon/features/listings/data/models/listing_model.dart';
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
