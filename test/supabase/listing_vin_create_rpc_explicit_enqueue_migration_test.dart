import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260708120000_vin_create_rpc_explicit_enqueue.sql`.
void main() {
  group('20260708120000_vin_create_rpc_explicit_enqueue.sql', () {
    late String sql;
    late String lower;
    late String createBody;
    late String updateBody;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260708120000_vin_create_rpc_explicit_enqueue.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'VIN enqueue migration must exist');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();

      final createParts = sql.split('create function public.create_listing_v2(');
      expect(createParts.length, greaterThan(1));
      createBody = createParts[1].split(r'$$')[1];

      final updateParts = sql.split(
        'create function public.update_listing_details_v2(',
      );
      expect(updateParts.length, greaterThan(1));
      updateBody = updateParts[1].split(r'$$')[1];
    });

    test('recreates create_listing_v2 and update_listing_details_v2 only', () {
      expect(lower, contains('create function public.create_listing_v2('));
      expect(lower, contains('create function public.update_listing_details_v2('));
      expect(lower, isNot(contains('alter table public.listings')));
    });

    test('create_listing_v2 enqueues decode after identity insert', () {
      expect(
        createBody,
        contains('insert into public.listing_vehicle_identity'),
      );
      expect(
        createBody.indexOf('insert into public.listing_vehicle_identity'),
        lessThan(createBody.indexOf('carzon_enqueue_vin_decode_from_identity')),
      );
      expect(createBody, contains('if v_vin_norm is not null then'));
      expect(
        createBody,
        contains(
          'perform public.carzon_enqueue_vin_decode_from_identity(\n'
          '            v_row.id,\n'
          '            auth.uid(),\n'
          '            v_vin_hash\n'
          '        );',
        ),
      );
    });

    test('update_listing_details_v2 enqueues decode after identity upsert', () {
      expect(
        updateBody,
        contains('on conflict (listing_id) do update'),
      );
      expect(
        updateBody.indexOf('on conflict (listing_id) do update'),
        lessThan(
          updateBody.indexOf('carzon_enqueue_vin_decode_from_identity'),
        ),
      );
      expect(
        updateBody,
        contains(
          'perform public.carzon_enqueue_vin_decode_from_identity(\n'
          '                p_listing_id,\n'
          '                auth.uid(),\n'
          '                v_vin_hash\n'
          '            );',
        ),
      );
    });

    test('invalid VIN still rejected before listing insert', () {
      expect(
        createBody.indexOf("raise exception 'invalid vin'"),
        lessThan(createBody.indexOf('insert into public.listings')),
      );
      expect(
        updateBody.indexOf("raise exception 'invalid vin'"),
        lessThan(updateBody.indexOf('update public.listings')),
      );
    });

    test('enqueue uses vin_hash only (no plaintext VIN in perform args)', () {
      final performBlocks = RegExp(
        r'perform public\.carzon_enqueue_vin_decode_from_identity\([\s\S]*?\);',
      ).allMatches(createBody + updateBody);
      expect(performBlocks.length, 2);
      for (final m in performBlocks) {
        final block = m.group(0)!;
        expect(block.contains('v_vin_norm'), isFalse);
        expect(block.contains('p_vin'), isFalse);
        expect(block.contains('v_vin_hash'), isTrue);
      }
    });

    test('idempotent enqueue helper referenced (not client requeue RPC)', () {
      expect(lower, contains('carzon_enqueue_vin_decode_from_identity'));
      expect(lower, isNot(contains('requeue_vin_decode_job_for_listing')));
    });

    test('backfill covers identities missing snapshot only', () {
      expect(lower, contains('left join public.listing_vin_report_snapshot'));
      expect(lower, contains('where s.listing_id is null'));
      expect(
        lower,
        contains(
          'perform public.carzon_enqueue_vin_decode_from_identity(',
        ),
      );
    });

    test('does not change get_listing_vin_report_for_buyer', () {
      expect(lower, isNot(contains('get_listing_vin_report_for_buyer')));
    });

    test('preserves authenticated grants on listing RPCs', () {
      expect(
        lower,
        contains(
          'grant execute on function public.create_listing_v2(\n'
          '    text, text, text, integer, numeric, integer,\n'
          '    text, text, text, text, text, boolean,\n'
          '    text, text, text[], text[], text,\n'
          '    text, numeric, integer, text, text, text,\n'
          '    text\n'
          ') to authenticated;',
        ),
      );
      expect(
        lower,
        contains(
          'grant execute on function public.update_listing_details_v2(\n'
          '    uuid, text, text, text, integer, numeric, text, integer,\n'
          '    text, text, text, text, text, boolean, text,\n'
          '    text, numeric, integer, text, text, text,\n'
          '    text\n'
          ') to authenticated;',
        ),
      );
    });
  });
}
