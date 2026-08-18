import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/'
      '20260824120000_exclusive_active_push_token_ownership.sql';
  late String sql;

  setUpAll(() {
    final migration = File(migrationPath);
    expect(migration.existsSync(), isTrue);
    sql = migration.readAsStringSync().toLowerCase();
  });

  test('normalizes missed cleanup before enforcing one active owner', () {
    expect(sql, contains('row_number() over'));
    expect(sql, contains('partition by token'));
    expect(sql, contains('where is_active = true'));
    expect(sql, contains('ownership_rank > 1'));
    expect(sql, contains('set is_active = false'));
  });

  test('database invariant permits only one active account per token', () {
    expect(sql, contains('user_push_tokens_one_active_owner_per_token_idx'));
    expect(sql, contains('unique index'));
    expect(sql, contains('on public.user_push_tokens (token)'));
    expect(sql, contains('where is_active = true'));
  });

  test('A to B transfer is serialized and deactivates A first', () {
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('pg_advisory_xact_lock'));
    expect(sql, contains('hashtextextended(v_tok, 0)'));
    final deactivate = sql.indexOf('where token = v_tok');
    final insert = sql.indexOf('insert into public.user_push_tokens');
    expect(deactivate, greaterThan(-1));
    expect(insert, greaterThan(deactivate));
    expect(sql, contains('user_id <> v_uid'));
  });

  test('same-user repeat registration stays idempotent', () {
    expect(
      sql,
      contains(
        'on conflict on constraint user_push_tokens_user_token_uniq '
        'do update',
      ),
    );
    expect(sql, contains('is_active = true'));
    expect(sql, contains('last_seen_at = now()'));
  });

  test('RPC preserves authenticated-only security contract', () {
    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = public, pg_temp'));
    expect(sql, contains("raise exception 'not authenticated'"));
    expect(sql, contains('revoke all on function public.register_push_token'));
    expect(sql, contains('from anon'));
    expect(sql, contains('to authenticated'));
    expect(sql, isNot(contains('p_user_id')));
  });
}
