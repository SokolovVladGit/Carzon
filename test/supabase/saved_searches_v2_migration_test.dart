import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static audit for P1 M1.4 Phase A saved searches v2 migration.
///
/// Does not execute Postgres or apply hosted SQL.
void main() {
  group('20260801120000_saved_searches_table_and_backfill.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260801120000_saved_searches_table_and_backfill.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'migration file must exist');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('creates saved_searches with required columns', () {
      expect(
        lower,
        contains('create table if not exists public.saved_searches'),
      );
      expect(lower, contains('id                  uuid primary key'));
      expect(
        lower,
        contains('user_id             uuid not null references auth.users'),
      );
      expect(lower, contains('name                text not null'));
      expect(lower, contains('criteria            jsonb not null'));
      expect(
        lower,
        contains('alerts_enabled      boolean not null default false'),
      );
      expect(lower, contains('created_at          timestamptz'));
      expect(lower, contains('updated_at          timestamptz'));
      expect(lower, contains('last_notified_at    timestamptz null'));
    });

    test('name and criteria constraints exist', () {
      expect(lower, contains('saved_searches_name_nonempty_chk'));
      expect(lower, contains('saved_searches_name_max_len_chk'));
      expect(lower, contains('saved_searches_criteria_is_object_chk'));
      expect(lower, contains("jsonb_typeof(criteria) = 'object'"));
    });

    test('indexes for list and enqueue paths', () {
      expect(lower, contains('saved_searches_user_id_updated_at_idx'));
      expect(lower, contains('saved_searches_user_id_alerts_enabled_idx'));
      expect(lower, contains('saved_searches_user_criteria_uniq_idx'));
    });

    test('updated_at trigger exists', () {
      expect(lower, contains('touch_saved_searches_updated_at'));
      expect(lower, contains('saved_searches_touch_updated_at'));
      expect(lower, contains('before update on public.saved_searches'));
    });

    test('enables RLS with own-row policies', () {
      expect(
        lower,
        contains('alter table public.saved_searches enable row level security'),
      );
      expect(lower, contains('saved_searches_select_own'));
      expect(lower, contains('saved_searches_insert_own'));
      expect(lower, contains('saved_searches_update_own'));
      expect(lower, contains('saved_searches_delete_own'));
      expect(sql, contains('(select auth.uid())'));
    });

    test('restricts table grants — select only for authenticated', () {
      expect(lower, contains('revoke all on table public.saved_searches from public'));
      expect(
        lower,
        contains(
          'revoke insert, update, delete on table public.saved_searches from authenticated',
        ),
      );
      expect(
        lower,
        contains('grant select on table public.saved_searches to authenticated'),
      );
    });

    test('backfills from filter_alert_settings without dropping v1 table', () {
      expect(lower, contains('from public.filter_alert_settings fas'));
      expect(lower, contains('insert into public.saved_searches'));
      expect(lower, contains('fas.notifications_enabled'));
      expect(lower, contains('not exists'));
      expect(lower, isNot(contains('drop table public.filter_alert_settings')));
      expect(lower, isNot(contains('drop table if exists public.filter_alert_settings')));
    });

    test('max 5 guard via RPC and insert trigger', () {
      expect(lower, contains('max_saved_searches_reached'));
      expect(lower, contains('enforce_saved_searches_max_per_user'));
      expect(lower, contains('saved_searches_enforce_max_per_user_ins'));
      expect(lower, contains('if v_count >= 5'));
    });

    test('duplicate criteria guard uses exact jsonb equality', () {
      expect(lower, contains('duplicate_saved_search'));
      expect(lower, contains('ss.criteria = v_criteria'));
      expect(lower, contains('saved_searches_user_criteria_uniq_idx'));
    });

    group('RPCs', () {
      test('list_my_saved_searches', () {
        expect(
          lower,
          contains('create or replace function public.list_my_saved_searches'),
        );
        expect(lower, contains('returns setof public.saved_searches'));
        expect(lower, contains('auth.uid()'));
        expect(lower, contains('security definer'));
        expect(lower, contains('set search_path = public, pg_temp'));
        expect(
          lower,
          contains('grant execute on function public.list_my_saved_searches()'),
        );
      });

      test('create_saved_search', () {
        expect(
          lower,
          contains('create or replace function public.create_saved_search'),
        );
        expect(lower, contains('p_name text'));
        expect(lower, contains('p_criteria jsonb'));
        expect(lower, contains('p_alerts_enabled boolean default true'));
        expect(lower, contains('user_id = v_uid'));
        expect(lower, isNot(contains('p_user_id')));
        expect(
          lower,
          contains(
            'grant execute on function public.create_saved_search(text, jsonb, boolean)',
          ),
        );
      });

      test('update_saved_search', () {
        expect(
          lower,
          contains('create or replace function public.update_saved_search'),
        );
        expect(lower, contains('p_id uuid'));
        expect(lower, contains('ss.user_id = v_uid'));
        expect(
          lower,
          contains(
            'grant execute on function public.update_saved_search(uuid, text, jsonb, boolean)',
          ),
        );
      });

      test('delete_saved_search', () {
        expect(
          lower,
          contains('create or replace function public.delete_saved_search'),
        );
        expect(lower, contains('returns boolean'));
        expect(
          lower,
          contains('grant execute on function public.delete_saved_search(uuid)'),
        );
      });

      test('set_saved_search_alerts_enabled', () {
        expect(
          lower,
          contains(
            'create or replace function public.set_saved_search_alerts_enabled',
          ),
        );
        expect(
          lower,
          contains(
            'grant execute on function public.set_saved_search_alerts_enabled(uuid, boolean)',
          ),
        );
      });

      test('RPCs revoke anon/public execute', () {
        expect(lower, contains('revoke all on function public.list_my_saved_searches() from anon'));
        expect(lower, contains('revoke all on function public.create_saved_search(text, jsonb, boolean) from anon'));
      });
    });

    test('enqueue scans saved_searches not filter_alert_settings', () {
      final enqueueStart = lower.indexOf(
        'create or replace function public.enqueue_filter_alert_notification_events_for_listing',
      );
      expect(enqueueStart, greaterThan(-1));
      final enqueueSql = lower.substring(enqueueStart);

      expect(enqueueSql, contains('from public.saved_searches ss'));
      expect(enqueueSql, contains('ss.alerts_enabled = true'));
      expect(enqueueSql, isNot(contains('from public.filter_alert_settings fas')));
      expect(
        enqueueSql,
        contains('public.listing_matches_saved_discovery_criteria(r, ss.criteria)'),
      );
    });

    test('notification dedupe and safe payload preserved', () {
      expect(lower, contains("'filter_alert_listing_match'"));
      expect(
        lower,
        contains('on conflict (recipient_user_id, listing_id)'),
      );
      expect(
        lower,
        contains("where (event_type = 'filter_alert_listing_match')"),
      );
      expect(lower, contains("jsonb_build_object('listing_id', r.id)"));
      expect(lower, isNot(contains("'criteria'")));
      expect(lower, isNot(contains('vin_hash')));
      expect(lower, isNot(contains('source_metadata')));
      expect(lower, isNot(contains("'saved_search_id'")));
    });

    test('enqueue remains internal — not granted to authenticated', () {
      expect(
        lower,
        contains(
          'revoke all on function public.enqueue_filter_alert_notification_events_for_listing(uuid)',
        ),
      );
      expect(lower, contains('from authenticated'));
    });

    test('does not expose VIN or official-data fields', () {
      expect(lower, isNot(contains('vin')));
      expect(lower, isNot(contains('recall')));
      expect(lower, isNot(contains('model_passport')));
    });
  });
}
