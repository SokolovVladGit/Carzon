import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/presentation/models/vin_resolve_display.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();
  final ro = roStrings();

  const ram = VehicleResolveSuggestion(
    make: 'Ram',
    model: '1500',
    year: 2021,
    trim: 'TRX',
    bodyType: 'Pickup',
    fuelType: 'Gasoline',
    engine: 'Supercharged 6.2',
    transmission: 'Automatic',
    driveType: '4WD/4-Wheel Drive/4x4',
    displacement: '6.2 L',
    cylinders: '8',
  );

  test('maps a realistic Ram result for RU and RO', () {
    final ruSpec = vinResolveDisplaySpec(
      vehicle: ram,
      warnings: const [],
      l10n: ru,
    );
    expect(ruSpec.fuel, ru.listingFuelTypePetrol);
    expect(ruSpec.transmission, ru.listingTransmissionAutomatic);
    expect(ruSpec.drivetrain, ru.listingDrivetrainFourWheel);
    expect(ruSpec.displacement, '6.2 ${ru.listingEngineDisplacementLitersSuffix}');
    expect(ruSpec.body, ru.listingBodyTypePickup);
    expect(ruSpec.caution, isNull);
    expect(ruSpec.line1, 'Бензин · Автомат');
    expect(ruSpec.line2, '4×4 · 6.2 л');

    final roSpec = vinResolveDisplaySpec(
      vehicle: ram,
      warnings: const [],
      l10n: ro,
    );
    expect(roSpec.fuel, ro.listingFuelTypePetrol);
    expect(roSpec.transmission, ro.listingTransmissionAutomatic);
    expect(roSpec.drivetrain, ro.listingDrivetrainFourWheel);
    expect(roSpec.body, ro.listingBodyTypePickup);
    expect(roSpec.fuel, isNot(ruSpec.fuel));
    expect(roSpec.line1.contains(' · '), isTrue);
  });

  test('omits empty separators when only fuel is known', () {
    final spec = vinResolveDisplaySpec(
      vehicle: const VehicleResolveSuggestion(
        make: 'Honda',
        model: 'Civic',
        year: 2019,
        fuelType: 'Diesel',
      ),
      warnings: const [],
      l10n: ru,
    );
    expect(spec.line1, ru.listingFuelTypeDiesel);
    expect(spec.line2, isEmpty);
    expect(spec.body, isNull);
    expect(joinVinSpecParts([null, '', '  ']), isEmpty);
  });

  test('unknown and ambiguous provider values stay unmapped', () {
    final spec = vinResolveDisplaySpec(
      vehicle: const VehicleResolveSuggestion(
        fuelType: 'Flexible Fuel',
        transmission: 'Automated Manual (6)',
        driveType: '4x2',
        bodyType: 'Incomplete - Cutaway',
        displacement: '0 L',
        engine: 'V-Shaped Supercharged 6.2',
        cylinders: '8',
      ),
      warnings: const [],
      l10n: ru,
    );
    expect(spec.fuel, isNull);
    expect(spec.transmission, isNull);
    expect(spec.drivetrain, isNull);
    expect(spec.body, isNull);
    expect(spec.displacement, isNull);
    expect(spec.hasTechnicalLines, isFalse);
  });

  test('keeps AWD and 4WD as distinct display labels', () {
    final awd = vinResolveDisplaySpec(
      vehicle: const VehicleResolveSuggestion(driveType: 'AWD/All-Wheel Drive'),
      warnings: const [],
      l10n: ru,
    );
    final four = vinResolveDisplaySpec(
      vehicle: const VehicleResolveSuggestion(driveType: '4WD/4-Wheel Drive/4x4'),
      warnings: const [],
      l10n: ru,
    );
    expect(awd.drivetrain, ru.listingDrivetrainAwd);
    expect(four.drivetrain, ru.listingDrivetrainFourWheel);
    expect(awd.drivetrain, isNot(four.drivetrain));
  });

  test('safe warnings produce a generic caution only', () {
    final withWarning = vinResolveDisplaySpec(
      vehicle: ram,
      warnings: const ['nhtsa_catalog_decode_caution'],
      l10n: ru,
    );
    expect(withWarning.caution, ru.createListingVinSpecCaution);
    expect(withWarning.caution, isNot(contains('nhtsa')));
    expect(
      vinResolveDisplaySpec(
        vehicle: ram,
        warnings: const [],
        l10n: ru,
      ).caution,
      isNull,
    );
    expect(
      vinResolveDisplaySpec(
        vehicle: ram,
        warnings: const ['nhtsa_catalog_decode_caution'],
        l10n: ro,
      ).caution,
      ro.createListingVinSpecCaution,
    );
    expect(ru.createListingVinSpecCaution, isNot(ro.createListingVinSpecCaution));
  });
}
