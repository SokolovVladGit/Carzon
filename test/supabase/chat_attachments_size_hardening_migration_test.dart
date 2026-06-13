import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260704120000_chat_attachments_size_hardening.sql`.
void main() {
  group('20260704120000_chat_attachments_size_hardening.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260704120000_chat_attachments_size_hardening.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('sets chat-attachments bucket to 10 MiB and jpeg/png MIME allowlist', () {
      expect(lower, contains("where id = 'chat-attachments'"));
      expect(lower, contains('10485760'));
      expect(lower, contains('file_size_limit'));
      expect(lower, contains('allowed_mime_types'));
      expect(lower, contains("'image/jpeg'"));
      expect(lower, contains("'image/png'"));
    });

    test('tightens message_attachments size_bytes constraint and requires NOT NULL', () {
      expect(lower, contains('alter column size_bytes set not null'));
      expect(lower, contains('message_attachments_size_bytes_chk'));
      expect(lower, contains('size_bytes > 0 and size_bytes <= 10485760'));
    });

    test('send_message_with_attachment requires size and rejects invalid bounds', () {
      final start = lower.indexOf(
        'create or replace function public.send_message_with_attachment',
      );
      expect(start, greaterThan(-1));
      final fn = lower.substring(start);
      expect(fn, contains('attachment size is required'));
      expect(fn, contains('attachment size must be positive'));
      expect(fn, contains('attachment size exceeds limit'));
      expect(fn, contains('v_max_bytes    constant bigint := 10485760'));
      expect(fn, contains('p_size_bytes      bigint,'));
      expect(fn, isNot(contains('p_size_bytes      bigint default null')));
    });

    test('drops prior RPC signature before recreate', () {
      expect(lower, contains('drop function if exists public.send_message_with_attachment'));
      expect(lower, contains('uuid, text, text, text, bigint, integer, integer'));
      expect(lower, contains('uuid, text, text, bigint, text, integer, integer'));
      expect(lower, contains('grant execute on function public.send_message_with_attachment'));
    });
  });
}
