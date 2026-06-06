import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final file = File(
      'supabase/migrations/20260630120000_public_contact_projection_hardening.sql',
    );
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync().toLowerCase();
  });

  test('revokes broad public table SELECT and grants listing columns only', () {
    expect(sql, contains('revoke select on table public.listings from anon'));
    expect(
      sql,
      contains('revoke select on table public.listings from authenticated'),
    );
    expect(sql, contains('grant select ('));
    expect(sql, contains('seller_id'));
    expect(sql, isNot(contains('grant select (contact_phone')));
  });

  test(
    'public listing/image grants exclude contact and storage_path columns',
    () {
      final listingGrant = _statementStarting(
        sql,
        'grant select (',
        'public.listings',
      );
      final imageGrant = _statementStarting(
        sql,
        'grant select (',
        'public.listing_images',
      );

      expect(listingGrant, isNot(contains('contact_phone')));
      expect(listingGrant, isNot(contains('telegram_username')));
      expect(listingGrant, isNot(contains('whatsapp_enabled')));
      expect(imageGrant, isNot(contains('storage_path')));
    },
  );

  test(
    'defines explicit public contact reveal RPC for active listings only',
    () {
      expect(sql, contains('function public.get_listing_public_contact'));
      expect(sql, contains("and l.status = 'active'"));
      expect(
        sql,
        contains(
          'grant execute on function public.get_listing_public_contact(uuid)',
        ),
      );
      expect(sql, contains('to anon, authenticated'));
    },
  );

  test(
    'defines authenticated owner edit RPCs with auth.uid ownership checks',
    () {
      expect(sql, contains('function public.get_my_listing_for_edit'));
      expect(sql, contains('function public.get_my_listing_images_for_edit'));
      expect(sql, contains('and l.seller_id = auth.uid()'));
      expect(
        sql,
        contains(
          'grant execute on function public.get_my_listing_for_edit(uuid)',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function public.get_my_listing_images_for_edit(uuid)',
        ),
      );
      expect(sql, contains('to authenticated'));
    },
  );
}

String _statementStarting(String sql, String start, String target) {
  final index = sql.indexOf(start);
  var searchFrom = index;
  while (searchFrom >= 0) {
    final end = sql.indexOf(';', searchFrom);
    if (end < 0) break;
    final stmt = sql.substring(searchFrom, end + 1);
    if (stmt.contains(target)) return stmt;
    searchFrom = sql.indexOf(start, end + 1);
  }
  fail('Missing statement for $target');
}
