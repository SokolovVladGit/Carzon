import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260518100000_user_conversation_state.sql`.
void main() {
  group('20260518100000_user_conversation_state.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260518100000_user_conversation_state.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('creates user_conversation_state with expected columns and PK', () {
      final lower = sql.toLowerCase();
      expect(
        lower.contains(
          'create table if not exists public.user_conversation_state',
        ),
        isTrue,
      );
      expect(lower.contains('user_id uuid'), isTrue);
      expect(lower.contains('conversation_id uuid'), isTrue);
      expect(lower.contains('last_read_at timestamptz'), isTrue);
      expect(lower.contains('muted boolean'), isTrue);
      expect(lower.contains('user_conversation_state_pkey'), isTrue);
      expect(lower.contains('primary key (user_id, conversation_id)'), isTrue);
    });

    test('RLS enabled; direct writes revoked for client roles', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('enable row level security'), isTrue);
      expect(
        lower.contains(
          'revoke insert, update, delete on public.user_conversation_state from authenticated',
        ),
        isTrue,
      );
    });

    test('defines participant-scoped select policy', () {
      final lower = sql.toLowerCase();
      expect(
        lower.contains('user_conversation_state_participant_select'),
        isTrue,
      );
      expect(lower.contains('c.buyer_id = auth.uid()'), isTrue);
      expect(lower.contains('c.seller_id = auth.uid()'), isTrue);
    });

    test(
      'mark_conversation_read is security definer and granted to authenticated',
      () {
        final lower = sql.toLowerCase();
        expect(
          lower.contains(
            'create or replace function public.mark_conversation_read',
          ),
          isTrue,
        );
        expect(lower.contains('security definer'), isTrue);
        expect(
          lower.contains(
            'grant execute on function public.mark_conversation_read(uuid) to authenticated',
          ),
          isTrue,
        );
        expect(lower.contains('not a participant'), isTrue);
      },
    );

    test(
      'get_unread_conversation_count is security definer and counts distinct conversations',
      () {
        final lower = sql.toLowerCase();
        expect(
          lower.contains(
            'create or replace function public.get_unread_conversation_count',
          ),
          isTrue,
        );
        expect(lower.contains('count(distinct m.conversation_id)'), isTrue);
        expect(lower.contains('m.sender_id is distinct from v_uid'), isTrue);
        expect(lower.contains("'-infinity'::timestamptz"), isTrue);
        expect(
          lower.contains(
            'grant execute on function public.get_unread_conversation_count() to authenticated',
          ),
          isTrue,
        );
      },
    );
  });
}
