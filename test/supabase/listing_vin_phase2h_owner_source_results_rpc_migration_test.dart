import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards for `20260626120000_vin_phase2h_owner_source_results_rpc.sql`.
void main() {
  group('20260626120000_vin_phase2h_owner_source_results_rpc.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260626120000_vin_phase2h_owner_source_results_rpc.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'Phase 2H owner source-results RPC migration must exist',
      );
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('defines owner-only get_my_listing_vin_source_results', () {
      expect(
        lower,
        contains(
          'create or replace function public.get_my_listing_vin_source_results',
        ),
      );
      expect(lower, contains('security definer'));
      expect(lower, contains('p_listing_id uuid'));
    });

    test('requires auth and listing ownership via seller_id = auth.uid()', () {
      expect(lower, contains('auth.uid() is null'));
      expect(lower, contains('not authenticated'));
      expect(lower, contains('public.listings li'));
      expect(lower, contains('li.seller_id = auth.uid()'));
      expect(lower, contains('listing not found or not owned by caller'));
    });

    test('filters out internal visibility rows', () {
      expect(lower, contains("r.visibility in ('owner', 'public_summary')"));
      expect(lower, isNot(contains("r.visibility in ('internal'")));
      expect(lower, isNot(contains("= 'internal'")));
    });

    test('returns projection excludes VIN, vin_hash, owner_id, raw source_metadata', () {
      final returnsBlockStart = lower.indexOf('returns table (');
      expect(returnsBlockStart, greaterThan(-1));
      final returnsBlockEnd = lower.indexOf(')', returnsBlockStart + 1);
      expect(returnsBlockEnd, greaterThan(returnsBlockStart));
      final returnsBlock = lower.substring(returnsBlockStart, returnsBlockEnd);
      expect(returnsBlock, isNot(contains('vin')));
      expect(returnsBlock, isNot(contains('vin_hash')));
      expect(returnsBlock, isNot(contains('owner_id')));
      expect(returnsBlock, isNot(contains('source_metadata')));
    });

    test('return query selects only safe columns (no vin_hash / full vin columns)', () {
      expect(lower, contains('from public.listing_vin_source_results r'));
      expect(lower, isNot(contains('r.vin')));
      expect(lower, isNot(contains('r.vin_hash')));
      expect(lower, isNot(contains('r.owner_id')));
      expect(lower, isNot(contains('r.raw')));
    });

    test('maps NHTSA vPIC source_label and allowlisted provider_version', () {
      expect(lower, contains("when 'nhtsa_vpic' then 'nhtsa vpic'"));
      expect(lower, contains("r.source_id = 'nhtsa_vpic'"));
      expect(lower, contains("r.source_metadata->>'provider_version'"));
    });

    test('revokes public/anon and grants execute to authenticated only', () {
      expect(
        lower,
        contains(
          'revoke all on function public.get_my_listing_vin_source_results(uuid) from public',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.get_my_listing_vin_source_results(uuid) from anon',
        ),
      );
      expect(
        lower,
        contains('grant execute on function public.get_my_listing_vin_source_results(uuid)'),
      );
      expect(lower, contains('to authenticated'));
      expect(
        lower,
        isNot(
          RegExp(
            r'grant\s+execute\s+on\s+function\s+public\.get_my_listing_vin_source_results\s*\(\s*uuid\s*\)\s+to\s+anon\b',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('listing_vin_source_results stays without client table grants', () {
      expect(lower, isNot(contains('grant select on table public.listing_vin_source_results')));
    });
  });
}
