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
      expect(m.variant, isNull);
      expect(m.engineDisplacementLiters, isNull);
      expect(m.enginePowerHp, isNull);
      expect(m.drivetrain, isNull);
      expect(m.transmissionType, isNull);
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

    test('parses each transmission_type enum value and dual_clutch alias', () {
      const base = {
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
      };

      final cases = <String, ListingTransmissionType>{
        'manual': ListingTransmissionType.manual,
        'automatic': ListingTransmissionType.automatic,
        'cvt': ListingTransmissionType.cvt,
        'robotic': ListingTransmissionType.robotic,
        'dual_clutch': ListingTransmissionType.dualClutch,
        'other': ListingTransmissionType.other,
      };

      for (final entry in cases.entries) {
        final m = ListingModel.fromJson({
          ...base,
          'transmission_type': entry.key,
        });
        expect(m.transmissionType, entry.value, reason: entry.key);
      }
    });

    test(
      'toJson echoes transmission_type as dual_clutch for dualClutch enum',
      () {
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
          transmissionType: ListingTransmissionType.dualClutch,
          createdAt: DateTime.utc(2026),
          contactPhone: '+123',
        );

        final out = m.toJson();
        expect(out['transmission_type'], 'dual_clutch');
      },
    );

    test('parses variant and plug_in_hybrid fuel, never unknown-null', () {
      final m = ListingModel.fromJson({
        'id': 'a',
        'title': 't',
        'make': 'BMW',
        'model': '3 Series',
        'variant': '  M340i  ',
        'year': 2022,
        'price_eur': 1000,
        'price_currency': 'eur',
        'mileage_km': 10,
        'type': 'sale',
        'city': 'Chi',
        'market_region': 'moldova',
        'fuel_type': 'plug_in_hybrid',
        'created_at': '2026-03-01T12:00:00.000Z',
        'whatsapp_enabled': false,
      });
      expect(m.variant, 'M340i');
      expect(m.fuelType, ListingFuelType.plugInHybrid);
      expect(m.toJson()['fuel_type'], 'plug_in_hybrid');
      expect(m.toJson()['variant'], 'M340i');
    });

    test('legacy hybrid fuel still parses', () {
      final m = ListingModel.fromJson({
        'id': 'a',
        'title': 't',
        'make': 'Toyota',
        'model': 'RAV4',
        'year': 2022,
        'price_eur': 1000,
        'price_currency': 'eur',
        'mileage_km': 10,
        'type': 'sale',
        'city': 'Chi',
        'market_region': 'moldova',
        'fuel_type': 'hybrid',
        'created_at': '2026-03-01T12:00:00.000Z',
        'whatsapp_enabled': false,
      });
      expect(m.fuelType, ListingFuelType.hybrid);
    });
  });
}
