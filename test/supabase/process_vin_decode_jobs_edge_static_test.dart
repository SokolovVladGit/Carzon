import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Phase 2C `process-vin-decode-jobs` Edge Function.
///
/// Does not execute Deno or deploy.
void main() {
  late String indexTs;
  late String indexLower;
  late String providersCombined;
  late String providersLower;

  setUpAll(() {
    final indexFile = File('supabase/functions/process-vin-decode-jobs/index.ts');
    expect(indexFile.existsSync(), isTrue, reason: 'Edge entrypoint exists');
    indexTs = indexFile.readAsStringSync();
    indexLower = indexTs.toLowerCase();

    final providersDir = Directory('supabase/functions/process-vin-decode-jobs/providers');
    expect(providersDir.existsSync(), isTrue, reason: 'providers folder exists');
    final parts = <String>[];
    for (final e in providersDir.listSync().whereType<File>()) {
      if (e.path.endsWith('.ts')) parts.add(e.readAsStringSync());
    }
    providersCombined = parts.join('\n');
    providersLower = providersCombined.toLowerCase();
  });

  group('supabase/functions/process-vin-decode-jobs/index.ts', () {
    test('requires internal secret header and documents env vars', () {
      expect(indexTs, contains('x-carzon-internal-secret'));
      expect(indexTs, contains('CARZON_PROCESS_VIN_DECODE_JOBS_SECRET'));
      expect(indexTs, contains('SUPABASE_URL'));
      expect(indexTs, contains('SUPABASE_SERVICE_ROLE_KEY'));
    });

    test('uses CARZON_VIN_DECODER_MODE with fake default path', () {
      expect(indexTs, contains('CARZON_VIN_DECODER_MODE'));
      expect(indexTs, contains('normalizeDecoderMode'));
      expect(indexTs, contains('vin_decoder_config_invalid'));
    });

    test('calls worker RPCs including get_vin_for_decode_job after claim', () {
      expect(indexTs, contains('claim_vin_decode_jobs_for_processing'));
      expect(indexTs, contains('get_vin_for_decode_job'));
      expect(indexTs, contains('complete_vin_decode_job_success'));
      expect(indexTs, contains('complete_vin_decode_job_failure'));
    });

    test('index does not call fetch (providers handle HTTP)', () {
      expect(indexLower, isNot(contains('fetch(')));
    });

    test('401 JSON on unauthorized', () {
      expect(indexTs, contains('401'));
      expect(indexTs, contains('"unauthorized"'));
    });

    test('response JSON shape omits vin-sensitive fields', () {
      expect(indexTs, contains('ok: true'));
      expect(indexTs, contains('claimed:'));
      expect(indexTs, contains('succeeded'));
      expect(indexTs, contains('failed'));
      final serveIdx = indexTs.indexOf('jsonResponse(200');
      expect(serveIdx, greaterThan(-1));
      final end = (serveIdx + 400).clamp(0, indexTs.length);
      final block = indexTs.substring(serveIdx, end).toLowerCase();
      expect(block, isNot(contains('vin_hash')));
      expect(block, isNot(contains('vin_normalized')));
    });

    test('does not stringify claimed payload or log vin fields in templates', () {
      expect(indexLower, isNot(contains('console.log')));
      expect(indexLower, isNot(contains('json.stringify(claimed')));
      expect(indexLower, isNot(contains('json.stringify(job')));
      expect(indexTs, isNot(contains(r'`${job.vin_hash}`')));
      expect(indexTs, isNot(contains(r'`${vinNormalized}`')));
    });

    test('no commercial provider env placeholders', () {
      expect(indexLower, isNot(contains('carvertical')));
      expect(indexLower, isNot(contains('vincario')));
      expect(indexLower, isNot(contains('vindecoder.eu')));
    });
  });

  group('supabase/functions/process-vin-decode-jobs/providers', () {
    test('NHTSA adapter uses vPIC DecodeVinValues base path', () {
      expect(providersCombined, contains('vpic.nhtsa.dot.gov'));
      expect(providersCombined, contains('DecodeVinValues'));
    });

    test('fetch exists only in provider layer', () {
      expect(providersLower, contains('fetch('));
    });

    test('fake provider identifies carzon_fake_vin_decoder', () {
      expect(providersCombined, contains('carzon_fake_vin_decoder'));
      expect(providersCombined, contains('fake_decoder_placeholder'));
    });

    test('factory supports fake and nhtsa modes', () {
      expect(providersCombined, contains('"fake"'));
      expect(providersCombined, contains('"nhtsa"'));
    });

    test('provider modules avoid sensitive digest substring in comments', () {
      final sensitive = File(
        'supabase/functions/process-vin-decode-jobs/providers/nhtsa_provider.ts',
      ).readAsStringSync().toLowerCase();
      expect(sensitive, isNot(contains('vin_hash')));
    });

    test('provider modules do not use console.log', () {
      expect(providersLower, isNot(contains('console.log')));
    });
  });

  group('supabase/config.toml process-vin-decode-jobs', () {
    test('verify_jwt is false for worker function', () {
      final raw = File('supabase/config.toml').readAsStringSync();
      expect(raw, contains('[functions.process-vin-decode-jobs]'));
      final idx = raw.indexOf('[functions.process-vin-decode-jobs]');
      expect(idx, greaterThan(-1));
      final end = (idx + 120).clamp(0, raw.length);
      final tail = raw.substring(idx, end);
      expect(tail, contains('verify_jwt = false'));
    });
  });
}
