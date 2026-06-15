import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('vehicle_recall_data DI/static safety', () {
    late String injection;
    late String featureTree;

    setUpAll(() {
      injection = File('lib/app/di/injection.dart').readAsStringSync();
      final dir = Directory('lib/features/vehicle_recall_data');
      final parts = <String>[];
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          parts.add(entity.readAsStringSync());
        }
      }
      featureTree = parts.join('\n');
    });

    test('vehicle_recall_data_injection.dart exists and is registered', () {
      expect(
        File(
          'lib/features/vehicle_recall_data/di/vehicle_recall_data_injection.dart',
        ).existsSync(),
        isTrue,
      );
      expect(injection, contains('vehicle_recall_data_injection.dart'));
      expect(injection, contains('registerVehicleRecallDataFeature'));
    });

    test('non-entity feature code avoids VIN and Model Passport coupling', () {
      final paths = <String>[
        'lib/features/vehicle_recall_data/data',
        'lib/features/vehicle_recall_data/di',
        'lib/features/vehicle_recall_data/domain/repositories',
        'lib/features/vehicle_recall_data/domain/usecases',
      ];
      final buffer = StringBuffer();
      for (final path in paths) {
        final dir = Directory(path);
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            buffer.writeln(entity.readAsStringSync());
          }
        }
      }
      final code = buffer.toString().toLowerCase();
      expect(code, isNot(contains('listing_vehicle_identity')));
      expect(code, isNot(contains('vin_hash')));
      expect(code, isNot(contains('vin_normalized')));
      expect(code, isNot(contains('vehicle_model_source_cache')));
      expect(code, isNot(contains('get_listing_model_data_for_buyer')));
    });

    test('entity parsers define forbidden internal keys', () {
      expect(featureTree, contains("'vin_hash'"));
      expect(featureTree, contains("'source_metadata'"));
      expect(featureTree, contains("'cache_key'"));
    });

    test('feature tree avoids direct NHTSA HTTP and VIN decode', () {
      expect(featureTree.toLowerCase(), isNot(contains('api.nhtsa.gov')));
      expect(featureTree.toLowerCase(), isNot(contains('recallsbyvehicle')));
      expect(featureTree.toLowerCase(), isNot(contains('decodevinvalues')));
      expect(featureTree.toLowerCase(), isNot(contains('process-model-data-jobs')));
    });

    test('feature tree uses buyer recall RPC only', () {
      expect(featureTree, contains('get_listing_recalls_for_buyer'));
    });

    test('feature tree avoids exact-vehicle recall claim phrases', () {
      const forbidden = [
        'this vehicle has an open recall',
        'this exact vehicle has an open recall',
        'open recall on this vehicle',
      ];
      for (final phrase in forbidden) {
        expect(featureTree.toLowerCase(), isNot(contains(phrase)));
      }
    });
  });
}
