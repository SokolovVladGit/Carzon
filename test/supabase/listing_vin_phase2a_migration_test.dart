import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260618120000_vin_phase2a_processing_foundation.sql`.
void main() {
  group('20260618120000_vin_phase2a_processing_foundation.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260618120000_vin_phase2a_processing_foundation.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'VIN Phase 2A migration must exist');
      sql = f.readAsStringSync();
    });

    test('does not alter public.listings or expand vin_status', () {
      expect(
        sql.toLowerCase(),
        isNot(contains('alter table public.listings')),
        reason:
            'Phase 2A must not touch listings.vin_status or listings columns.',
      );
    });

    test('does not add a plaintext vin column to public.listings', () {
      final listingAlter = RegExp(
        r'alter\s+table\s+public\.listings\b[\s\S]*?;',
        caseSensitive: false,
      );
      final standaloneVinCol = RegExp(
        r'\badd\s+column\b[\s\S]{0,220}?\bvin\b(?![a-z0-9_])',
        caseSensitive: false,
      );
      for (final m in listingAlter.allMatches(sql)) {
        final stmt = m.group(0)!;
        if (!stmt.toLowerCase().contains('add column')) continue;
        expect(
          standaloneVinCol.hasMatch(stmt),
          isFalse,
          reason:
              'public.listings must not gain a plaintext vin column (vin_status only).',
        );
      }
    });

    test('defines private Phase 2A tables', () {
      final lower = sql.toLowerCase();
      expect(lower, contains('create table'));
      expect(lower, contains('public.vin_processing_jobs'));
      expect(lower, contains('public.vin_decode_cache'));
      expect(lower, contains('public.listing_vin_report_snapshot'));
    });

    test('enables RLS on new private tables', () {
      final lower = sql.toLowerCase();
      expect(
        lower,
        contains(
          'alter table public.vin_processing_jobs enable row level security',
        ),
      );
      expect(
        lower,
        contains(
          'alter table public.vin_decode_cache enable row level security',
        ),
      );
      expect(
        lower,
        contains(
          'alter table public.listing_vin_report_snapshot enable row level security',
        ),
      );
    });

    test('revokes anon/authenticated grants on private tables', () {
      final lower = sql.toLowerCase();
      for (final t in [
        'vin_processing_jobs',
        'vin_decode_cache',
        'listing_vin_report_snapshot',
      ]) {
        expect(
          lower,
          contains('revoke all on table public.$t'),
          reason: 'Revoke client roles from public.$t.',
        );
        expect(lower, contains('from anon'));
        expect(lower, contains('from authenticated'));
      }
    });

    test('defines listing_vehicle_identity triggers for enqueue/cleanup', () {
      final lower = sql.toLowerCase();
      expect(
        lower,
        contains(
          'after insert or update of vin_hash on public.listing_vehicle_identity',
        ),
      );
      expect(lower, contains('after delete on public.listing_vehicle_identity'));
      expect(lower, contains('carzon_after_listing_vehicle_identity_vin_hash_change'));
      expect(lower, contains('carzon_after_listing_vehicle_identity_deleted'));
    });

    test(
      'defines get_my_listing_vin_report_status granted to authenticated only',
      () {
        expect(sql.toLowerCase(), contains('get_my_listing_vin_report_status'));
        expect(
          sql.toLowerCase(),
          contains(
            'grant execute on function public.get_my_listing_vin_report_status(uuid)',
          ),
        );
        expect(
          sql.toLowerCase(),
          contains(
            'revoke all on function public.get_my_listing_vin_report_status(uuid) from anon',
          ),
        );
      },
    );

    test('revokes internal enqueue/trigger helpers from clients', () {
      final lower = sql.toLowerCase();
      expect(
        lower,
        contains(
          'revoke all on function public.carzon_enqueue_vin_decode_from_identity(uuid, uuid, text)',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.carzon_after_listing_vehicle_identity_vin_hash_change()',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.carzon_after_listing_vehicle_identity_deleted()',
        ),
      );
    });

    test('does not introduce HTTP / pg_net provider calls', () {
      final lower = sql.toLowerCase();
      expect(lower, isNot(contains('pg_net')));
      expect(lower, isNot(contains('net.http')));
      expect(lower, isNot(contains('http://')));
      expect(lower, isNot(contains('https://')));
    });

    test('RPC definition omits vin_hash and vin_normalized from return shape', () {
      final sigStart = sql.toLowerCase().indexOf(
            'get_my_listing_vin_report_status(p_listing_id uuid)',
          );
      expect(sigStart, greaterThan(-1));
      final chunk = sql.toLowerCase().substring(sigStart, sigStart + 900);
      expect(chunk.contains('vin_hash'), isFalse);
      expect(chunk.contains('vin_normalized'), isFalse);
    });
  });
}
