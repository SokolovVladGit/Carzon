import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260523120000_filter_alert_settings.sql`.
void main() {
  group('20260523120000_filter_alert_settings.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260523120000_filter_alert_settings.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('does not reference experimental saved_searches table teardown', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('saved_searches'), isFalse);
    });

    test('creates filter_alert_settings with expected shape', () {
      final lower = sql.toLowerCase();
      expect(
        lower.contains(
          'create table if not exists public.filter_alert_settings',
        ),
        isTrue,
      );
      expect(
        lower.contains(
          'user_id                 uuid primary key references auth.users (id)',
        ),
        isTrue,
      );
      expect(lower.contains('criteria                jsonb'), isTrue);
      expect(
        lower.contains(
          'notifications_enabled   boolean not null default false',
        ),
        isTrue,
      );
      expect(lower.contains('created_at              timestamptz'), isTrue);
      expect(lower.contains('updated_at              timestamptz'), isTrue);
    });

    test('defines updated_at trigger consistent with migrations', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('touch_filter_alert_settings_updated_at'), isTrue);
      expect(
        lower.contains('before update on public.filter_alert_settings'),
        isTrue,
      );
    });

    test('enables RLS and authenticated-scoped CRUD policies', () {
      final lower = sql.toLowerCase();
      expect(
        lower.contains(
          'alter table public.filter_alert_settings enable row level security',
        ),
        isTrue,
      );
      expect(lower.contains('filter_alert_settings_select_own'), isTrue);
      expect(lower.contains('filter_alert_settings_insert_own'), isTrue);
      expect(lower.contains('filter_alert_settings_update_own'), isTrue);
      expect(lower.contains('filter_alert_settings_delete_own'), isTrue);
      expect(sql, contains('(select auth.uid())'));
      expect(
        lower.contains(
          'grant select, insert, update, delete on public.filter_alert_settings to authenticated',
        ),
        isTrue,
      );
    });
  });
}
