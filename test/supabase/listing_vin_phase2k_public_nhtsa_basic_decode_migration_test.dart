import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards for `20260628120000_vin_phase2k_public_nhtsa_basic_decode.sql`.
void main() {
  group('20260628120000_vin_phase2k_public_nhtsa_basic_decode.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260628120000_vin_phase2k_public_nhtsa_basic_decode.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'Phase 2K public NHTSA migration must exist',
      );
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('replaces complete_vin_decode_job_success', () {
      expect(
        lower,
        contains('create or replace function public.complete_vin_decode_job_success'),
      );
    });

    test('nhtsa insert uses public_summary visibility', () {
      expect(lower, contains('if p_provider_id = \'nhtsa_vpic\''));
      final idxInsert = lower.indexOf('insert into public.listing_vin_source_results');
      expect(idxInsert, greaterThan(-1));
      final chunk = lower.substring(idxInsert, idxInsert + 1200);
      expect(chunk, contains('\'public_summary\''));
      expect(chunk, isNot(contains("'owner'")));
    });

    test('backfill promotes only nhtsa_vpic basic_decode owner succeeded partial', () {
      expect(lower, contains('update public.listing_vin_source_results'));
      expect(lower, contains("source_id = 'nhtsa_vpic'"));
      expect(lower, contains("confidence = 'basic_decode'"));
      expect(lower, contains("visibility = 'owner'"));
      expect(lower, contains("visibility = 'public_summary'"));
      expect(lower, contains("status in ('succeeded', 'partial')"));
    });

    test('does not grant table privileges on listing_vin_source_results', () {
      expect(
        lower,
        isNot(contains('grant select on table public.listing_vin_source_results')),
      );
    });

    test('worker execute limited to service_role', () {
      expect(lower, contains('grant execute on function public.complete_vin_decode_job_success'));
      expect(lower, contains('to service_role'));
      expect(lower, contains('from anon'));
    });

    test('listing_vin_source_results insert lists no vin or vin_hash columns', () {
      final start = lower.indexOf('insert into public.listing_vin_source_results');
      expect(start, greaterThan(-1));
      final end = lower.indexOf('on conflict (listing_id, source_id)', start);
      expect(end, greaterThan(start));
      final block = lower.substring(start, end);
      expect(block, isNot(contains('vin_hash')));
      expect(block, isNot(contains('full_vin')));
    });
  });
}
