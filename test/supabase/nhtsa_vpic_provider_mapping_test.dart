import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String providerTs;
  late String indexTs;

  setUpAll(() {
    providerTs = File(
      'supabase/functions/process-vin-decode-jobs/providers/nhtsa_provider.ts',
    ).readAsStringSync();
    indexTs = File(
      'supabase/functions/process-vin-decode-jobs/index.ts',
    ).readAsStringSync();
  });

  group('NHTSA vPIC provider mapping (static)', () {
    test('maps extended DecodeVinValues fields', () {
      expect(providerTs, contains('Manufacturer'));
      expect(providerTs, contains('PlantCountry'));
      expect(providerTs, contains('VehicleType'));
      expect(providerTs, contains('DriveType'));
      expect(providerTs, contains('GVWR'));
      expect(providerTs, contains('mapNhtsaVinValuesRow'));
      expect(providerTs, contains('manufacturer:'));
      expect(providerTs, contains('grossVehicleWeightRating:'));
    });

    test('decode errors stay internal, not in buyer summary path', () {
      expect(providerTs, contains('decodeErrorCode'));
      expect(providerTs, contains('nhtsa_catalog_decode_caution'));
      expect(providerTs, isNot(contains('console.log')));
    });

    test('index passes extended fields to normalized_data payload', () {
      expect(indexTs, contains('manufacturer: norm.manufacturer'));
      expect(indexTs, contains('plantCountry: norm.plantCountry'));
      expect(
        indexTs,
        contains('grossVehicleWeightRating: norm.grossVehicleWeightRating'),
      );
      expect(indexTs, contains('decodeErrorCode: norm.decodeErrorCode'));
    });
  });
}
