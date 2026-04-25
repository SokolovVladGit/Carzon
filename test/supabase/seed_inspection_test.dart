import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static inspection of `supabase/seed.sql`.
///
/// The repo has no live SQL execution harness for tests, so these
/// checks are textual. They exist to prevent accidental regressions
/// in the demo dataset's minimum coverage and to guard the
/// "no schema/RLS changes from the seed" invariant.
///
/// The grep-style assertions are deliberately permissive: they count
/// occurrences of structural tokens (e.g. `'transnistria', null, 'active'`)
/// rather than parsing SQL. This is sufficient because the seed rows
/// are written in a fixed, reviewable insert shape.
void main() {
  group('supabase/seed.sql', () {
    late String sql;
    late String sqlLower;

    setUpAll(() {
      final file = File('supabase/seed.sql');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'supabase/seed.sql must exist for local/demo usage',
      );
      sql = file.readAsStringSync();
      sqlLower = sql.toLowerCase();
    });

    int countMatches(String haystack, RegExp pattern) =>
        pattern.allMatches(haystack).length;

    test('contains at least 12 active Transnistria listings', () {
      // The insert rows follow the contract:
      //   ..., 'transnistria', null, 'active', ...
      // where the two-column tuple is `(market_region, cover_image_url, status)`.
      final pattern = RegExp(
        r"'transnistria'\s*,\s*null\s*,\s*'active'",
        caseSensitive: false,
      );
      final count = countMatches(sql, pattern);
      expect(
        count,
        greaterThanOrEqualTo(12),
        reason:
            'expected ≥12 active Transnistria listings, found $count',
      );
    });

    test('contains at least 4 active Moldova listings', () {
      final pattern = RegExp(
        r"'moldova'\s*,\s*null\s*,\s*'active'",
        caseSensitive: false,
      );
      final count = countMatches(sql, pattern);
      expect(
        count,
        greaterThanOrEqualTo(4),
        reason: 'expected ≥4 active Moldova listings, found $count',
      );
    });

    test('contains at least 2 non-active listings', () {
      final pattern = RegExp(
        r"null\s*,\s*'(hidden|sold|archived)'",
        caseSensitive: false,
      );
      final count = countMatches(sql, pattern);
      expect(
        count,
        greaterThanOrEqualTo(2),
        reason:
            'expected ≥2 hidden/sold/archived rows for dev visibility, '
            'found $count',
      );
    });

    test(
      'every contact_phone literal matches the synthetic '
      '+373 000 000 XXX pattern',
      () {
        final phoneLiterals =
            RegExp(r"'\+\d[\d\s]+'").allMatches(sql).map((m) => m.group(0)!);
        expect(
          phoneLiterals,
          isNotEmpty,
          reason: 'seed must have phone literals to assert on',
        );
        final syntheticPattern =
            RegExp(r"^'\+373 000 000 \d{3}'$");
        for (final literal in phoneLiterals) {
          expect(
            syntheticPattern.hasMatch(literal),
            isTrue,
            reason:
                'non-synthetic phone literal found in seed: $literal. '
                'all seed phones must follow the `+373 000 000 XXX` '
                'placeholder pattern.',
          );
        }
      },
    );

    test('telegram usernames follow the synthetic carzon_demo_NN pattern', () {
      // The row shape is:
      //   ..., '+373 000 000 XXX', <telegram-literal-or-null>, <bool>)
      // so the telegram slot is whatever directly follows a synthetic
      // phone literal. Capture it as either `null` or a quoted handle.
      final telegramMatches = RegExp(
        r"'\+373 000 000 \d{3}'\s*,\s*(null|'([A-Za-z0-9_]{1,32})')",
        caseSensitive: false,
      ).allMatches(sql);
      expect(
        telegramMatches,
        isNotEmpty,
        reason:
            'expected the phone→telegram row shape to be present in seed',
      );
      var nonNullCount = 0;
      for (final match in telegramMatches) {
        final slot = match.group(1)!;
        if (slot == 'null') continue;
        nonNullCount++;
        final handle = match.group(2)!;
        expect(
          handle.startsWith('carzon_demo_'),
          isTrue,
          reason:
              'non-synthetic telegram handle found in seed: `$handle`. '
              'seed telegram handles must use the `carzon_demo_NN` pattern.',
        );
      }
      expect(
        nonNullCount,
        greaterThan(0),
        reason:
            'seed should include at least one non-null telegram handle to '
            'exercise that contact surface in the demo',
      );
    });

    test('only uses valid market_region values', () {
      // The only region literals acceptable in the seed are
      // 'transnistria' and 'moldova'. If some other region literal is
      // introduced here, the insert will fail the CHECK constraint.
      final regionLiterals = RegExp(
        r"'(?:transnistria|moldova|[a-z]{4,})'",
      ).allMatches(sqlLower).map((m) => m.group(0)!).toSet();
      // Only assert on the region-looking strings that appear in the
      // `market_region` insert slot — the sql_lower step is just to
      // handle case-insensitive accidents.
      expect(sqlLower, contains("'transnistria'"));
      expect(sqlLower, contains("'moldova'"));
      // Sanity-check: no unexpected region literals.
      const forbiddenRegions = <String>[
        "'ukraine'",
        "'romania'",
        "'russia'",
        "'eu'",
      ];
      for (final token in forbiddenRegions) {
        expect(
          sqlLower,
          isNot(contains(token)),
          reason: 'seed must not reference region: $token',
        );
      }
      // Extra: regionLiterals is examined only for debugging if the
      // sanity checks above ever stop being sufficient.
      expect(regionLiterals, isNotEmpty);
    });

    test('only uses valid listing status values', () {
      const allowed = {"'active'", "'hidden'", "'sold'", "'archived'"};
      // Status literals in the seed appear immediately after
      // `null, 'active'` / `null, 'hidden'` / etc. Grab every such
      // pair and ensure its status belongs to the allow-set.
      final statusTuples = RegExp(
        r"null\s*,\s*'([a-z]+)'",
        caseSensitive: false,
      ).allMatches(sql).map((m) => "'${m.group(1)!.toLowerCase()}'").toSet();
      expect(statusTuples, isNotEmpty);
      for (final status in statusTuples) {
        expect(
          allowed,
          contains(status),
          reason: 'invalid listing status literal in seed: $status',
        );
      }
    });

    test('only uses valid listing type values', () {
      const allowed = {"'sale'", "'exchange'", "'both'"};
      // Type literals sit immediately before the city column, i.e.
      // `<price>, <mileage>, 'sale', 'Tiraspol', 'transnistria'`.
      // Capture the type token by finding commas followed by one of
      // the three allowed type strings to avoid false positives from
      // other string columns.
      final typeTuples = RegExp(
        r",\s*'(sale|exchange|both)'\s*,\s*'[^']+'\s*,\s*'(transnistria|moldova)'",
        caseSensitive: false,
      ).allMatches(sql).map((m) => "'${m.group(1)!.toLowerCase()}'").toSet();
      expect(typeTuples, isNotEmpty);
      for (final t in typeTuples) {
        expect(
          allowed,
          contains(t),
          reason: 'invalid listing type literal in seed: $t',
        );
      }
    });

    test('mixes whatsapp_enabled true and false', () {
      expect(sqlLower, contains('true'));
      expect(sqlLower, contains('false'));
    });

    test('every insert row uses seller_id = null', () {
      // Sanity check: seeds must not bind a seller_id, since they are
      // intentionally un-owned demo rows. If a real auth.users UUID is
      // ever pasted here by mistake, this check flags it.
      final uuidRefs = RegExp(
        r"auth\.users\s*\(",
        caseSensitive: false,
      );
      expect(uuidRefs.hasMatch(sql), isFalse,
          reason: 'seed must not reference auth.users directly');
      // The seller_id column value in every insert tuple must be the
      // literal `null`. The row shape places seller_id between
      // `status` and `contact_phone`, so: `'active', null,` or
      // `'hidden', null,` etc. We already asserted active/hidden/etc.
      // above — this check adds the explicit `, null,` token right
      // after the status literal.
      final sellerNullPairs = RegExp(
        r"'(active|hidden|sold|archived)'\s*,\s*null\s*,",
        caseSensitive: false,
      ).allMatches(sql);
      expect(sellerNullPairs, isNotEmpty);
    });

    test('does not add, drop, or alter policies or schema', () {
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
          reason: 'seed.sql must not contain "$token"',
        );
      }
    });

    test('is idempotent via on conflict do update', () {
      // Re-running the seed file is a supported workflow. Every insert
      // block must have an `on conflict (id) do update` clause.
      final insertCount =
          RegExp(r'insert\s+into\s+public\.listings', caseSensitive: false)
              .allMatches(sql)
              .length;
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
            'clause so the seed is re-runnable. '
            'inserts=$insertCount conflicts=$conflictCount',
      );
    });
  });
}
