import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for `20260527120000_notification_preferences_and_push_tokens.sql`.
///
/// Does not execute Postgres or prove hosted Supabase parity.
void main() {
  group('20260527120000_notification_preferences_and_push_tokens.sql', () {
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260527120000_notification_preferences_and_push_tokens.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'notification foundation migration exists');
      lower = f.readAsStringSync().toLowerCase();
    });

    test('creates notification_preferences and user_push_tokens', () {
      expect(lower, contains('create table if not exists public.notification_preferences'));
      expect(lower, contains('create table if not exists public.user_push_tokens'));
      expect(lower, contains('global_enabled'));
      expect(lower, contains('messages_enabled'));
      expect(lower, contains('filter_alerts_enabled'));
      expect(lower, contains('user_push_tokens_platform_chk'));
    });

    test('enables RLS on both tables', () {
      expect(lower, contains('alter table public.notification_preferences enable row level security'));
      expect(lower, contains('alter table public.user_push_tokens enable row level security'));
    });

    test('grants select to authenticated only (no anon)', () {
      expect(lower, contains('grant select on table public.notification_preferences to authenticated'));
      expect(lower, contains('grant select on table public.user_push_tokens to authenticated'));
      expect(lower, isNot(contains('grant select on table public.notification_preferences to anon')));
    });

    test('defines RPCs with authenticated execute only', () {
      expect(lower, contains('get_my_notification_preferences'));
      expect(lower, contains('update_my_notification_preferences'));
      expect(lower, contains('register_push_token'));
      expect(lower, contains('deactivate_push_token'));
      expect(lower, contains('deactivate_my_push_tokens'));
      expect(lower, contains('grant execute on function public.get_my_notification_preferences()'));
      expect(lower, contains('revoke all on function public.get_my_notification_preferences()'));
    });

    test('migration text does not reference service_role for Flutter', () {
      expect(lower, isNot(contains('service_role')));
    });
  });
}
