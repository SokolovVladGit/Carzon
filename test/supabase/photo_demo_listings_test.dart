import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static inspection of the temporary photo-demo SQL files under
/// `supabase/demo/`. The repo has no live SQL execution harness for
/// tests, so these checks are textual and rely on the fixed insert
/// shape used in the file.
///
/// Guards:
///   * dataset shape (20 rows, 10 per region, all active, un-owned),
///   * synthetic contact patterns (phone + Telegram handle),
///   * cover URLs come only from the expected `kareta.md` host,
///   * no schema / RLS / policy / function / grant / revoke escape,
///   * cleanup targets only the explicit demo ids and nothing else.
void main() {
  group('supabase/demo/photo_demo_listings.sql', () {
    late String sql;
    late String sqlLower;

    setUpAll(() {
      final file = File('supabase/demo/photo_demo_listings.sql');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'supabase/demo/photo_demo_listings.sql must exist',
      );
      sql = file.readAsStringSync();
      sqlLower = sql.toLowerCase();
    });

    int countMatches(String haystack, RegExp pattern) =>
        pattern.allMatches(haystack).length;

    test('contains exactly 20 demo-namespace IDs', () {
      // The demo namespace is `d0000000-0000-4000-8000-0000000000XX`
      // where XX is 01..20. There must be exactly one occurrence per
      // id — rows are inserted once and the cleanup file lives in a
      // sibling SQL script, so this file must not repeat ids.
      final idPattern = RegExp(
        r"'d0000000-0000-4000-8000-0000000000\d{2}'",
        caseSensitive: false,
      );
      final matches = idPattern
          .allMatches(sql)
          .map((m) => m.group(0)!)
          .toList();
      expect(
        matches.length,
        20,
        reason:
            'expected exactly 20 demo IDs in photo_demo_listings.sql, '
            'found ${matches.length}',
      );
      // IDs must be unique (no copy-paste collisions).
      expect(matches.toSet().length, 20, reason: 'demo IDs must be unique');
    });

    test('contains exactly 10 Transnistria rows', () {
      final pattern = RegExp(
        r"'transnistria'\s*,\s*'https://content\.kareta\.md",
        caseSensitive: false,
      );
      final count = countMatches(sql, pattern);
      expect(
        count,
        10,
        reason:
            'expected exactly 10 Transnistria photo-demo rows, found $count',
      );
    });

    test('contains exactly 10 Moldova rows', () {
      final pattern = RegExp(
        r"'moldova'\s*,\s*'https://content\.kareta\.md",
        caseSensitive: false,
      );
      final count = countMatches(sql, pattern);
      expect(
        count,
        10,
        reason: 'expected exactly 10 Moldova photo-demo rows, found $count',
      );
    });

    test('every row is status = active', () {
      // The insert row shape is:
      //   ..., 'transnistria'|'moldova', '<cover>', 'active', null, ...
      // So status literals in the file must all be 'active'.
      final statusLiterals = RegExp(
        r"'(active|hidden|sold|archived)'",
        caseSensitive: false,
      ).allMatches(sql).map((m) => m.group(1)!.toLowerCase()).toSet();
      expect(
        statusLiterals,
        {'active'},
        reason:
            'photo demo dataset must only use status = active, '
            'found: $statusLiterals',
      );
      // Count `'active', null,` — the row-shape fingerprint for the
      // (status, seller_id) tuple. Comment mentions of `'active'` do
      // not match this pattern, so this scopes the assertion to real
      // row values only.
      final rowActiveCount = RegExp(
        r"'active'\s*,\s*null\s*,",
        caseSensitive: false,
      ).allMatches(sql).length;
      expect(
        rowActiveCount,
        20,
        reason:
            'expected 20 `active, null` status tuples (one per row), '
            'found $rowActiveCount',
      );
    });

    test('every row has seller_id = null', () {
      // The seller_id slot sits between status and contact_phone, so
      // the pattern `'active', null,` must appear once per row.
      final pattern = RegExp(r"'active'\s*,\s*null\s*,", caseSensitive: false);
      final count = countMatches(sql, pattern);
      expect(
        count,
        20,
        reason: 'expected 20 rows with seller_id = null, found $count',
      );
      // Defense in depth: must not reference auth.users directly.
      expect(
        RegExp(r"auth\.users\s*\(", caseSensitive: false).hasMatch(sql),
        isFalse,
        reason: 'photo demo must not reference auth.users directly',
      );
    });

    test('every contact phone matches the +373 000 100 XXX pattern', () {
      // Grab every +XXX-looking literal and require it to match the
      // synthetic photo-demo pattern. This catches accidental real
      // numbers leaking in.
      final phoneLiterals = RegExp(
        r"'\+\d[\d\s]+'",
      ).allMatches(sql).map((m) => m.group(0)!).toList();
      expect(
        phoneLiterals.length,
        20,
        reason:
            'expected 20 phone literals (one per row), '
            'found ${phoneLiterals.length}',
      );
      final syntheticPattern = RegExp(r"^'\+373 000 100 \d{3}'$");
      for (final literal in phoneLiterals) {
        expect(
          syntheticPattern.hasMatch(literal),
          isTrue,
          reason:
              'non-synthetic phone literal in photo demo: $literal. '
              'all photo-demo phones must follow `+373 000 100 XXX`.',
        );
      }
      // Cross-check: numeric XXX suffixes must be unique (001..020).
      final suffixPattern = RegExp(r"'\+373 000 100 (\d{3})'");
      final suffixes = phoneLiterals
          .map((l) => suffixPattern.firstMatch(l)?.group(1))
          .whereType<String>()
          .toSet();
      expect(
        suffixes.length,
        20,
        reason: 'expected 20 unique phone suffixes (001..020)',
      );
    });

    test('every Telegram handle matches @carzon_photo_demo_XX', () {
      // Telegram literal directly follows the synthetic phone in each
      // row: `'+373 000 100 001', '@carzon_photo_demo_01', ...`.
      final handleLiterals = RegExp(
        r"'\+373 000 100 \d{3}'\s*,\s*'(@?[A-Za-z0-9_]{5,32})'",
        caseSensitive: false,
      ).allMatches(sql).map((m) => m.group(1)!).toList();
      expect(
        handleLiterals.length,
        20,
        reason:
            'expected 20 Telegram handles (one per row), '
            'found ${handleLiterals.length}',
      );
      final handlePattern = RegExp(r'^@carzon_photo_demo_\d{2}$');
      for (final handle in handleLiterals) {
        expect(
          handlePattern.hasMatch(handle),
          isTrue,
          reason:
              'non-synthetic telegram handle in photo demo: $handle. '
              'all handles must match `@carzon_photo_demo_XX`.',
        );
      }
      // Must have 20 unique handles.
      expect(handleLiterals.toSet().length, 20);
    });

    test(
      'every cover URL uses https://content.kareta.md/items/original/...webp',
      () {
        final urlLiterals = RegExp(
          r"'https://[^']+'",
        ).allMatches(sql).map((m) => m.group(0)!).toList();
        expect(
          urlLiterals.length,
          20,
          reason: 'expected 20 cover URL literals, found ${urlLiterals.length}',
        );
        final expectedPattern = RegExp(
          r"^'https://content\.kareta\.md/items/original/[0-9a-f\-]{36}\.webp'$",
        );
        for (final url in urlLiterals) {
          expect(
            expectedPattern.hasMatch(url),
            isTrue,
            reason:
                'unexpected cover URL in photo demo: $url. '
                'must use https://content.kareta.md/items/original/<uuid>.webp.',
          );
        }
      },
    );

    test(
      'duplicate cover URLs are tolerated but the dataset still has 20 rows',
      () {
        // The provided source list has URL #1 and URL #6 identical, so
        // we expect exactly one duplicate cover in the dataset. The
        // dataset must still contain 20 rows regardless.
        final urlLiterals = RegExp(
          r"'https://[^']+'",
        ).allMatches(sql).map((m) => m.group(0)!).toList();
        expect(urlLiterals.length, 20);
        final unique = urlLiterals.toSet();
        // 20 rows, 19 unique URLs — one intentional duplicate.
        expect(
          unique.length,
          lessThanOrEqualTo(20),
          reason: 'unique cover count must not exceed row count',
        );
        expect(
          unique.length,
          greaterThanOrEqualTo(19),
          reason: 'expected at most one duplicate cover URL in the dataset',
        );
      },
    );

    test('mixes listing type sale / exchange / both', () {
      // Every `type` literal in the file must be one of the allowed
      // values, and the full mix must be present.
      final typeLiterals = RegExp(
        r",\s*'(sale|exchange|both)'\s*,\s*'[^']+'\s*,\s*'(transnistria|moldova)'",
        caseSensitive: false,
      ).allMatches(sql).map((m) => m.group(1)!.toLowerCase()).toSet();
      expect(typeLiterals, containsAll(<String>{'sale', 'exchange', 'both'}));
    });

    test('mixes whatsapp_enabled true and false', () {
      expect(sqlLower, contains('true'));
      expect(sqlLower, contains('false'));
    });

    test('does not add, drop, or alter policies, schema, or functions', () {
      const forbidden = [
        'create policy',
        'drop policy',
        'alter policy',
        'create table',
        'alter table',
        'drop table',
        'create index',
        'drop index',
        'create function',
        'create or replace function',
        'create extension',
        'grant ',
        'revoke ',
      ];
      for (final token in forbidden) {
        expect(
          sqlLower,
          isNot(contains(token)),
          reason: 'photo_demo_listings.sql must not contain "$token"',
        );
      }
    });

    test('is idempotent via on conflict do update', () {
      final insertCount = RegExp(
        r'insert\s+into\s+public\.listings',
        caseSensitive: false,
      ).allMatches(sql).length;
      final conflictCount = RegExp(
        r'on\s+conflict\s*\(\s*id\s*\)\s+do\s+update',
        caseSensitive: false,
      ).allMatches(sql).length;
      expect(insertCount, greaterThanOrEqualTo(1));
      expect(
        conflictCount,
        greaterThanOrEqualTo(insertCount),
        reason:
            'every insert block must carry an `on conflict (id) do update` '
            'clause so the photo demo SQL is re-runnable. '
            'inserts=$insertCount conflicts=$conflictCount',
      );
    });
  });

  group('supabase/demo/remove_photo_demo_listings.sql', () {
    late String sql;
    late String sqlLower;
    late String sqlStatementsLower;

    /// Strips `-- line comments` from a SQL string so lexical checks
    /// for forbidden tokens only inspect actual statements and not
    /// the "this script deliberately avoids X" explanatory prose.
    String stripLineComments(String raw) {
      final lines = raw.split('\n');
      final buf = StringBuffer();
      for (final line in lines) {
        final idx = line.indexOf('--');
        buf.writeln(idx >= 0 ? line.substring(0, idx) : line);
      }
      return buf.toString();
    }

    setUpAll(() {
      final file = File('supabase/demo/remove_photo_demo_listings.sql');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'supabase/demo/remove_photo_demo_listings.sql must exist',
      );
      sql = file.readAsStringSync();
      sqlLower = sql.toLowerCase();
      sqlStatementsLower = stripLineComments(sqlLower);
    });

    test('deletes exactly the 20 d000... ids and nothing else', () {
      final ids = RegExp(
        r"'d0000000-0000-4000-8000-0000000000\d{2}'",
        caseSensitive: false,
      ).allMatches(sql).map((m) => m.group(0)!).toList();
      expect(
        ids.length,
        20,
        reason:
            'cleanup SQL must reference all 20 photo-demo ids, '
            'found ${ids.length}',
      );
      expect(ids.toSet().length, 20, reason: 'cleanup ids must be unique');

      // Must not reference the production-seed `c0000000-...` namespace.
      expect(
        RegExp(r"'c0000000-0000-4000-8000", caseSensitive: false).hasMatch(sql),
        isFalse,
        reason:
            'cleanup SQL must not touch the production-seed c0000000 '
            'namespace',
      );
    });

    test('uses only a single scoped delete statement', () {
      final deleteCount = RegExp(
        r'delete\s+from\s+public\.listings',
        caseSensitive: false,
      ).allMatches(sql).length;
      expect(
        deleteCount,
        1,
        reason:
            'cleanup must consist of a single DELETE statement, '
            'found $deleteCount',
      );
    });

    test('does not use broad delete predicates', () {
      // Forbidden predicates that would put the normal seed or real
      // user data at risk. Checked against the comment-stripped
      // statement body so the prose explaining what the script
      // deliberately avoids does not trigger false positives.
      const forbidden = [
        'seller_id is null',
        'seller_id = null',
        'market_region =',
        'market_region in',
        'status =',
        'status in',
        'cover_image_url like',
        'cover_image_url ~',
        'cover_image_url ilike',
      ];
      for (final token in forbidden) {
        expect(
          sqlStatementsLower,
          isNot(contains(token)),
          reason:
              'remove_photo_demo_listings.sql must not contain broad '
              'predicate "$token" in actual statements',
        );
      }
    });

    test('does not alter schema, policies, or functions', () {
      const forbidden = [
        'create policy',
        'drop policy',
        'alter policy',
        'create table',
        'alter table',
        'drop table',
        'truncate',
        'create function',
        'create or replace function',
        'create extension',
        'grant ',
        'revoke ',
      ];
      for (final token in forbidden) {
        expect(
          sqlStatementsLower,
          isNot(contains(token)),
          reason: 'remove_photo_demo_listings.sql must not contain "$token"',
        );
      }
    });
  });
}
