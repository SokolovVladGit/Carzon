import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260617120000_fix_listing_vin_pgcrypto_digest.sql`.
void main() {
  group('20260617120000_fix_listing_vin_pgcrypto_digest.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260617120000_fix_listing_vin_pgcrypto_digest.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'VIN digest fix migration must exist');
      sql = f.readAsStringSync();
    });

    test('enables pgcrypto in extensions schema (Supabase-safe)', () {
      expect(
        sql.toLowerCase(),
        contains('create extension if not exists pgcrypto with schema extensions'),
      );
    });

    test('defines internal carzon_sha256_hex_utf8 with extensions-capable search_path', () {
      expect(sql.toLowerCase(), contains('carzon_sha256_hex_utf8'));
      expect(
        sql.toLowerCase(),
        contains('set search_path = public, extensions, pg_temp'),
      );
      expect(sql.toLowerCase(), contains("'sha256'::text"));
    });

    test('RPCs delegate VIN hash to helper (no bare digest in RPC bodies)', () {
      expect(sql, contains('v_vin_hash := public.carzon_sha256_hex_utf8(v_vin_norm);'));
      final rpcBodies = sql.split('create function public.create_listing_v2');
      expect(rpcBodies.length, greaterThan(1));
      final afterCreate = rpcBodies[1];
      final dollarBlocks = afterCreate.split(r'$$');
      expect(dollarBlocks.length, greaterThan(2));
      final plpgsqlBody = dollarBlocks[1];
      expect(plpgsqlBody.contains('digest('), isFalse);

      final updParts = sql.split('create function public.update_listing_details_v2');
      expect(updParts.length, greaterThan(1));
      final updBodyBlock = updParts[1].split(r'$$')[1];
      expect(updBodyBlock.contains('digest('), isFalse);
    });

    test('helper body uses digest with explicit algorithm type', () {
      final helperStart = sql.indexOf('create or replace function public.carzon_sha256_hex_utf8');
      expect(helperStart, greaterThan(-1));
      final helperSql = sql.substring(helperStart);
      final helperBody = helperSql.split(r'$$')[1];
      expect(helperBody.contains('digest('), isTrue);
      expect(helperBody.contains("'sha256'::text"), isTrue);
    });

    test('does not add plaintext vin column to public.listings', () {
      final listingAlter = RegExp(
        r'alter\s+table\s+public\.listings\b[\s\S]*?;',
        caseSensitive: false,
      );
      final standaloneVinCol = RegExp(
        r'\badd\s+column\b[\s\S]{0,220}?\bvin\b(?![a-z0-9_])',
        caseSensitive: false,
      );
      for (final m in listingAlter.allMatches(sql)) {
        final stmt = m.group(0)!;
        if (!stmt.toLowerCase().contains('add column')) continue;
        expect(
          standaloneVinCol.hasMatch(stmt),
          isFalse,
        );
      }
    });

    test('create_listing_v2 drop signature includes trailing p_vin text type', () {
      expect(
        sql.toLowerCase(),
        contains(
          'drop function if exists public.create_listing_v2(\n'
          '    text, text, text, integer, numeric, integer,\n'
          '    text, text, text, text, text, boolean,\n'
          '    text, text, text[], text[], text,\n'
          '    text, numeric, integer, text, text, text,\n'
          '    text\n'
          ');',
        ),
      );
    });

    test('re-applies authenticated execute grants for listing RPCs', () {
      expect(
        sql.toLowerCase(),
        contains(
          'grant execute on function public.create_listing_v2(\n'
          '    text, text, text, integer, numeric, integer,\n'
          '    text, text, text, text, text, boolean,\n'
          '    text, text, text[], text[], text,\n'
          '    text, numeric, integer, text, text, text,\n'
          '    text\n'
          ') to authenticated;',
        ),
      );
      expect(
        sql.toLowerCase(),
        contains(
          'grant execute on function public.update_listing_details_v2(\n'
          '    uuid, text, text, text, integer, numeric, text, integer,\n'
          '    text, text, text, text, text, boolean, text,\n'
          '    text, numeric, integer, text, text, text,\n'
          '    text\n'
          ') to authenticated;',
        ),
      );
    });

    test('revokes helper from anon/authenticated', () {
      expect(
        sql.toLowerCase(),
        contains('revoke all on function public.carzon_sha256_hex_utf8(text) from anon'),
      );
      expect(
        sql.toLowerCase(),
        contains(
          'revoke all on function public.carzon_sha256_hex_utf8(text) from authenticated',
        ),
      );
    });
  });
}
