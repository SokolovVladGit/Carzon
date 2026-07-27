import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _functionBody(String lower, String signature) {
  final start = lower.indexOf(signature);
  expect(start, greaterThanOrEqualTo(0), reason: 'function $signature');
  final end = lower.indexOf(r'$$;', start);
  expect(end, greaterThan(start), reason: 'function end for $signature');
  return lower.substring(start, end);
}

void main() {
  const migrationName =
      '20260823120000_retain_pseudonymized_moderation_reports.sql';
  const migrationPath = 'supabase/migrations/$migrationName';

  group(migrationName, () {
    late String sql;
    late String lower;
    late String evidenceTriggerBody;
    late String reportUserBody;

    setUpAll(() {
      final file = File(migrationPath);
      expect(file.existsSync(), isTrue, reason: 'migration file exists');
      sql = file.readAsStringSync();
      lower = sql.toLowerCase();
      evidenceTriggerBody = _functionBody(
        lower,
        'create or replace function '
        'public.protect_user_report_original_evidence()',
      );
      reportUserBody = _functionBody(
        lower,
        'create or replace function public.report_user(',
      );
    });

    test('is ordered after every migration it supersedes', () {
      final migrationNames =
          Directory('supabase/migrations')
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .where((name) => name.endsWith('.sql'))
              .toList()
            ..sort();
      expect(migrationNames.last, migrationName);
      expect(
        migrationName.compareTo(
          '20260714120000_messaging_user_blocks_and_reports.sql',
        ),
        greaterThan(0),
      );
      expect(
        migrationName.compareTo(
          '20260713130000_delete_own_account_storage_delete_bypass.sql',
        ),
        greaterThan(0),
      );
    });

    test('adds only pseudonymized UUID subject snapshots', () {
      expect(lower, contains('original_reporter_user_id uuid'));
      expect(lower, contains('original_reported_user_id uuid'));
      expect(lower, contains('original_conversation_id uuid'));
      expect(lower, contains('original_listing_id uuid'));
      expect(lower, contains('pseudonymized snapshot'));
      expect(lower, isNot(contains('original_message_id')));
      expect(lower, isNot(contains('email text')));
      expect(lower, isNot(contains('phone text')));
      expect(lower, isNot(contains('vin_')));
      expect(lower, isNot(contains('attachment_url')));
      expect(lower, isNot(contains('jsonb')));
    });

    test('backfills existing reports before requiring core snapshots', () {
      final updateIndex = lower.indexOf('update public.user_reports');
      final notNullIndex = lower.indexOf(
        'alter column original_reporter_user_id set not null',
      );
      expect(updateIndex, greaterThanOrEqualTo(0));
      expect(notNullIndex, greaterThan(updateIndex));
      expect(
        lower,
        contains('coalesce(original_reporter_user_id, reporter_user_id)'),
      );
      expect(
        lower,
        contains('coalesce(original_reported_user_id, reported_user_id)'),
      );
      expect(
        lower,
        contains('coalesce(original_conversation_id, conversation_id)'),
      );
      expect(lower, contains('coalesce(original_listing_id, listing_id)'));
      expect(
        lower,
        isNot(contains('alter column original_listing_id set not null')),
      );
    });

    test('makes every deletable live report reference nullable', () {
      expect(lower, contains('alter column reporter_user_id drop not null'));
      expect(lower, contains('alter column reported_user_id drop not null'));
      expect(lower, contains('alter column conversation_id drop not null'));
    });

    test('replaces every report foreign key with ON DELETE SET NULL', () {
      for (final constraint in <String>[
        'user_reports_reporter_user_id_fkey',
        'user_reports_reported_user_id_fkey',
        'user_reports_conversation_id_fkey',
        'user_reports_listing_id_fkey',
      ]) {
        expect(lower, contains('drop constraint if exists $constraint'));
        final addIndex = lower.indexOf('add constraint $constraint');
        expect(addIndex, greaterThanOrEqualTo(0), reason: constraint);
        final nextConstraint = lower.indexOf('add constraint', addIndex + 1);
        final constraintSql = lower.substring(
          addIndex,
          nextConstraint == -1 ? lower.length : nextConstraint,
        );
        expect(
          constraintSql,
          contains('on delete set null'),
          reason: constraint,
        );
        expect(
          constraintSql,
          isNot(contains('on delete cascade')),
          reason: constraint,
        );
      }
    });

    test('protects original evidence with a BEFORE UPDATE row trigger', () {
      final triggerPattern = RegExp(
        r'create trigger protect_user_report_original_evidence_before_update'
        r'\s+before update on public\.user_reports'
        r'\s+for each row'
        r'\s+execute function '
        r'public\.protect_user_report_original_evidence\(\)',
      );
      expect(lower, matches(triggerPattern));
      expect(
        lower.indexOf(
          'create trigger '
          'protect_user_report_original_evidence_before_update',
        ),
        greaterThan(
          lower.indexOf('add constraint user_reports_listing_id_fkey'),
        ),
      );
    });

    test('rejects changes to exactly the original evidence fields', () {
      for (final field in <String>[
        'original_reporter_user_id',
        'original_reported_user_id',
        'original_conversation_id',
        'original_listing_id',
        'reason',
        'note',
        'created_at',
      ]) {
        expect(
          evidenceTriggerBody,
          contains('new.$field is distinct from old.$field'),
          reason: field,
        );
      }
      expect(
        evidenceTriggerBody,
        contains('moderation_report_original_evidence_is_immutable'),
      );
      expect(evidenceTriggerBody, contains("using errcode = '22000'"));
      expect(evidenceTriggerBody, contains('return new'));
      expect(
        RegExp(r'is distinct from').allMatches(evidenceTriggerBody).length,
        7,
      );
    });

    test('allows status and live-reference updates', () {
      for (final field in <String>[
        'status',
        'reporter_user_id',
        'reported_user_id',
        'conversation_id',
        'listing_id',
      ]) {
        expect(
          evidenceTriggerBody,
          isNot(contains('new.$field is distinct from old.$field')),
          reason: field,
        );
      }
      expect(evidenceTriggerBody, isNot(contains('raise exception;')));
    });

    test('keeps the trigger function non-callable by app roles', () {
      for (final role in <String>['public', 'anon', 'authenticated']) {
        expect(
          lower,
          contains(
            'revoke all on function '
            'public.protect_user_report_original_evidence() from $role',
          ),
          reason: role,
        );
      }
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function '
            'public.protect_user_report_original_evidence()',
          ),
        ),
      );
      expect(evidenceTriggerBody, contains('returns trigger'));
      expect(
        evidenceTriggerBody,
        contains('set search_path = pg_catalog, pg_temp'),
      );
      expect(evidenceTriggerBody, isNot(contains('security definer')));
    });

    test('keeps report submission signature and response compatible', () {
      expect(
        lower,
        contains(
          'create or replace function public.report_user(\n'
          '    p_conversation_id uuid,\n'
          '    p_reason          text,\n'
          '    p_note            text default null\n'
          ')',
        ),
      );
      expect(lower, contains('report_id  uuid'));
      expect(lower, contains('status     text'));
      expect(lower, contains('created_at timestamptz'));
    });

    test('keeps report_user SECURITY DEFINER with restricted search path', () {
      expect(reportUserBody, contains('security definer'));
      expect(reportUserBody, contains('set search_path = public, pg_temp'));
    });

    test('derives reporter and subjects from trusted server-side values', () {
      expect(reportUserBody, matches(RegExp(r'v_uid\s+uuid := auth\.uid\(\)')));
      expect(
        reportUserBody,
        contains('carzon_messaging_peer_from_conversation'),
      );
      expect(reportUserBody, contains('v_uid,\n        v_other_user_id'));
      expect(
        reportUserBody,
        contains(
          'v_listing_id,\n'
          '        v_uid,\n'
          '        v_other_user_id,\n'
          '        p_conversation_id,\n'
          '        v_listing_id',
        ),
      );
      expect(reportUserBody, isNot(contains('p_reporter_user_id')));
      expect(reportUserBody, isNot(contains('p_original_')));
    });

    test('preserves report validation and support exclusions', () {
      expect(reportUserBody, contains('invalid report reason'));
      expect(reportUserBody, contains('report note is too long'));
      expect(reportUserBody, contains("v_kind = 'support'"));
      expect(reportUserBody, contains('carzon_is_support_user_id'));
    });

    test('does not expose snapshots in the RPC response', () {
      final returnsStart = lower.indexOf('returns table (');
      final returnsEnd = lower.indexOf(')', returnsStart);
      final returnsSql = lower.substring(returnsStart, returnsEnd);
      expect(returnsSql, isNot(contains('original_')));
      expect(returnsSql, isNot(contains('reporter_user_id')));
      expect(returnsSql, isNot(contains('reported_user_id')));
    });

    test('keeps direct client table access revoked', () {
      expect(
        lower,
        contains('alter table public.user_reports enable row level security'),
      );
      expect(
        lower,
        contains('revoke all on table public.user_reports from anon'),
      );
      expect(
        lower,
        contains('revoke all on table public.user_reports from authenticated'),
      );
      expect(
        lower,
        contains('revoke all on table public.user_reports from public'),
      );
      expect(lower, isNot(contains('create policy')));
      expect(lower, isNot(contains('grant select on public.user_reports')));
      expect(lower, isNot(contains('grant update on public.user_reports')));
      expect(lower, isNot(contains('grant delete on public.user_reports')));
    });

    test('keeps RPC execution authenticated-only', () {
      expect(
        lower,
        contains(
          'grant execute on function public.report_user(uuid, text, text) '
          'to authenticated',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.report_user(uuid, text, text) '
          'from anon',
        ),
      );
    });

    test('latest account deletion does not explicitly erase reports', () {
      final deleteMigration = File(
        'supabase/migrations/'
        '20260713130000_delete_own_account_storage_delete_bypass.sql',
      ).readAsStringSync().toLowerCase();
      final edgeFunction = File(
        'supabase/functions/delete-own-account/index.ts',
      ).readAsStringSync().toLowerCase();
      expect(
        deleteMigration,
        isNot(contains('delete from public.user_reports')),
      );
      expect(edgeFunction, isNot(contains('user_reports')));
      expect(deleteMigration, contains('delete from public.listings'));
    });
  });
}
