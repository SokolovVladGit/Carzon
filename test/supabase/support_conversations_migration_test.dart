import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260702120000_support_conversations.sql`.
void main() {
  group('20260702120000_support_conversations.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260702120000_support_conversations.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('adds conversation_kind and nullable listing_id constraints', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('conversation_kind'), isTrue);
      expect(lower.contains('alter column listing_id drop not null'), isTrue);
      expect(lower.contains("conversation_kind = 'listing'"), isTrue);
      expect(lower.contains("conversation_kind = 'support'"), isTrue);
      expect(lower.contains('conversations_support_buyer_uniq'), isTrue);
    });

    test('defines get_or_create_support_conversation with admin email', () {
      final lower = sql.toLowerCase();
      expect(
        lower.contains(
          'create or replace function public.get_or_create_support_conversation',
        ),
        isTrue,
      );
      expect(lower.contains('admin@carzon.com'), isTrue);
      expect(
        lower.contains(
          'grant execute on function public.get_or_create_support_conversation() to authenticated',
        ),
        isTrue,
      );
      expect(lower.contains('support account is not configured'), isTrue);
    });

    test('list_inbox_conversations includes kind and left join listings', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('c.conversation_kind'), isTrue);
      expect(lower.contains('left join public.listings l'), isTrue);
    });

    test(
      'list_inbox_conversations is dropped before create to avoid return-type failure',
      () {
        final lower = sql.toLowerCase();
        final dropIndex = lower.indexOf(
          'drop function if exists public.list_inbox_conversations()',
        );
        final createIndex = lower.indexOf(
          'create function public.list_inbox_conversations()',
        );

        expect(dropIndex, greaterThanOrEqualTo(0));
        expect(createIndex, greaterThan(dropIndex));
        expect(
          lower.contains(
            'create or replace function public.list_inbox_conversations',
          ),
          isFalse,
        );
      },
    );
  });
}
