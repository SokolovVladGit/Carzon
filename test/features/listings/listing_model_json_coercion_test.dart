import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/features/listings/data/models/listing_model.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hardening against PostgREST / hosted row shapes (numeric strings, bool
/// coercion, optional enum drop).
void main() {
  Map<String, dynamic> baseJson() => <String, dynamic>{
    'id': '11111111-1111-1111-1111-111111111111',
    'title': 'Test',
    'make': 'Make',
    'model': 'Model',
    'year': 2019,
    'price_eur': 10000,
    'mileage_km': 50000,
    'type': 'sale',
    'city': 'Tiraspol',
    'market_region': 'transnistria',
    'created_at': '2026-01-01T00:00:00.000Z',
    'status': 'active',
  };

  group('ListingModel.fromJson coercion', () {
    test('parses year, mileage, price_eur from numeric strings', () {
      final m = ListingModel.fromJson(
        baseJson()
          ..['year'] = '2018'
          ..['mileage_km'] = '49000'
          ..['price_eur'] = '8500.50',
      );
      expect(m.year, 2018);
      expect(m.mileageKm, 49000);
      expect(m.priceEur, 8500.50);
    });

    test('parses engine fields from strings', () {
      final m = ListingModel.fromJson(
        baseJson()
          ..['engine_displacement_liters'] = '1.9'
          ..['engine_power_hp'] = '110',
      );
      expect(m.engineDisplacementLiters, closeTo(1.9, 0.001));
      expect(m.enginePowerHp, 110);
    });

    test('parses whatsapp_enabled from int and string truthy/falsey', () {
      final t = ListingModel.fromJson(baseJson()..['whatsapp_enabled'] = 1);
      expect(t.whatsappEnabled, true);

      final t2 = ListingModel.fromJson(
        baseJson()..['whatsapp_enabled'] = 'TRUE',
      );
      expect(t2.whatsappEnabled, true);

      final f = ListingModel.fromJson(baseJson()..['whatsapp_enabled'] = 0);
      expect(f.whatsappEnabled, false);

      final f2 = ListingModel.fromJson(
        baseJson()..['whatsapp_enabled'] = 'false',
      );
      expect(f2.whatsappEnabled, false);
    });

    test('uppercase type and status normalize', () {
      final m = ListingModel.fromJson(
        baseJson()
          ..['type'] = 'BOTH'
          ..['status'] = 'ACTIVE',
      );
      expect(m.type, ListingType.both);
      expect(m.status, ListingStatus.active);
    });

    test('coerces id via toString when wire value is not a String', () {
      final m = ListingModel.fromJson(baseJson()..['id'] = 999);
      expect(m.id, '999');
    });

    test('missing or empty market_region throws ServerException', () {
      expect(
        () => ListingModel.fromJson(baseJson()..remove('market_region')),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => ListingModel.fromJson(baseJson()..['market_region'] = '   '),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => ListingModel.fromJson(baseJson()..['market_region'] = 'antarctica'),
        throwsA(isA<ServerException>()),
      );
    });

    test('unknown fuel_type maps to null', () {
      final m = ListingModel.fromJson(
        baseJson()..['fuel_type'] = 'unobtanium',
      );
      expect(m.fuelType, isNull);
    });

    test('missing vin_status maps to notProvided', () {
      final m = ListingModel.fromJson(Map<String, dynamic>.from(baseJson()));
      expect(m.vinStatus, ListingVinStatus.notProvided);
    });

    test('null vin_status maps to notProvided', () {
      final m = ListingModel.fromJson(baseJson()..['vin_status'] = null);
      expect(m.vinStatus, ListingVinStatus.notProvided);
    });

    test('format_valid vin_status parses', () {
      final m = ListingModel.fromJson(
        baseJson()..['vin_status'] = 'format_valid',
      );
      expect(m.vinStatus, ListingVinStatus.formatValid);
    });
  });
}
