import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260905120000_listing_variant_and_plugin_hybrid.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260905120000_listing_variant_and_plugin_hybrid.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('adds nullable variant with length CHECK and no FK', () {
      expect(sql, contains('add column if not exists variant text'));
      expect(sql, contains('listings_variant_len_chk'));
      expect(sql, contains('<= 80'));
      expect(
        sql.toLowerCase(),
        isNot(contains('references public.vehicle_model_catalog')),
      );
    });

    test('does not modify vehicle_model_catalog', () {
      expect(sql.toLowerCase(), isNot(contains('vehicle_model_catalog')));
    });

    test('extends fuel CHECK and RPC validation with plug_in_hybrid', () {
      expect(sql, contains("'plug_in_hybrid'"));
      expect(sql, contains("'hybrid'"));
      expect(sql, contains('invalid fuel_type'));
    });

    test('create/update RPCs accept trailing optional p_variant', () {
      expect(sql, contains('p_variant'));
      expect(sql, contains("nullif(btrim(coalesce(p_variant, '')), '')"));
      expect(sql, contains('variant is too long'));
      expect(
        sql,
        contains('drop function if exists public.create_listing_v2('),
      );
      expect(
        sql,
        contains('drop function if exists public.update_listing_details_v2('),
      );
    });

    test('public select grant includes variant', () {
      expect(sql, contains('grant select ('));
      expect(sql, contains('variant,'));
    });

    test('moderation trigger covers listing_variant', () {
      expect(
        sql,
        contains("assert_user_text_allowed(new.variant, 'listing_variant')"),
      );
    });

    test('does not change discovery or official-data identity functions', () {
      expect(sql, isNot(contains('listing_matches_saved_discovery_criteria')));
      expect(sql, isNot(contains('carzon_model_data_resolve_identity')));
      expect(sql, isNot(contains('carzon_recall_data_resolve_identity')));
    });
  });
}
