import 'package:carzon/features/create_listing/data/datasources/manual_smart_fill_remote_datasource.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_refinement.dart';
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

  test('parses body refinement option', () {
    final result = parseManualSmartFillResponse({
      'status': 'ok',
      'mappingVersion': 'm1.2',
      'identity': {'makeKey': 'skoda', 'modelKey': 'fabia', 'year': 2019},
      'consensusSpecs': {'drivetrain': null},
      'nextRefinement': {
        'kind': 'body',
        'allowUnknown': true,
        'options': [
          {'id': 'body-hatch', 'candidateCount': 10, 'bodyType': 'hatchback'},
          {'id': 'body-wagon', 'candidateCount': 4, 'bodyType': 'wagon'},
        ],
      },
      'refinementState': {
        'answers': [],
        'skippedKinds': [],
        'decisionsUsed': 0,
        'maxDecisions': 3,
      },
    });
    expect(result.nextRefinement!.kind, ManualSmartFillRefinementKind.body);
    expect(result.nextRefinement!.options.first.bodyType, 'hatchback');
    expect(result.clarification!.attribute, 'body');
  });

  test('parses fuel refinement option', () {
    final result = parseManualSmartFillResponse({
      'status': 'ok',
      'identity': {'makeKey': 'skoda', 'modelKey': 'fabia', 'year': 2019},
      'nextRefinement': {
        'kind': 'fuel',
        'options': [
          {'id': 'fuel-p', 'candidateCount': 8, 'fuelType': 'petrol'},
          {'id': 'fuel-d', 'candidateCount': 3, 'fuelType': 'diesel'},
        ],
      },
    });
    expect(result.nextRefinement!.options.last.fuelType, 'diesel');
  });

  test('parses engine composite option', () {
    final result = parseManualSmartFillResponse({
      'status': 'ok',
      'identity': {'makeKey': 'skoda', 'modelKey': 'fabia', 'year': 2019},
      'nextRefinement': {
        'kind': 'engine',
        'options': [
          {
            'id': 'eng-1',
            'candidateCount': 6,
            'fuelType': 'petrol',
            'engineDisplacementLiters': 1.0,
            'enginePowerHp': 95,
          },
        ],
      },
    });
    final option = result.nextRefinement!.options.single;
    expect(option.fuelType, 'petrol');
    expect(option.engineDisplacementLiters, 1.0);
    expect(option.enginePowerHp, 95);
    expect(result.clarification, isNull);
  });

  test('parses transmission refinement option', () {
    final result = parseManualSmartFillResponse({
      'status': 'ok',
      'identity': {'makeKey': 'skoda', 'modelKey': 'fabia', 'year': 2019},
      'nextRefinement': {
        'kind': 'transmission',
        'options': [
          {'id': 'tr-m', 'candidateCount': 4, 'transmissionType': 'manual'},
        ],
      },
    });
    expect(result.nextRefinement!.options.single.transmissionType, 'manual');
  });

  test('unknown taxonomy and malformed options do not crash', () {
    final result = parseManualSmartFillResponse({
      'status': 'ok',
      'identity': {'makeKey': 'skoda', 'modelKey': 'fabia', 'year': 2019},
      'consensusSpecs': {
        'bodyType': 'spaceship',
        'fuelType': 'unobtanium',
        'transmissionType': 'warp',
        'drivetrain': 'anti-grav',
      },
      'nextRefinement': {
        'kind': 'engine',
        'options': [
          {'id': 'bad', 'candidateCount': 1, 'fuelType': 'petrol'},
          {
            'id': 'ok',
            'candidateCount': 2,
            'fuelType': 'mystery',
            'engineDisplacementLiters': 1.2,
            'enginePowerHp': 90,
          },
        ],
      },
    });
    expect(result.consensus.bodyType, 'spaceship');
    expect(result.nextRefinement!.options, hasLength(1));
    expect(result.nextRefinement!.options.single.fuelType, 'mystery');
  });

  test('unknown next kind is ignored', () {
    final result = parseManualSmartFillResponse({
      'status': 'ok',
      'identity': {'makeKey': 'skoda', 'modelKey': 'fabia', 'year': 2019},
      'nextRefinement': {
        'kind': 'trim',
        'options': [
          {'id': 'x', 'candidateCount': 1, 'bodyType': 'hatchback'},
        ],
      },
    });
    expect(result.nextRefinement, isNull);
  });

  test('parses invalidRefinement without identity keys', () {
    final result = parseManualSmartFillResponse({
      'status': 'invalidRefinement',
      'identity': {'year': 2019},
      'consensusSpecs': {},
      'mappingVersion': 'm1.2',
    });
    expect(result.resolution, ManualSmartFillResolution.invalidRefinement);
  });

  test('answer json uses backend keys', () {
    expect(
      const ManualSmartFillAnswer(
        attribute: 'fuel',
        value: 'diesel',
      ).toRpcJson(),
      {'attribute': 'fuel', 'value': 'diesel'},
    );
    expect(
      const ManualSmartFillRefinementAnswer(
        kind: ManualSmartFillRefinementKind.engine,
        optionId: 'abc',
      ).toRpcJson(),
      {'kind': 'engine', 'optionId': 'abc'},
    );
  });
}
