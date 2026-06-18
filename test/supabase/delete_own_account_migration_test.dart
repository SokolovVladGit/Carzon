import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for `20260713120000_delete_own_account.sql`.
void main() {
  group('20260713120000_delete_own_account.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final file = File(
        'supabase/migrations/20260713120000_delete_own_account.sql',
      );
      expect(file.existsSync(), isTrue, reason: 'migration file exists');
      sql = file.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('defines delete_own_account RPC with SECURITY DEFINER', () {
      expect(lower, contains('create or replace function public.delete_own_account'));
      expect(lower, contains('security definer'));
      expect(lower, contains('set search_path = public, pg_temp, storage'));
    });

    test('requires authenticated caller', () {
      expect(lower, contains('v_uid is null'));
      expect(lower, contains("errcode = '28000'"));
    });

    test('blocks support account self-deletion', () {
      expect(lower, contains('admin@carzon.com'));
      expect(lower, contains('account cannot be self-deleted'));
    });

    test('deletes owned listings before auth user removal', () {
      expect(lower, contains('delete from public.listings'));
      expect(lower, contains('where seller_id = v_uid'));
    });

    test('cleans user-scoped storage prefixes', () {
      expect(lower, contains("bucket_id = 'listing-images'"));
      expect(lower, contains("bucket_id = 'seller-avatars'"));
      expect(lower, contains("bucket_id = 'chat-attachments'"));
    });

    test('enables hosted storage delete guard bypass before storage cleanup', () {
      expect(lower, contains("storage.allow_delete_query"));
      expect(lower, contains("set_config('storage.allow_delete_query', 'true', true)"));
      final bypassIndex = lower.indexOf('storage.allow_delete_query');
      final storageIndex = lower.indexOf("bucket_id = 'listing-images'");
      expect(bypassIndex, lessThan(storageIndex));
    });

    test('deactivates push tokens before listing and storage cleanup', () {
      final pushIndex = lower.indexOf('deactivate_my_push_tokens');
      final bypassIndex = lower.indexOf('storage.allow_delete_query');
      final storageIndex = lower.indexOf("bucket_id = 'listing-images'");
      final listingsIndex = lower.indexOf('delete from public.listings');
      expect(pushIndex, lessThan(bypassIndex));
      expect(bypassIndex, lessThan(storageIndex));
      expect(storageIndex, lessThan(listingsIndex));
    });

    test('scopes all mutations to auth.uid()', () {
      expect(lower, contains('v_uid uuid := auth.uid()'));
      expect(lower, isNot(contains('p_user_id')));
      expect(lower, isNot(contains('p_uid')));
    });

    test('grants execute to authenticated only', () {
      expect(
        lower,
        contains('grant execute on function public.delete_own_account()'),
      );
      expect(
        lower,
        contains('revoke all on function public.delete_own_account()'),
      );
      expect(lower, isNot(contains('grant execute on function public.delete_own_account() to anon')));
    });

    test('does not weaken listings seller_id FK or expose buyer VIN data', () {
      expect(lower, isNot(contains('alter table public.listings')));
      expect(lower, isNot(contains('listing_vehicle_identity')));
      expect(lower, isNot(contains('vin_hash')));
    });
  });

  group('20260713130000_delete_own_account_storage_delete_bypass.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final file = File(
        'supabase/migrations/20260713130000_delete_own_account_storage_delete_bypass.sql',
      );
      expect(file.existsSync(), isTrue, reason: 'patch migration file exists');
      sql = file.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('patches delete_own_account with storage delete guard bypass', () {
      expect(lower, contains('create or replace function public.delete_own_account'));
      expect(lower, contains("set_config('storage.allow_delete_query', 'true', true)"));
      expect(lower, contains('storage.protect_delete'));
    });
  });

  group('delete-own-account Edge Function', () {
    late String ts;
    late String lower;

    setUpAll(() {
      final file = File('supabase/functions/delete-own-account/index.ts');
      expect(file.existsSync(), isTrue, reason: 'edge function exists');
      ts = file.readAsStringSync();
      lower = ts.toLowerCase();
    });

    test('calls delete_own_account RPC before auth.admin.deleteUser', () {
      final rpcIndex = lower.indexOf('delete_own_account');
      final deleteIndex = lower.indexOf('auth.admin.deleteuser');
      expect(rpcIndex, greaterThanOrEqualTo(0));
      expect(deleteIndex, greaterThan(rpcIndex));
    });

    test('does not log raw error messages that may contain user data', () {
      expect(ts, isNot(contains('rpcError.message')));
      expect(ts, isNot(contains('deleteError.message')));
    });

    test('blocks support account', () {
      expect(lower, contains('admin@carzon.com'));
      expect(lower, contains('account_cannot_be_self_deleted'));
    });
  });
}
