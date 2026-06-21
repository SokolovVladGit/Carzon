import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _functionBody(String lower, String signature, {String? endSignature}) {
  final start = lower.indexOf(signature);
  expect(start, greaterThanOrEqualTo(0), reason: 'function $signature');
  final end = endSignature != null
      ? lower.indexOf(endSignature, start + signature.length)
      : lower.length;
  expect(end, greaterThan(start), reason: 'function end for $signature');
  return lower.substring(start, end);
}

/// Static checks for `20260714120000_messaging_user_blocks_and_reports.sql`.
void main() {
  group('20260714120000_messaging_user_blocks_and_reports.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final file = File(
        'supabase/migrations/20260714120000_messaging_user_blocks_and_reports.sql',
      );
      expect(file.existsSync(), isTrue, reason: 'migration file exists');
      sql = file.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test(
      'defines user_blocks with composite primary key and no self-block',
      () {
        expect(
          lower,
          contains('create table if not exists public.user_blocks'),
        );
        expect(lower, contains('blocker_user_id'));
        expect(lower, contains('blocked_user_id'));
        expect(
          lower,
          contains('primary key (blocker_user_id, blocked_user_id)'),
        );
        expect(lower, contains('user_blocks_no_self_block_chk'));
      },
    );

    test(
      'defines user_reports with reporter/reported/conversation/reason/status',
      () {
        expect(
          lower,
          contains('create table if not exists public.user_reports'),
        );
        expect(lower, contains('reporter_user_id'));
        expect(lower, contains('reported_user_id'));
        expect(lower, contains('conversation_id'));
        expect(lower, contains('listing_id'));
        expect(lower, contains('user_reports_reason_chk'));
        expect(lower, contains('user_reports_status_chk'));
        expect(lower, contains('user_reports_note_len_chk'));
        expect(lower, contains("'harassment'"));
        expect(lower, contains("'pending'"));
        expect(lower, contains("'reviewed'"));
        expect(lower, contains("'dismissed'"));
      },
    );

    test('enables RLS and restricts direct table writes', () {
      expect(
        lower,
        contains('alter table public.user_blocks enable row level security'),
      );
      expect(
        lower,
        contains('alter table public.user_reports enable row level security'),
      );
      expect(
        lower,
        contains('revoke insert, update, delete on public.user_blocks'),
      );
      expect(lower, contains('revoke all on table public.user_reports'));
      expect(lower, contains('user_blocks_blocker_select'));
      expect(lower, contains('blocker_user_id = auth.uid()'));
    });

    test('carzon_users_are_blocked checks both directions', () {
      expect(
        lower,
        contains('create or replace function public.carzon_users_are_blocked'),
      );
      expect(lower, contains('security definer'));
      expect(lower, contains('set search_path = public, pg_temp'));
      expect(
        lower,
        contains(
          'b.blocker_user_id = p_user_a and b.blocked_user_id = p_user_b',
        ),
      );
      expect(
        lower,
        contains(
          'b.blocker_user_id = p_user_b and b.blocked_user_id = p_user_a',
        ),
      );
      expect(
        lower,
        contains('revoke all on function public.carzon_users_are_blocked'),
      );
    });

    test('block_user derives peer from conversation via auth.uid()', () {
      final body = _functionBody(
        lower,
        'create or replace function public.block_user(p_conversation_id uuid)',
        endSignature:
            'create or replace function public.unblock_user(p_blocked_user_id uuid)',
      );
      expect(body, contains('carzon_messaging_peer_from_conversation'));
      expect(body, contains('v_uid'));
      expect(body, contains('auth.uid()'));
      expect(body, isNot(contains('p_blocked_user_id')));
      expect(
        body,
        contains('on conflict (blocker_user_id, blocked_user_id) do nothing'),
      );
    });

    test('report_user derives reported user from conversation only', () {
      expect(lower, contains('create or replace function public.report_user'));
      expect(lower, contains('carzon_messaging_peer_from_conversation'));
      expect(lower, isNot(contains('p_reported_user_id')));
      expect(lower, contains('invalid report reason'));
      expect(lower, contains('report note is too long'));
      expect(lower, contains('char_length(v_note) > 1000'));
    });

    test('excludes support conversations from block and report', () {
      final blockBody = _functionBody(
        lower,
        'create or replace function public.block_user(p_conversation_id uuid)',
        endSignature:
            'create or replace function public.unblock_user(p_blocked_user_id uuid)',
      );
      expect(blockBody, contains("v_kind = 'support'"));
      expect(blockBody, contains('carzon_is_support_user_id'));
      expect(blockBody, contains('not available for support conversations'));

      final reportBody = _functionBody(
        lower,
        'create or replace function public.report_user(',
        endSignature: 'create or replace function public.get_or_create_conversation',
      );
      expect(reportBody, contains("v_kind = 'support'"));
      expect(reportBody, contains('carzon_is_support_user_id'));
    });

    test('unblock_user is scoped to auth.uid()', () {
      expect(lower, contains('create or replace function public.unblock_user'));
      expect(lower, contains('where b.blocker_user_id = v_uid'));
      expect(
        lower,
        contains('grant execute on function public.unblock_user(uuid)'),
      );
    });

    test('list_blocked_users exposes only safe public seller fields', () {
      final body = _functionBody(
        lower,
        'create or replace function public.list_blocked_users()',
        endSignature: 'create or replace function public.report_user(',
      );
      expect(body, contains('sp.display_name'));
      expect(body, contains('sp.avatar_url'));
      expect(body, contains('where b.blocker_user_id = auth.uid()'));
      expect(body, isNot(contains('email')));
      expect(body, isNot(contains('phone')));
    });

    test(
      'send_message and send_message_with_attachment gate on block helper',
      () {
        final sendIdx = lower.indexOf(
          'create or replace function public.send_message(',
        );
        final attachIdx = lower.indexOf(
          'create or replace function public.send_message_with_attachment',
        );
        final enqueueIdx = lower.indexOf(
          'create or replace function public.enqueue_message_notification_event',
        );
        expect(sendIdx, greaterThanOrEqualTo(0));
        expect(attachIdx, greaterThan(sendIdx));
        expect(enqueueIdx, greaterThan(attachIdx));

        final sendBody = lower.substring(sendIdx, attachIdx);
        expect(sendBody, contains('carzon_users_are_blocked'));
        expect(sendBody, contains('messaging blocked'));
        expect(sendBody, contains("v_kind is distinct from 'support'"));

        final attachBody = lower.substring(attachIdx, enqueueIdx);
        expect(attachBody, contains('carzon_users_are_blocked'));
        expect(attachBody, contains('messaging blocked'));
      },
    );

    test(
      'get_or_create_conversation blocks new listing threads when blocked',
      () {
        final fnIdx = lower.indexOf(
          'create or replace function public.get_or_create_conversation',
        );
        final sendIdx = lower.indexOf(
          'create or replace function public.send_message(',
        );
        final fnBody = lower.substring(fnIdx, sendIdx);
        expect(
          fnBody,
          contains('carzon_users_are_blocked(v_uid, v_seller_id)'),
        );
        expect(fnBody, contains('messaging blocked'));
      },
    );

    test('enqueue_message_notification_event skips blocked listing peers', () {
      final enqueueIdx = lower.indexOf(
        'create or replace function public.enqueue_message_notification_event',
      );
      final enqueueBody = lower.substring(enqueueIdx);
      expect(enqueueBody, contains('carzon_users_are_blocked'));
      expect(enqueueBody, contains("v_kind is distinct from 'support'"));
    });

    test('does not expose VIN or official-data private fields', () {
      expect(lower, isNot(contains('vin_hash')));
      expect(lower, isNot(contains('source_metadata')));
      expect(lower, isNot(contains('listing_vehicle_identity')));
      expect(lower, isNot(contains('cache_key')));
    });

    test('RPC grants are authenticated-only', () {
      expect(
        lower,
        contains('grant execute on function public.block_user(uuid)'),
      );
      expect(
        lower,
        contains(
          'grant execute on function public.report_user(uuid, text, text)',
        ),
      );
      expect(
        lower,
        isNot(
          contains('grant execute on function public.block_user(uuid) to anon'),
        ),
      );
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function public.report_user(uuid, text, text) to anon',
          ),
        ),
      );
    });
  });
}
