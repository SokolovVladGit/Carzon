import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for `resolve-vehicle` Edge Function. Does not deploy.
void main() {
  late String indexTs;
  late String handlerTs;
  late String resolveTs;
  late String nhtsaTs;
  late String configToml;
  late String workerIndexTs;

  setUpAll(() {
    indexTs = File(
      'supabase/functions/resolve-vehicle/index.ts',
    ).readAsStringSync();
    handlerTs = File(
      'supabase/functions/resolve-vehicle/handler.ts',
    ).readAsStringSync();
    resolveTs = File(
      'supabase/functions/resolve-vehicle/resolve.ts',
    ).readAsStringSync();
    nhtsaTs = File(
      'supabase/functions/resolve-vehicle/nhtsa.ts',
    ).readAsStringSync();
    configToml = File('supabase/config.toml').readAsStringSync();
    workerIndexTs = File(
      'supabase/functions/process-vin-decode-jobs/index.ts',
    ).readAsStringSync();
  });

  group('resolve-vehicle config', () {
    test('verify_jwt is true and worker stays false', () {
      expect(configToml, contains('[functions.resolve-vehicle]'));
      final resolveIdx = configToml.indexOf('[functions.resolve-vehicle]');
      expect(resolveIdx, greaterThan(-1));
      final resolveTail = configToml.substring(
        resolveIdx,
        (resolveIdx + 160).clamp(0, configToml.length),
      );
      expect(resolveTail, contains('verify_jwt = true'));

      final workerIdx = configToml.indexOf('[functions.process-vin-decode-jobs]');
      expect(workerIdx, greaterThan(-1));
      final workerTail = configToml.substring(
        workerIdx,
        (workerIdx + 120).clamp(0, configToml.length),
      );
      expect(workerTail, contains('verify_jwt = false'));
    });
  });

  group('resolve-vehicle contract', () {
    test('is POST + JWT user-facing and cache-first', () {
      expect(handlerTs, contains('req.method !== "POST"'));
      expect(indexTs, contains('auth.getUser'));
      expect(resolveTs, contains('isReusableCacheRow'));
      expect(resolveTs, contains('decodeNhtsa'));
      expect(resolveTs, isNot(contains('vin_decode_cache')));
    });

    test('does not enqueue listing-bound VIN pipeline', () {
      final combined = '$indexTs\n$handlerTs\n$resolveTs';
      expect(combined, isNot(contains('vin_processing_jobs')));
      expect(combined, isNot(contains('listing_vehicle_identity')));
      expect(combined, isNot(contains('listing_vin_report_snapshot')));
      expect(combined, isNot(contains('listing_vin_source_results')));
      expect(combined, isNot(contains('create_listing_v2')));
      expect(combined, isNot(contains('process-model-data-jobs')));
      expect(combined, isNot(contains('epa')));
    });

    test('public allow-list omits VIN hash and provider internals', () {
      expect(resolveTs, contains('PublicVehicleSuggestion'));
      expect(handlerTs.toLowerCase(), isNot(contains('console.log')));
      expect(indexTs.toLowerCase(), isNot(contains('console.log')));
      expect(nhtsaTs, contains('nhtsa_vpic'));
      expect(nhtsaTs, contains('decode-vin-values-v2'));
      expect(nhtsaTs, contains('15_000'));
    });
  });

  group('process-vin-decode-jobs left unchanged', () {
    test('worker still uses internal secret and job RPCs', () {
      expect(workerIndexTs, contains('x-carzon-internal-secret'));
      expect(workerIndexTs, contains('claim_vin_decode_jobs_for_processing'));
      expect(workerIndexTs, contains('complete_vin_decode_job_success'));
    });
  });
}
