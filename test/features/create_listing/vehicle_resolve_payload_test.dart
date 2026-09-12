import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/features/create_listing/data/datasources/vehicle_resolver_remote_datasource.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseVehicleResolveResponse', () {
    test('parses a resolved payload', () {
      final result = parseVehicleResolveResponse(
        status: 200,
        data: {
          'ok': true,
          'resolution': 'resolved',
          'vehicle': {
            'make': 'BMW',
            'model': 'X5',
            'year': 2020,
            'trim': 'xDrive30d',
            'series': 'X5',
            'bodyType':
                'Sport Utility Vehicle (SUV)/Multi-Purpose Vehicle (MPV)',
            'fuelType': 'Diesel',
            'engine': '3.0L',
            'transmission': 'Automatic',
            'driveType': 'AWD/All-Wheel Drive',
            'displacement': '3.0',
            'cylinders': '6',
          },
          'completeness': 0.82,
          'warnings': ['stale_cache'],
        },
      );

      expect(result.resolution, VehicleResolveResolution.resolved);
      expect(result.vehicle.make, 'BMW');
      expect(result.vehicle.model, 'X5');
      expect(result.vehicle.year, 2020);
      expect(result.vehicle.trim, 'xDrive30d');
      expect(result.vehicle.series, 'X5');
      expect(
        result.vehicle.bodyType,
        'Sport Utility Vehicle (SUV)/Multi-Purpose Vehicle (MPV)',
      );
      expect(result.vehicle.fuelType, 'Diesel');
      expect(result.vehicle.engine, '3.0L');
      expect(result.vehicle.transmission, 'Automatic');
      expect(result.vehicle.driveType, 'AWD/All-Wheel Drive');
      expect(result.vehicle.displacement, '3.0');
      expect(result.vehicle.cylinders, '6');
      expect(result.vehicle.hasCoreIdentity, isTrue);
      expect(result.vehicle.variantHint, 'xDrive30d');
      expect(result.completeness, 0.82);
      expect(result.warnings, ['stale_cache']);
    });

    test('parses a partial payload without confirming core identity', () {
      final result = parseVehicleResolveResponse(
        status: 200,
        data: {
          'ok': true,
          'resolution': 'partial',
          'vehicle': {
            'make': 'Honda',
            'model': null,
            'year': 2003,
            'trim': '',
            'series': 'Accord',
          },
          'completeness': 0.4,
          'warnings': [],
        },
      );

      expect(result.resolution, VehicleResolveResolution.partial);
      expect(result.vehicle.make, 'Honda');
      expect(result.vehicle.model, isNull);
      expect(result.vehicle.year, 2003);
      expect(result.vehicle.hasCoreIdentity, isFalse);
      expect(result.vehicle.variantHint, 'Accord');
    });

    test('parses no_data', () {
      final result = parseVehicleResolveResponse(
        status: 200,
        data: {
          'ok': true,
          'resolution': 'no_data',
          'vehicle': {'make': null, 'model': null, 'year': null},
          'completeness': 0,
          'warnings': ['nhtsa_empty'],
        },
      );

      expect(result.resolution, VehicleResolveResolution.noData);
      expect(result.vehicle.hasCoreIdentity, isFalse);
      expect(result.vehicle.identityHeadline, isEmpty);
    });

    test('maps safe HTTP/error codes', () {
      expect(
        vehicleResolveFailureKindForStatus(401, errorCode: 'unauthorized'),
        VehicleResolveFailureKind.unauthorized,
      );
      expect(
        vehicleResolveFailureKindForStatus(400, errorCode: 'invalid_vin'),
        VehicleResolveFailureKind.invalidVin,
      );
      expect(
        vehicleResolveFailureKindForStatus(504, errorCode: 'upstream_timeout'),
        VehicleResolveFailureKind.upstreamTimeout,
      );
      expect(
        vehicleResolveFailureKindForStatus(502),
        VehicleResolveFailureKind.upstreamUnavailable,
      );
      expect(
        vehicleResolveFailureKindForStatus(500, errorCode: 'internal_error'),
        VehicleResolveFailureKind.internalError,
      );
    });

    test('ignores unknown extra backend fields', () {
      final result = parseVehicleResolveResponse(
        status: 200,
        data: {
          'ok': true,
          'resolution': 'resolved',
          'vehicle': {
            'make': 'Toyota',
            'model': 'Camry',
            'year': 2018,
            'provider': 'nhtsa',
            'vinHash': 'must-not-surface',
          },
          'completeness': 1,
          'warnings': [],
          'cacheHit': true,
          'debug': {'raw': true},
        },
      );

      expect(result.vehicle.make, 'Toyota');
      expect(result.vehicle.model, 'Camry');
      expect(result.vehicle.year, 2018);
      expect(result.vehicle.bodyType, isNull);
      expect(result.vehicle.fuelType, isNull);
      expect(result.vehicle.transmission, isNull);
      expect(result.vehicle.driveType, isNull);
      expect(result.vehicle.displacement, isNull);
      expect(result.vehicle.cylinders, isNull);
      expect(result.vehicle.engine, isNull);
    });

    test('blank optional spec fields normalize to null', () {
      final result = parseVehicleResolveResponse(
        status: 200,
        data: {
          'ok': true,
          'resolution': 'resolved',
          'vehicle': {
            'make': 'Ram',
            'model': '1500',
            'year': 2021,
            'bodyType': '  ',
            'fuelType': '',
            'engine': '   ',
            'transmission': ' Automatic  ',
            'driveType': null,
            'displacement': '6.2   L',
            'cylinders': '',
          },
          'completeness': 0.5,
          'warnings': [],
        },
      );

      expect(result.vehicle.bodyType, isNull);
      expect(result.vehicle.fuelType, isNull);
      expect(result.vehicle.engine, isNull);
      expect(result.vehicle.transmission, 'Automatic');
      expect(result.vehicle.driveType, isNull);
      expect(result.vehicle.displacement, '6.2 L');
      expect(result.vehicle.cylinders, isNull);
    });

    test('malformed payload fails safely', () {
      expect(
        () => parseVehicleResolveResponse(status: 200, data: 'nope'),
        throwsA(isA<VehicleResolveServerException>()),
      );
      expect(
        () => parseVehicleResolveResponse(
          status: 200,
          data: {'ok': true, 'resolution': 'mystery', 'vehicle': {}},
        ),
        throwsA(isA<VehicleResolveServerException>()),
      );
      expect(
        () => parseVehicleResolveResponse(
          status: 200,
          data: {'ok': true, 'resolution': 'resolved', 'vehicle': 'x'},
        ),
        throwsA(isA<VehicleResolveServerException>()),
      );
    });

    test('malformed expected field types do not crash parsing', () {
      final result = parseVehicleResolveResponse(
        status: 200,
        data: {
          'ok': true,
          'resolution': 'partial',
          'vehicle': {
            'make': 12,
            'model': true,
            'year': '2020',
            'trim': ['x'],
          },
          'completeness': 'high',
          'warnings': 'nope',
        },
      );

      expect(result.vehicle.make, isNull);
      expect(result.vehicle.model, isNull);
      expect(result.vehicle.year, isNull);
      expect(result.vehicle.trim, isNull);
      expect(result.vehicle.bodyType, isNull);
      expect(result.vehicle.fuelType, isNull);
      expect(result.vehicle.engine, isNull);
      expect(result.vehicle.transmission, isNull);
      expect(result.vehicle.driveType, isNull);
      expect(result.vehicle.displacement, isNull);
      expect(result.vehicle.cylinders, isNull);
      expect(result.completeness, 0);
      expect(result.warnings, isEmpty);
    });
  });

  group('variantSuggestionFrom', () {
    test('prefers trim over series', () {
      expect(
        variantSuggestionFrom(trim: 'xDrive30d', series: 'X5'),
        'xDrive30d',
      );
    });

    test('uses series when trim is absent', () {
      expect(variantSuggestionFrom(trim: null, series: '330i'), '330i');
      expect(variantSuggestionFrom(trim: '  ', series: '330i'), '330i');
    });
  });
}
