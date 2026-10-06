import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/presentation/models/vin_resolved_form_prefill.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('vinResolvedBodyType', () {
    test('maps a conservative whitelist only', () {
      expect(vinResolvedBodyType('Pickup'), ListingBodyType.pickup);
      expect(vinResolvedBodyType('pick-up'), ListingBodyType.pickup);
      expect(vinResolvedBodyType('Sedan'), ListingBodyType.sedan);
      expect(vinResolvedBodyType('Saloon'), ListingBodyType.sedan);
      expect(vinResolvedBodyType('SUV'), ListingBodyType.suv);
      expect(vinResolvedBodyType('Sport Utility Vehicle'), ListingBodyType.suv);
      expect(
        vinResolvedBodyType(
          'Sport Utility Vehicle (SUV)/Multi-Purpose Vehicle (MPV)',
        ),
        ListingBodyType.suv,
      );
      expect(vinResolvedBodyType('Wagon'), ListingBodyType.wagon);
      expect(vinResolvedBodyType('Hatchback'), ListingBodyType.hatchback);
      expect(
        vinResolvedBodyType('Hatchback/Liftback/Notchback'),
        ListingBodyType.hatchback,
      );
      expect(vinResolvedBodyType('Coupe'), ListingBodyType.coupe);
      expect(
        vinResolvedBodyType('Convertible/Cabriolet'),
        ListingBodyType.convertible,
      );
      expect(vinResolvedBodyType('Minivan'), ListingBodyType.minivan);
      expect(vinResolvedBodyType('Van'), ListingBodyType.van);
      expect(vinResolvedBodyType('Cargo Van'), ListingBodyType.van);
      expect(vinResolvedBodyType('Truck'), isNull);
      expect(vinResolvedBodyType('Incomplete Vehicle'), isNull);
      expect(vinResolvedBodyType('Crossover'), isNull);
      expect(vinResolvedBodyType('Pickup Truck'), isNull);
      expect(
        vinResolvedBodyType('Crossover Utility Vehicle (CUV)'),
        isNull,
      );
      expect(vinResolvedBodyType('other'), isNull);
      expect(vinResolvedBodyType(null), isNull);
    });
  });

  group('vinResolvedFuelType', () {
    test('maps only unambiguous single fuels', () {
      expect(vinResolvedFuelType('Gasoline'), ListingFuelType.petrol);
      expect(vinResolvedFuelType('Petrol'), ListingFuelType.petrol);
      expect(vinResolvedFuelType('Diesel'), ListingFuelType.diesel);
      expect(vinResolvedFuelType('Electric'), ListingFuelType.electric);
      expect(
        vinResolvedFuelType(
          'Gasoline',
          electrification: 'PHEV (Plug-in Hybrid Electric Vehicle)',
        ),
        ListingFuelType.plugInHybrid,
      );
      expect(
        vinResolvedFuelType(
          'Gasoline',
          electrification: 'HEV (Hybrid Electric Vehicle) - Level Unknown',
        ),
        ListingFuelType.hybrid,
      );
      expect(
        vinResolvedFuelType(
          'Electric',
          electrification: 'BEV (Battery Electric Vehicle)',
        ),
        ListingFuelType.electric,
      );
      expect(
        vinResolvedFuelType(
          null,
          electrification: 'Strong HEV (Hybrid Electric Vehicle)',
        ),
        ListingFuelType.hybrid,
      );
      expect(vinResolvedFuelType('LPG'), ListingFuelType.lpg);
      expect(
        vinResolvedFuelType('Compressed Natural Gas (CNG)'),
        ListingFuelType.cng,
      );
      expect(vinResolvedFuelType('Hybrid'), isNull);
      expect(vinResolvedFuelType('Plug-in Hybrid'), isNull);
      expect(vinResolvedFuelType('Flex Fuel'), isNull);
      expect(vinResolvedFuelType('Gasoline/E-85'), isNull);
      expect(
        vinResolvedFuelType(
          'Gasoline',
          secondary: 'Electric',
          electrification: 'PHEV (Plug-in Hybrid Electric Vehicle)',
        ),
        isNull,
      );
      expect(
        vinResolvedFuelType(
          'Electric',
          electrification: 'HEV (Hybrid Electric Vehicle) - Level Unknown',
        ),
        isNull,
      );
      expect(
        vinResolvedFuelType(
          'Gasoline',
          electrification: 'FCEV (Fuel Cell Electric Vehicle)',
        ),
        isNull,
      );
      expect(vinResolvedFuelType('unknown'), isNull);
    });
  });

  group('vinResolvedTransmissionType', () {
    test('maps automatic, manual, and exact CVT only', () {
      expect(
        vinResolvedTransmissionType('Automatic'),
        ListingTransmissionType.automatic,
      );
      expect(
        vinResolvedTransmissionType('Automatic (8)'),
        ListingTransmissionType.automatic,
      );
      expect(
        vinResolvedTransmissionType('Manual'),
        ListingTransmissionType.manual,
      );
      expect(vinResolvedTransmissionType('CVT'), ListingTransmissionType.cvt);
      expect(vinResolvedTransmissionType('DCT'), isNull);
      expect(vinResolvedTransmissionType('Dual Clutch'), isNull);
      expect(vinResolvedTransmissionType('Automated Manual'), isNull);
      expect(vinResolvedTransmissionType('Robotic'), isNull);
      expect(vinResolvedTransmissionType('unknown'), isNull);
    });
  });

  group('vinResolvedDrivetrain', () {
    test('keeps AWD and 4WD distinct and rejects 4x2', () {
      expect(vinResolvedDrivetrain('AWD'), ListingDrivetrain.awd);
      expect(vinResolvedDrivetrain('All-Wheel Drive'), ListingDrivetrain.awd);
      expect(vinResolvedDrivetrain('4WD'), ListingDrivetrain.fourWheel);
      expect(vinResolvedDrivetrain('4x4'), ListingDrivetrain.fourWheel);
      expect(
        vinResolvedDrivetrain('4WD/4-Wheel Drive/4x4'),
        ListingDrivetrain.fourWheel,
      );
      expect(vinResolvedDrivetrain('FWD'), ListingDrivetrain.fwd);
      expect(vinResolvedDrivetrain('RWD'), ListingDrivetrain.rwd);
      expect(vinResolvedDrivetrain('4x2'), isNull);
      expect(vinResolvedDrivetrain('2WD'), isNull);
      expect(vinResolvedDrivetrain('4WD/AWD'), isNull);
      expect(vinResolvedDrivetrain('unknown'), isNull);
    });
  });

  group('vinResolvedDisplacementLiters', () {
    test('parses liters inside the existing form bounds', () {
      expect(vinResolvedDisplacementLiters('6.2 L'), 6.2);
      expect(vinResolvedDisplacementLiters('2.0 L'), 2.0);
      expect(vinResolvedDisplacementLiters('0'), isNull);
      expect(vinResolvedDisplacementLiters('0 L'), isNull);
      expect(vinResolvedDisplacementLiters('30.1 L'), isNull);
      expect(vinResolvedDisplacementLiters('31'), isNull);
      expect(vinResolvedDisplacementLiters('abc'), isNull);
      expect(vinResolvedDisplacementLiters(''), isNull);
      expect(vinResolvedDisplacementLiters(null), isNull);
    });
  });

  group('vinResolvedFormPrefill', () {
    const ram = VehicleResolveSuggestion(
      make: 'Ram',
      model: '1500',
      year: 2021,
      bodyType: 'Pickup',
      fuelType: 'Gasoline',
      transmission: 'Automatic',
      driveType: '4WD/4-Wheel Drive/4x4',
      displacement: '6.2 L',
    );

    test('maps a safe resolved suggestion', () {
      final prefill = vinResolvedFormPrefill(ram);
      expect(prefill.bodyType, ListingBodyType.pickup);
      expect(prefill.fuelType, ListingFuelType.petrol);
      expect(prefill.transmissionType, ListingTransmissionType.automatic);
      expect(prefill.drivetrain, ListingDrivetrain.fourWheel);
      expect(prefill.engineDisplacementLiters, 6.2);
      expect(prefill.engineCylinders, isNull);
      expect(prefill.doors, isNull);
      expect(prefill.seats, isNull);
      expect(formatVinDisplacementField(6.2), '6.2');
    });

    test('skips persist when catalog decode caution is present', () {
      final prefill = vinResolvedFormPrefill(
        ram,
        warnings: const ['nhtsa_catalog_decode_caution'],
      );
      expect(prefill.isEmpty, isTrue);
    });

    test('unknown provider values stay empty without throwing', () {
      final prefill = vinResolvedFormPrefill(
        const VehicleResolveSuggestion(
          make: 'Honda',
          model: 'Civic',
          year: 2019,
          bodyType: 'Incomplete - Cutaway',
          fuelType: 'Flexible Fuel',
          transmission: 'Automated Manual',
          driveType: '4x2',
          displacement: 'huge',
        ),
      );
      expect(prefill.isEmpty, isTrue);
    });

    test('maps explicit cylinder, door, and seat counts', () {
      final prefill = vinResolvedFormPrefill(
        const VehicleResolveSuggestion(
          make: 'Honda',
          model: 'Accord',
          year: 2003,
          cylinders: '6',
          doors: '4',
          seats: '5',
        ),
      );
      expect(prefill.engineCylinders, 6);
      expect(prefill.doors, 4);
      expect(prefill.seats, 5);
      expect(vinResolvedCount('0', max: 16), isNull);
      expect(vinResolvedCount('V6', max: 16), isNull);
      expect(vinResolvedCount('24', max: 16), isNull);
      expect(vinResolvedCount('7', max: 6), isNull);
      expect(vinResolvedCount('16', max: 15), isNull);
    });

    test('caution blanks counts as well as other optional specs', () {
      final prefill = vinResolvedFormPrefill(
        const VehicleResolveSuggestion(
          make: 'Honda',
          model: 'Accord',
          year: 2003,
          bodyType: 'Sedan/Saloon',
          fuelType: 'Gasoline',
          cylinders: '4',
          doors: '4',
          seats: '5',
        ),
        warnings: const ['nhtsa_catalog_decode_caution'],
      );
      expect(prefill.isEmpty, isTrue);
    });
  });
}
