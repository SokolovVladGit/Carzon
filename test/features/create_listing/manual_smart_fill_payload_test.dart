import 'package:carzon/features/create_listing/data/datasources/manual_smart_fill_remote_datasource.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses ok payload with clarification', () {
    final result = parseManualSmartFillResponse({
      'status': 'ok',
      'identity': {
        'makeKey': 'skoda',
        'modelKey': 'octavia',
        'year': 2018,
        'yearTolerance': 1,
        'yearEvidence': 'registration_window',
      },
      'confidence': 'partial',
      'clarification': {
        'attribute': 'body',
        'options': [
          {'value': 'wagon', 'candidateCount': 243},
          {'value': 'sedan', 'candidateCount': 113},
        ],
      },
      'candidateCount': 920,
      'consensusSpecs': {
        'bodyType': null,
        'fuelType': null,
        'drivetrain': null,
        'enginePowerHp': null,
        'transmissionType': null,
        'engineDisplacementLiters': null,
      },
      'mappingVersion': 'm1.1',
    });

    expect(result.resolution, ManualSmartFillResolution.ok);
    expect(result.identity.makeKey, 'skoda');
    expect(result.hasSupportedClarification, isTrue);
    expect(result.clarification!.attribute, 'body');
    expect(result.clarification!.options.first.value, 'wagon');
    expect(result.mappingVersion, 'm1.1');
  });

  test('supports transmission clarification and fillable consensus', () {
    final result = parseManualSmartFillResponse({
      'status': 'ok',
      'identity': {'makeKey': 'skoda', 'modelKey': 'octavia', 'year': 2018},
      'confidence': 'partial',
      'clarification': {
        'attribute': 'transmission',
        'options': [
          {'value': 'manual', 'candidateCount': 12},
          {'value': 'automatic', 'candidateCount': 9},
        ],
      },
      'candidateCount': 21,
      'consensusSpecs': {
        'bodyType': 'wagon',
        'fuelType': 'petrol',
        'transmissionType': null,
        'drivetrain': null,
      },
      'mappingVersion': 'm1.1',
    });
    expect(result.hasSupportedClarification, isTrue);
    expect(result.clarification!.attribute, 'transmission');
    expect(result.consensus.hasAnyFillable, isTrue);
    expect(result.consensus.drivetrain, isNull);
  });

  test('parses noData', () {
    final result = parseManualSmartFillResponse({
      'status': 'noData',
      'identity': {'makeKey': 'chery', 'modelKey': 'tiggo 7', 'year': 2019},
      'confidence': 'none',
      'clarification': null,
      'candidateCount': 0,
      'consensusSpecs': {'bodyType': null, 'fuelType': null},
      'mappingVersion': 'm1.0',
    });
    expect(result.resolution, ManualSmartFillResolution.noData);
    expect(result.candidateCount, 0);
  });

  test('answer json uses backend keys', () {
    expect(
      const ManualSmartFillAnswer(
        attribute: 'fuel',
        value: 'diesel',
      ).toRpcJson(),
      {'attribute': 'fuel', 'value': 'diesel'},
    );
  });
}
