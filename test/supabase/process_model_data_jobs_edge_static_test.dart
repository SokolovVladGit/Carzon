import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Phase 1 `process-model-data-jobs` Edge Function.
void main() {
  late String indexTs;
  late String indexLower;
  late String providersCombined;
  late String providersLower;

  setUpAll(() {
    final indexFile = File(
      'supabase/functions/process-model-data-jobs/index.ts',
    );
    expect(indexFile.existsSync(), isTrue, reason: 'Edge entrypoint exists');
    indexTs = indexFile.readAsStringSync();
    indexLower = indexTs.toLowerCase();

    final providersDir = Directory(
      'supabase/functions/process-model-data-jobs/providers',
    );
    expect(providersDir.existsSync(), isTrue, reason: 'providers folder exists');
    final parts = <String>[];
    for (final e in providersDir.listSync().whereType<File>()) {
      if (e.path.endsWith('.ts')) parts.add(e.readAsStringSync());
    }
    providersCombined = parts.join('\n');
    providersLower = providersCombined.toLowerCase();
  });

  group('supabase/functions/process-model-data-jobs/index.ts', () {
    test('requires internal secret header and documents env vars', () {
      expect(indexTs, contains('x-carzon-internal-secret'));
      expect(indexTs, contains('CARZON_PROCESS_MODEL_DATA_JOBS_SECRET'));
      expect(indexTs, contains('SUPABASE_URL'));
      expect(indexTs, contains('SUPABASE_SERVICE_ROLE_KEY'));
    });

    test('uses CARZON_MODEL_DATA_PROVIDER_MODE with fake default path', () {
      expect(indexTs, contains('CARZON_MODEL_DATA_PROVIDER_MODE'));
      expect(indexTs, contains('normalizeProviderMode'));
      expect(indexTs, contains('model_data_provider_config_invalid'));
      expect(indexTs, contains('`fake` (default) | `fake_sample` | `epa`'));
    });

    test('calls worker claim/complete RPCs', () {
      expect(indexTs, contains('claim_vehicle_model_fetch_jobs_for_processing'));
      expect(indexTs, contains('get_listing_vin_model_fetch_hints'));
      expect(indexTs, contains('complete_vehicle_model_fetch_job_success'));
      expect(indexTs, contains('complete_vehicle_model_fetch_job_failure'));
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
  });

  group('supabase/functions/process-model-data-jobs/providers', () {
    test('fake provider exists with no_data default', () {
      expect(providersCombined, contains('FakeModelDataProvider'));
      expect(providersCombined, contains('carzon_fake_model_data'));
      expect(providersCombined, contains('"no_data"'));
    });

    test('fake_sample mode is explicit and non-default', () {
      expect(providersCombined, contains('fake_sample'));
      expect(providersCombined, contains('toyota'));
      expect(providersCombined, contains('camry'));
      expect(providersCombined, contains('highlander'));
    });

    test('factory supports fake, fake_sample, and opt-in epa modes', () {
      expect(providersCombined, contains('"epa"'));
      expect(providersCombined, contains('EpaFuelEconomyProvider'));
      expect(providersCombined, contains('FakeModelDataProvider'));
    });

    test('required limitation codes are defined', () {
      expect(providersCombined, contains('us_market_data_only'));
      expect(providersCombined, contains('not_recall_data'));
    });

    test('EPA HTTP exists only in epa provider module', () {
      final epaProvider = File(
        'supabase/functions/process-model-data-jobs/providers/epa_provider.ts',
      ).readAsStringSync().toLowerCase();
      final epaMapping = File(
        'supabase/functions/process-model-data-jobs/providers/epa_mapping.ts',
      ).readAsStringSync().toLowerCase();
      expect(epaProvider, contains('await fetch('));
      expect(epaMapping, contains('fueleconomy.gov/ws/rest/vehicle'));
    });

    test('no real EPA call in default fake provider path', () {
      final fakeProvider = File(
        'supabase/functions/process-model-data-jobs/providers/fake_provider.ts',
      ).readAsStringSync().toLowerCase();
      expect(fakeProvider, isNot(contains('await fetch(')));
      expect(fakeProvider, contains('no_data'));
    });

    test('no real EPA or Wikidata HTTP endpoints in fake/mapping-only modules', () {
      final fakeProvider = File(
        'supabase/functions/process-model-data-jobs/providers/fake_provider.ts',
      ).readAsStringSync().toLowerCase();
      final mapping = File(
        'supabase/functions/process-model-data-jobs/providers/epa_mapping.ts',
      ).readAsStringSync().toLowerCase();
      expect(fakeProvider, isNot(contains('await fetch(')));
      expect(mapping, isNot(contains('await fetch(')));
      expect(providersLower, isNot(contains('wikidata.org')));
      expect(providersLower, isNot(contains('carvertical')));
    });

    test('provider modules do not use console.log', () {
      expect(providersLower, isNot(contains('console.log')));
    });
  });

  group('supabase/config.toml process-model-data-jobs', () {
    test('verify_jwt is false for worker function', () {
      final raw = File('supabase/config.toml').readAsStringSync();
      expect(raw, contains('[functions.process-model-data-jobs]'));
      final idx = raw.indexOf('[functions.process-model-data-jobs]');
      expect(idx, greaterThan(-1));
      final end = (idx + 120).clamp(0, raw.length);
      final tail = raw.substring(idx, end);
      expect(tail, contains('verify_jwt = false'));
    });
  });
}
