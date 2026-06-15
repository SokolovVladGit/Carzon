import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Phase 2 `process-recall-data-jobs` Edge Function.
void main() {
  late String indexTs;
  late String indexLower;
  late String providersCombined;
  late String providersLower;

  setUpAll(() {
    final indexFile = File(
      'supabase/functions/process-recall-data-jobs/index.ts',
    );
    expect(indexFile.existsSync(), isTrue, reason: 'Edge entrypoint exists');
    indexTs = indexFile.readAsStringSync();
    indexLower = indexTs.toLowerCase();

    final providersDir = Directory(
      'supabase/functions/process-recall-data-jobs/providers',
    );
    expect(providersDir.existsSync(), isTrue, reason: 'providers folder exists');
    final parts = <String>[];
    for (final e in providersDir.listSync().whereType<File>()) {
      if (e.path.endsWith('.ts')) parts.add(e.readAsStringSync());
    }
    providersCombined = parts.join('\n');
    providersLower = providersCombined.toLowerCase();
  });

  group('supabase/functions/process-recall-data-jobs/index.ts', () {
    test('requires internal secret header and documents env vars', () {
      expect(indexTs, contains('x-carzon-internal-secret'));
      expect(indexTs, contains('CARZON_PROCESS_RECALL_DATA_JOBS_SECRET'));
      expect(indexTs, contains('SUPABASE_URL'));
      expect(indexTs, contains('SUPABASE_SERVICE_ROLE_KEY'));
    });

    test('uses CARZON_RECALL_DATA_PROVIDER_MODE with fake default path', () {
      expect(indexTs, contains('CARZON_RECALL_DATA_PROVIDER_MODE'));
      expect(indexTs, contains('normalizeProviderMode'));
      expect(indexTs, contains('recall_data_provider_config_invalid'));
      expect(indexTs, contains('`fake` (default) | `fake_sample` | `nhtsa`'));
    });

    test('calls recall worker claim/complete RPCs', () {
      expect(indexTs, contains('claim_vehicle_recall_fetch_jobs_for_processing'));
      expect(indexTs, contains('complete_vehicle_recall_fetch_job_success'));
      expect(indexTs, contains('complete_vehicle_recall_fetch_job_failure'));
    });

    test('index does not perform HTTP fetch calls', () {
      expect(indexTs, isNot(contains('await fetch(')));
      expect(indexTs, isNot(contains('= fetch(')));
    });

    test('401 JSON on unauthorized', () {
      expect(indexTs, contains('401'));
      expect(indexTs, contains('"unauthorized"'));
    });

    test('response JSON shape omits sensitive/internal fields', () {
      expect(indexTs, contains('ok: true'));
      expect(indexTs, contains('claimed:'));
      expect(indexTs, contains('succeeded'));
      expect(indexTs, contains('failed'));
      final serveIdx = indexTs.indexOf('jsonResponse(200');
      expect(serveIdx, greaterThan(-1));
      final end = (serveIdx + 400).clamp(0, indexTs.length);
      final block = indexTs.substring(serveIdx, end).toLowerCase();
      expect(block, isNot(contains('cache_key')));
      expect(block, isNot(contains('source_metadata')));
    });

    test('does not use console.log or stringify job payloads', () {
      expect(indexLower, isNot(contains('console.log')));
      expect(indexLower, isNot(contains('json.stringify(claimed')));
    });

    test('does not reference VIN or Model Passport tables', () {
      expect(indexLower, isNot(contains('listing_vehicle_identity')));
      expect(indexLower, isNot(contains('vin_hash')));
      expect(indexLower, isNot(contains('vehicle_model_source_cache')));
      expect(indexLower, isNot(contains('process-model-data-jobs')));
      expect(indexLower, isNot(contains('decodevinvalues')));
    });
  });

  group('supabase/functions/process-recall-data-jobs/providers', () {
    test('fake provider exists with no_data default', () {
      expect(providersCombined, contains('FakeRecallProvider'));
      expect(providersCombined, contains('carzon_fake_recall_data'));
      expect(providersCombined, contains('"no_data"'));
    });

    test('fake_sample mode is explicit and non-default', () {
      expect(providersCombined, contains('fake_sample'));
      expect(providersCombined, contains('toyota'));
      expect(providersCombined, contains('camry'));
      expect(providersCombined, contains('campaign_number'));
    });

    test('factory supports fake, fake_sample, and opt-in nhtsa modes', () {
      expect(providersCombined, contains('"nhtsa"'));
      expect(providersCombined, contains('NhtsaRecallsProvider'));
      expect(providersCombined, contains('FakeRecallProvider'));
    });

    test('required limitation codes are defined', () {
      expect(providersCombined, contains('not_vin_verified_recall_status'));
      expect(providersCombined, contains('model_level_not_exact_vehicle'));
    });

    test('NHTSA HTTP exists only in nhtsa provider module', () {
      final nhtsaProvider = File(
        'supabase/functions/process-recall-data-jobs/providers/nhtsa_provider.ts',
      ).readAsStringSync().toLowerCase();
      final nhtsaMapping = File(
        'supabase/functions/process-recall-data-jobs/providers/nhtsa_mapping.ts',
      ).readAsStringSync().toLowerCase();
      expect(nhtsaProvider, contains('await fetch('));
      expect(nhtsaMapping, contains('recalls/recallsbyvehicle'));
    });

    test('no real NHTSA call in default fake provider path', () {
      final fakeProvider = File(
        'supabase/functions/process-recall-data-jobs/providers/fake_provider.ts',
      ).readAsStringSync().toLowerCase();
      expect(fakeProvider, isNot(contains('await fetch(')));
      expect(fakeProvider, contains('no_data'));
    });

    test('does not store raw provider payload in normalized summary', () {
      expect(providersLower, isNot(contains('normalizedsummary: response.body')));
      expect(providersLower, isNot(contains('rawprovider')));
      expect(providersLower, isNot(contains('console.log')));
    });

    test('avoid unsafe exact-vehicle recall claim phrases', () {
      const forbidden = [
        'this exact vehicle has an open recall',
        'open recall on this vehicle',
        'this vehicle has an open recall',
      ];
      for (final phrase in forbidden) {
        expect(providersLower, isNot(contains(phrase)));
        expect(indexLower, isNot(contains(phrase)));
      }
    });
  });

  group('supabase/config.toml process-recall-data-jobs', () {
    test('verify_jwt is false for worker function', () {
      final raw = File('supabase/config.toml').readAsStringSync();
      expect(raw, contains('[functions.process-recall-data-jobs]'));
      final idx = raw.indexOf('[functions.process-recall-data-jobs]');
      expect(idx, greaterThan(-1));
      final end = (idx + 120).clamp(0, raw.length);
      final tail = raw.substring(idx, end);
      expect(tail, contains('verify_jwt = false'));
    });
  });
}
