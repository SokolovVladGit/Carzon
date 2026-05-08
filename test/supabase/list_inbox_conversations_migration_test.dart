import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260520120000_list_inbox_conversations_rpc.sql`.
void main() {
  group('20260520120000_list_inbox_conversations_rpc.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260520120000_list_inbox_conversations_rpc.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('defines security definer list_inbox_conversations with has_unread', () {
      final lower = sql.toLowerCase();
      expect(
        lower.contains('create or replace function public.list_inbox_conversations'),
        isTrue,
      );
      expect(lower.contains('has_unread boolean'), isTrue);
      expect(lower.contains('security definer'), isTrue);
    });

    test('unread predicate aligns with inbound-after-read semantics', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('m.sender_id is distinct from auth.uid()'), isTrue);
      expect(
        lower.contains('coalesce(') &&
            lower.contains('ucs.last_read_at') &&
            lower.contains("'-infinity'::timestamptz"),
        isTrue,
      );
      expect(lower.contains('from public.messages m'), isTrue);
    });

    test('participant scope and authenticated execute grant', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('c.buyer_id = auth.uid()'), isTrue);
      expect(lower.contains('c.seller_id = auth.uid()'), isTrue);
      expect(lower.contains('ucs.user_id = auth.uid()'), isTrue);
      expect(
        lower.contains(
          'grant execute on function public.list_inbox_conversations() to authenticated',
        ),
        isTrue,
      );
      expect(lower.contains('not authenticated'), isTrue);
      expect(
        lower.contains('revoke all on function public.list_inbox_conversations() from public'),
        isTrue,
      );
      expect(
        lower.contains('revoke all on function public.list_inbox_conversations() from anon'),
        isTrue,
      );
    });

    test('search_path locked to public without pg_temp append', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('set search_path = public'), isTrue);
      expect(lower.contains('pg_temp'), isFalse);
    });

    test('listing json allowlist omits seller/contact/internal columns', () {
      final body = sql.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
      expect(body.contains("jsonb_build_object("), isTrue);
      expect(body.contains("'title', l.title"), isTrue);
      expect(body.contains("'seller_id'"), isFalse);
      expect(body.contains("'status'"), isFalse);
      expect(body.contains("'mileage_km'"), isFalse);
      expect(body.contains("'created_at'"), isFalse);
    });

    test('migration does not alter RLS, policies, or grant table DML', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('create policy'), isFalse);
      expect(lower.contains('alter table'), isFalse);
      expect(lower.contains('enable row level security'), isFalse);
      expect(lower.contains('grant insert'), isFalse);
      expect(lower.contains('grant update'), isFalse);
      expect(lower.contains('grant delete'), isFalse);
      expect(lower.contains('grant select on'), isFalse);
    });
  });
}
