import 'package:carzon/features/listings/data/models/listing_model.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListingModel specs + description columns', () {
    test('parses nullable columns when absent', () {
      final m = ListingModel.fromJson({
        'id': 'a',
        'title': 't',
        'make': 'm',
        'model': 'x',
        'year': 2019,
        'price_eur': 1000,
        'price_currency': 'eur',
        'mileage_km': 10,
        'type': 'sale',
        'city': 'Chi',
        'market_region': 'moldova',
        'created_at': '2026-03-01T12:00:00.000Z',
        'whatsapp_enabled': false,
      });

      expect(m.fuelType, isNull);
      expect(m.engineDisplacementLiters, isNull);
      expect(m.enginePowerHp, isNull);
      expect(m.drivetrain, isNull);
      expect(m.registration, isNull);
      expect(m.description, isNull);
    });

    test('parses full spec payload including four_wheel DB value', () {
      final m = ListingModel.fromJson({
        'id': 'a',
        'title': 't',
        'make': 'm',
        'model': 'x',
        'year': 2019,
        'price_eur': 1000,
        'price_currency': 'eur',
        'mileage_km': 10,
        'type': 'sale',
        'city': 'Chi',
        'market_region': 'moldova',
        'fuel_type': 'diesel',
        'engine_displacement_liters': 2.5,
        'engine_power_hp': 150,
        'drivetrain': 'four_wheel',
        'registration': ' MD ',
        'description': '  Good car  ',
        'created_at': '2026-03-01T12:00:00.000Z',
        'whatsapp_enabled': false,
      });

      expect(m.fuelType, ListingFuelType.diesel);
      expect(m.engineDisplacementLiters, 2.5);
      expect(m.enginePowerHp, 150);
      expect(m.drivetrain, ListingDrivetrain.fourWheel);
      expect(m.registration, 'MD');
      expect(m.description, 'Good car');
    });

    test('toJson echoes drivetrain as four_wheel for fourWheel enum', () {
      final m = ListingModel(
        id: 'a',
        title: 't',
        make: 'm',
        model: 'x',
        year: 2019,
        priceEur: 1,
        mileageKm: 1,
        type: ListingType.sale,
        city: 'c',
        marketRegion: MarketRegion.moldova,
        drivetrain: ListingDrivetrain.fourWheel,
        createdAt: DateTime.utc(2026),
        contactPhone: '+123',
      );

      final out = m.toJson();
      expect(out['drivetrain'], 'four_wheel');
    });
  });
}
