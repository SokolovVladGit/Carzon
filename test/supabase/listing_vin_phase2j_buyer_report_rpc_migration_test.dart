import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards for `20260627120000_vin_phase2j_buyer_report_rpc.sql`.
void main() {
  group('20260627120000_vin_phase2j_buyer_report_rpc.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260627120000_vin_phase2j_buyer_report_rpc.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'Phase 2J buyer report RPC migration must exist',
      );
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('defines get_listing_vin_report_for_buyer', () {
      expect(
        lower,
        contains(
          'create or replace function public.get_listing_vin_report_for_buyer',
        ),
      );
      expect(lower, contains('p_listing_id uuid'));
      expect(lower, contains('security definer'));
    });

    test('reads listing_vin_source_results and filters public_summary only', () {
      expect(lower, contains('from public.listing_vin_source_results'));
      expect(lower, contains("r.visibility = 'public_summary'"));
      expect(lower, isNot(contains("r.visibility in ('owner'")));
      expect(lower, isNot(contains("= 'owner'")));
    });

    test('restricts to active listings', () {
      expect(lower, contains('from public.listings li'));
      expect(lower, contains("li.status = 'active'"));
    });

    test('returns projection has no vin_hash vin_normalized owner_id source_metadata output', () {
      final start = lower.indexOf('returns table (');
      expect(start, greaterThan(-1));
      final end = lower.indexOf(')', start + 1);
      expect(end, greaterThan(start));
      final block = lower.substring(start, end);
      expect(block, isNot(contains('vin_hash')));
      expect(block, isNot(contains('owner_id')));
      expect(block, isNot(contains('source_metadata')));
    });

    test('return query does not select r.vin_hash or r.vin', () {
      expect(lower, isNot(contains('r.vin_hash')));
      expect(lower, isNot(contains('r.vin_normalized')));
    });

    test('grants execute to anon and authenticated', () {
      expect(lower, contains('grant execute on function public.get_listing_vin_report_for_buyer(uuid)'));
      expect(lower, contains('to anon, authenticated'));
    });

    test('does not grant select on listing_vin_source_results table', () {
      expect(lower, isNot(contains('grant select on table public.listing_vin_source_results')));
    });
  });
}
