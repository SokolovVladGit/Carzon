import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260703120000_chat_attachments_foundation.sql`.
void main() {
  group('20260703120000_chat_attachments_foundation.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260703120000_chat_attachments_foundation.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('creates private chat-attachments bucket', () {
      expect(lower, contains("'chat-attachments'"));
      expect(lower, contains('insert into storage.buckets'));
      expect(lower, contains('false'));
      expect(lower, isNot(contains('public = true')));
    });

    test('creates message_attachments with expected constraints', () {
      expect(lower, contains('create table if not exists public.message_attachments'));
      expect(lower, contains('message_attachments_message_id_uniq'));
      expect(lower, contains("storage_bucket = 'chat-attachments'"));
      expect(lower, contains("mime_type in ('image/jpeg', 'image/png')"));
      expect(lower, contains('size_bytes is null or size_bytes > 0'));
      expect(lower, contains('validate_message_attachment_conversation'));
    });

    test('enables participant-only RLS on message_attachments', () {
      expect(
        lower,
        contains(
          'alter table public.message_attachments enable row level security',
        ),
      );
      expect(lower, contains('message_attachments_participant_select'));
      expect(lower, contains('revoke insert, update, delete on public.message_attachments'));
      expect(lower, contains('grant select on table public.message_attachments'));
    });

    test('storage policies are participant/uploader scoped, not public read', () {
      expect(lower, contains('chat_attachments_participant_select'));
      expect(lower, contains('chat_attachments_uploader_insert'));
      expect(lower, contains('chat_attachments_uploader_delete'));
      expect(lower, isNot(contains('to anon')));
      expect(lower, isNot(contains('chat_attachments_public_read')));
      expect(
        lower,
        isNot(contains('using (bucket_id = \'chat-attachments\')')),
      );
    });

    test('relaxes messages.body safely and keeps send_message present', () {
      expect(lower, contains('alter column body drop not null'));
      expect(lower, contains('messages_body_length_chk'));
      expect(lower, contains('create or replace function public.send_message_with_attachment'));
      expect(
        lower,
        isNot(contains('drop function public.send_message')),
      );
    });

    test('preview trigger uses [photo] for empty/null body', () {
      final start = lower.indexOf(
        'create or replace function public.touch_conversation_from_message',
      );
      expect(start, greaterThan(-1));
      final end = lower.indexOf(
        'create or replace function public.send_message_with_attachment',
        start,
      );
      expect(end, greaterThan(start));
      final fn = lower.substring(start, end);
      expect(fn, contains('[photo]'));
      expect(fn, contains('left(v_body, 200)'));
    });

    test('send_message_with_attachment validates participant and path', () {
      final start = lower.indexOf(
        'create or replace function public.send_message_with_attachment',
      );
      expect(start, greaterThan(-1));
      final fn = lower.substring(start);
      expect(fn, contains('not a participant in this conversation'));
      expect(fn, contains('unsupported attachment mime type'));
      expect(fn, contains('conversations/<conversation_id>/<uploader_uid>/<filename>'));
      expect(fn, contains('insert into public.message_attachments'));
      expect(
        fn,
        contains(
          'grant execute on function public.send_message_with_attachment',
        ),
      );
      expect(fn, contains('to authenticated'));
    });

    test('participant model uses buyer_id and seller_id (support compatible)', () {
      expect(lower, contains('c.buyer_id = auth.uid()'));
      expect(lower, contains('c.seller_id = auth.uid()'));
    });
  });
}
