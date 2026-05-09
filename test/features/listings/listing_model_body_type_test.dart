import 'package:carzon/features/listings/data/models/listing_model.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
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

  group('ListingModel.fromJson — body_type', () {
    test('null/missing is allowed', () {
      final m = ListingModel.fromJson(baseJson());
      expect(m.bodyType, isNull);
    });

    test('parses valid allowed values', () {
      for (final t in ListingBodyType.values) {
        final m = ListingModel.fromJson(baseJson()..['body_type'] = t.name);
        expect(m.bodyType, t);
      }
    });

    test('normalizes body_type casing from database text', () {
      final m = ListingModel.fromJson(baseJson()..['body_type'] = 'SUV');
      expect(m.bodyType, ListingBodyType.suv);
    });

    test('unknown non-null body_type maps to null (feed-safe)', () {
      final m = ListingModel.fromJson(baseJson()..['body_type'] = 'limousine');
      expect(m.bodyType, isNull);
    });

    test('toJson uses null body_type when unspecified', () {
      final m = ListingModel.fromJson(baseJson());
      expect(m.toJson()['body_type'], isNull);
    });

    test('toJson includes body_type when set', () {
      final m = ListingModel.fromJson(baseJson()..['body_type'] = 'suv');
      expect(m.toJson()['body_type'], 'suv');
    });
  });
}
