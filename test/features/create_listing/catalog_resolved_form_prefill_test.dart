import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_result.dart';
import 'package:carzon/features/create_listing/presentation/models/catalog_resolved_form_prefill.dart';
import 'package:carzon/features/create_listing/presentation/models/vin_resolved_form_prefill.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps supported catalog bodies', () {
    expect(catalogResolvedBodyType('sedan'), ListingBodyType.sedan);
    expect(catalogResolvedBodyType('hatchback'), ListingBodyType.hatchback);
    expect(catalogResolvedBodyType('wagon'), ListingBodyType.wagon);
    expect(catalogResolvedBodyType('suv'), ListingBodyType.suv);
    expect(catalogResolvedBodyType('coupe'), ListingBodyType.coupe);
    expect(catalogResolvedBodyType('convertible'), ListingBodyType.convertible);
    expect(catalogResolvedBodyType('pickup'), ListingBodyType.pickup);
    expect(catalogResolvedBodyType('van'), ListingBodyType.van);
    expect(catalogResolvedBodyType('minivan'), ListingBodyType.minivan);
  });

  test('maps supported catalog fuels including hybrid and phev', () {
    expect(catalogResolvedFuelType('petrol'), ListingFuelType.petrol);
    expect(catalogResolvedFuelType('diesel'), ListingFuelType.diesel);
    expect(catalogResolvedFuelType('hybrid'), ListingFuelType.hybrid);
    expect(
      catalogResolvedFuelType('plug_in_hybrid'),
      ListingFuelType.plugInHybrid,
    );
    expect(catalogResolvedFuelType('electric'), ListingFuelType.electric);
    expect(catalogResolvedFuelType('lpg'), ListingFuelType.lpg);
    expect(catalogResolvedFuelType('cng'), ListingFuelType.cng);
  });

  test('unknown catalog values stay null and are not other', () {
    expect(catalogResolvedBodyType('roadster'), isNull);
    expect(catalogResolvedBodyType('other'), isNull);
    expect(catalogResolvedFuelType('hydrogen'), isNull);
    expect(catalogResolvedFuelType('other'), isNull);
  });

  test('VIN mapper is not used for catalog hybrid or wagon', () {
    expect(vinResolvedFuelType('hybrid'), isNull);
    expect(vinResolvedBodyType('wagon'), isNull);
    expect(catalogResolvedFuelType('hybrid'), ListingFuelType.hybrid);
    expect(catalogResolvedBodyType('wagon'), ListingBodyType.wagon);
  });

  test('maps catalog transmission and still ignores drivetrain', () {
    final prefill = catalogResolvedFormPrefill(
      const ManualSmartFillConsensusSpecs(
        bodyType: 'suv',
        fuelType: 'petrol',
        engineDisplacementLiters: 2,
        enginePowerHp: 150,
        transmissionType: 'automatic',
        drivetrain: 'awd',
      ),
    );
    expect(prefill.bodyType, ListingBodyType.suv);
    expect(prefill.fuelType, ListingFuelType.petrol);
    expect(prefill.engineDisplacementLiters, 2);
    expect(prefill.enginePowerHp, 150);
    expect(prefill.transmissionType, ListingTransmissionType.automatic);
  });

  test('maps official TGK-safe transmission taxonomy only', () {
    expect(
      catalogResolvedTransmissionType('manual'),
      ListingTransmissionType.manual,
    );
    expect(
      catalogResolvedTransmissionType('automatic'),
      ListingTransmissionType.automatic,
    );
    expect(catalogResolvedTransmissionType('cvt'), ListingTransmissionType.cvt);
    expect(
      catalogResolvedTransmissionType('dual_clutch'),
      ListingTransmissionType.dualClutch,
    );
    expect(
      catalogResolvedTransmissionType('robotic'),
      ListingTransmissionType.robotic,
    );
    expect(
      catalogResolvedTransmissionType('other'),
      ListingTransmissionType.other,
    );
    expect(catalogResolvedTransmissionType('M'), isNull);
    expect(catalogResolvedTransmissionType('xdrive'), isNull);
    expect(catalogResolvedTransmissionType('fixed'), isNull);
  });

  test('skips invalid displacement and power', () {
    expect(catalogResolvedDisplacementLiters(0), isNull);
    expect(catalogResolvedDisplacementLiters(40), isNull);
    expect(catalogResolvedPowerHp(0), isNull);
    expect(catalogResolvedPowerHp(4000), isNull);
  });

  test('ownership helpers encode seller > VIN > catalog', () {
    expect(catalogMayFillField(isEmpty: true, vinOwned: false), isTrue);
    expect(catalogMayFillField(isEmpty: true, vinOwned: true), isFalse);
    expect(catalogMayFillField(isEmpty: false, vinOwned: false), isFalse);
    expect(
      catalogMayFillField(isEmpty: false, vinOwned: false, catalogOwned: true),
      isTrue,
    );
    expect(
      catalogMayFillField(isEmpty: false, vinOwned: true, catalogOwned: true),
      isFalse,
    );
    expect(vinMayReplaceField(isEmpty: true, catalogOwned: false), isTrue);
    expect(vinMayReplaceField(isEmpty: false, catalogOwned: true), isTrue);
    expect(vinMayReplaceField(isEmpty: false, catalogOwned: false), isFalse);
  });
}
