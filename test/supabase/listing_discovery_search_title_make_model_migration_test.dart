import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for listing discovery search parity migration.
void main() {
  group('20260705120000_listing_discovery_search_title_make_model.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260705120000_listing_discovery_search_title_make_model.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('replaces listing_matches_saved_discovery_criteria', () {
      expect(
        lower,
        contains(
          'create or replace function public.listing_matches_saved_discovery_criteria',
        ),
      );
    });

    test('search criteria matches title OR make OR model', () {
      final start = lower.indexOf(
        'create or replace function public.listing_matches_saved_discovery_criteria',
      );
      expect(start, greaterThan(-1));
      final searchBlock = lower.substring(start);
      expect(searchBlock, contains('coalesce(p_listing.title'));
      expect(searchBlock, contains('coalesce(p_listing.make'));
      expect(searchBlock, contains('coalesce(p_listing.model'));
      expect(searchBlock, contains(" escape '\\'"));
      expect(
        searchBlock,
        isNot(
          contains(
            'p_listing.title is null or p_listing.title not ilike',
          ),
        ),
      );
    });

    test('saved criteria with search Audi: make branch present for parity', () {
      expect(lower, contains("coalesce(p_listing.make, '') ilike"));
      expect(lower, contains("coalesce(p_listing.model, '') ilike"));
    });

    test('explicit make and model criteria blocks unchanged', () {
      expect(
        lower,
        contains(
          "p_listing.make is null or p_listing.make not ilike ('%' || v_make || '%')",
        ),
      );
      expect(
        lower,
        contains(
          "p_listing.model is null or p_listing.model not ilike ('%' || v_model || '%')",
        ),
      );
    });

    test('does not add city or description to free-text search', () {
      final start = lower.indexOf('v_search := trim');
      expect(start, greaterThan(-1));
      final end = lower.indexOf('v_make := trim', start);
      expect(end, greaterThan(start));
      final searchSection = lower.substring(start, end);
      expect(searchSection, isNot(contains('p_listing.city')));
      expect(searchSection, isNot(contains('p_listing.description')));
    });

    test('updates function comment for title/make/model search', () {
      expect(lower, contains('title or make or model'));
    });
  });
}
