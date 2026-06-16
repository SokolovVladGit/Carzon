import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260710120000_model_fetch_vin_identity_hints.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final file = File(
        'supabase/migrations/20260710120000_model_fetch_vin_identity_hints.sql',
      );
      expect(file.existsSync(), isTrue);
      sql = file.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('adds optional listing_id to vehicle_model_fetch_jobs', () {
      expect(lower, contains('alter table public.vehicle_model_fetch_jobs'));
      expect(lower, contains('listing_id uuid'));
    });

    test('defines service-role VIN hints RPC with allowlisted fields only', () {
      expect(lower, contains('get_listing_vin_model_fetch_hints'));
      expect(lower, contains("'body_type'"));
      expect(lower, contains("'drive_type'"));
      expect(lower, contains("visibility = 'public_summary'"));
      expect(lower, isNot(contains('vin_normalized')));
      expect(lower, isNot(contains('vin_hash')));
      expect(lower, contains('grant execute on function public.get_listing_vin_model_fetch_hints(uuid)'));
      expect(lower, contains('to service_role'));
    });

    test('drops old enqueue overload before adding listing_id parameter', () {
      final enqueueDrop = lower.indexOf(
        'drop function if exists public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text)',
      );
      final enqueueCreate = lower.indexOf(
        'create or replace function public.enqueue_vehicle_model_fetch_if_needed(',
      );
      expect(enqueueDrop, greaterThan(-1));
      expect(enqueueCreate, greaterThan(enqueueDrop));
      expect(
        lower,
        contains(
          'enqueue_vehicle_model_fetch_if_needed(text, text, integer, text, uuid)',
        ),
      );
      expect(lower, contains('p_listing_id uuid default null'));
    });

    test(
      'drops claim function before redefining return type with listing_id',
      () {
        final claimDrop = lower.indexOf(
          'drop function if exists public.claim_vehicle_model_fetch_jobs_for_processing(integer)',
        );
        final claimCreate = lower.indexOf(
          'create or replace function public.claim_vehicle_model_fetch_jobs_for_processing(',
        );
        expect(claimDrop, greaterThan(-1));
        expect(claimCreate, greaterThan(claimDrop));
        expect(lower, contains('listing_id uuid'));
        expect(
          lower,
          contains(
            'grant execute on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)',
          ),
        );
        expect(lower, contains('to service_role'));
      },
    );

    test('buyer RPC passes listing id into enqueue without exposing hints', () {
      final start = lower.indexOf(
        'create or replace function public.get_listing_model_data_for_buyer',
      );
      final end = lower.indexOf(
        'comment on function public.get_listing_model_data_for_buyer',
        start,
      );
      expect(start, greaterThan(-1));
      expect(end, greaterThan(start));
      final buyerBlock = lower.substring(start, end);
      expect(buyerBlock, contains('p_listing_id'));
      expect(buyerBlock, isNot(contains('get_listing_vin_model_fetch_hints')));
      expect(buyerBlock, isNot(contains('identity_candidate_source')));
    });
  });
}
