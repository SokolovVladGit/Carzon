import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260620120000_vin_phase2c_provider_foundation.sql`.
void main() {
  group('20260620120000_vin_phase2c_provider_foundation.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260620120000_vin_phase2c_provider_foundation.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'Phase 2C provider migration must exist',
      );
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('does not alter public.listings or vin_status', () {
      expect(lower, isNot(contains('alter table public.listings')));
    });

    test('defines get_vin_for_decode_job joining listing_vehicle_identity', () {
      expect(lower, contains('get_vin_for_decode_job'));
      expect(lower, contains('listing_vehicle_identity'));
      expect(lower, contains('vin_processing_jobs'));
      expect(lower, contains("j.status = 'processing'"));
      expect(lower, contains("j.job_type = 'decode'"));
      expect(lower, contains('i.vin_hash = j.vin_hash'));
      expect(lower, contains('i.vin_normalized'));
    });

    test('get_vin_for_decode_job RETURNS TABLE lists only vin_normalized', () {
      expect(
        RegExp(
          r'create\s+or\s+replace\s+function\s+public\.get_vin_for_decode_job\b[\s\S]*?returns\s+table\s*\(\s*vin_normalized\s+text\s*\)',
          caseSensitive: false,
        ).hasMatch(sql),
        isTrue,
      );
    });

    test('get_vin_for_decode_job is service_role-only', () {
      expect(
        lower,
        contains(
          'grant execute on function public.get_vin_for_decode_job(uuid)',
        ),
      );
      expect(lower, contains('to service_role'));
      expect(
        lower,
        contains('revoke all on function public.get_vin_for_decode_job(uuid)'),
      );
      expect(lower, contains('from anon'));
      expect(lower, contains('from authenticated'));
    });

    test('defines requeue_vin_decode_job_for_listing service_role-only', () {
      expect(lower, contains('requeue_vin_decode_job_for_listing'));
      expect(
        lower,
        contains(
          'grant execute on function public.requeue_vin_decode_job_for_listing',
        ),
      );
      expect(lower, contains(':decode:'));
      expect(lower, contains('p_job_version'));
    });

    test('SECURITY DEFINER + search_path for new RPCs', () {
      expect(lower, contains('security definer'));
      expect(lower, contains('set search_path = public, pg_temp'));
    });

    test('no HTTP secrets or provider URLs in SQL', () {
      expect(lower, isNot(contains('http://')));
      expect(lower, isNot(contains('https://')));
    });
  });
}
