import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String indexTs;
  late String indexLower;
  late String providersCombined;
  late String providersLower;

  setUpAll(() {
    final indexFile = File(
      'supabase/functions/process-fuel-price-jobs/index.ts',
    );
    expect(indexFile.existsSync(), isTrue, reason: 'Edge entrypoint exists');
    indexTs = indexFile.readAsStringSync();
    indexLower = indexTs.toLowerCase();

    final providersDir = Directory(
      'supabase/functions/process-fuel-price-jobs/providers',
    );
    expect(providersDir.existsSync(), isTrue, reason: 'providers folder exists');
    final parts = <String>[];
    for (final e in providersDir.listSync().whereType<File>()) {
      if (e.path.endsWith('.ts')) parts.add(e.readAsStringSync());
    }
    providersCombined = parts.join('\n');
    providersLower = providersCombined.toLowerCase();
  });

  group('supabase/functions/process-fuel-price-jobs/index.ts', () {
    test('requires internal secret header and documents env vars', () {
      expect(indexTs, contains('x-carzon-internal-secret'));
      expect(indexTs, contains('CARZON_PROCESS_FUEL_PRICE_JOBS_SECRET'));
      expect(indexTs, contains('SUPABASE_URL'));
      expect(indexTs, contains('SUPABASE_SERVICE_ROLE_KEY'));
    });

    test('uses CARZON_FUEL_PRICE_PROVIDER_MODE with fail-closed config', () {
      expect(indexTs, contains('CARZON_FUEL_PRICE_PROVIDER_MODE'));
      expect(indexTs, contains('normalizeProviderMode'));
      expect(indexTs, contains('fuel_price_provider_config_invalid'));
    });

    test('calls worker claim/complete RPCs', () {
      expect(indexTs, contains('enqueue_all_fuel_price_fetch_jobs'));
      expect(indexTs, contains('claim_fuel_price_fetch_jobs_for_processing'));
      expect(indexTs, contains('complete_fuel_price_fetch_job_success'));
      expect(indexTs, contains('complete_fuel_price_fetch_job_failure'));
    });

    test('index does not perform HTTP fetch calls', () {
      expect(indexTs, isNot(contains('await fetch(')));
    });

    test('401 JSON on unauthorized', () {
      expect(indexTs, contains('401'));
      expect(indexTs, contains('"unauthorized"'));
    });

    test('response JSON shape omits sensitive/internal fields', () {
      expect(indexTs, contains('ok: true'));
      expect(indexTs, contains('claimed:'));
      final serveIdx = indexTs.indexOf('jsonResponse(200');
      expect(serveIdx, greaterThan(-1));
      final end = (serveIdx + 400).clamp(0, indexTs.length);
      final block = indexTs.substring(serveIdx, end).toLowerCase();
      expect(block, isNot(contains('cache_key')));
      expect(block, isNot(contains('source_metadata')));
    });

    test('does not use console.log', () {
      expect(indexLower, isNot(contains('console.log')));
    });
  });

  group('supabase/functions/process-fuel-price-jobs/providers', () {
    test('fake provider exists', () {
      expect(providersCombined, contains('FakeFuelPriceProvider'));
      expect(providersCombined, contains('carzon_fake_fuel_prices'));
    });

    test('live providers exist', () {
      expect(providersCombined, contains('AnrePlafonProvider'));
      expect(providersCombined, contains('SheriffRetailProvider'));
      expect(providersCombined, contains('api.ecarburanti.anre.md/public/plafon/'));
      expect(providersCombined, contains('sheriff.md/activities/nefteprodukty/ceny_po_regionam/'));
    });

    test('HTTP fetch only in live provider modules', () {
      final fakeProvider = File(
        'supabase/functions/process-fuel-price-jobs/providers/fake_provider.ts',
      ).readAsStringSync().toLowerCase();
      expect(fakeProvider, isNot(contains('await fetch(')));
    });

    test('provider modules do not use console.log', () {
      expect(providersLower, isNot(contains('console.log')));
    });

    test('provider mode requires explicit live or fake', () {
      final factory = File(
        'supabase/functions/process-fuel-price-jobs/providers/factory.ts',
      ).readAsStringSync();
      expect(factory, contains('CARZON_FUEL_PRICE_PROVIDER_MODE'));
      expect(factory, isNot(contains('raw ?? "fake"')));
      expect(factory, isNot(contains("v === ''")));
    });
  });

  group('supabase/config.toml process-fuel-price-jobs', () {
    test('verify_jwt is false for worker function', () {
      final raw = File('supabase/config.toml').readAsStringSync();
      expect(raw, contains('[functions.process-fuel-price-jobs]'));
      final idx = raw.indexOf('[functions.process-fuel-price-jobs]');
      expect(idx, greaterThan(-1));
      final end = (idx + 120).clamp(0, raw.length);
      final tail = raw.substring(idx, end);
      expect(tail, contains('verify_jwt = false'));
    });
  });
}
