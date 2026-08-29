import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _normalizeLikeMigration(String input) {
  const substitutions = <String, String>{
    'ă': 'a',
    'â': 'a',
    'î': 'i',
    'ș': 's',
    'ş': 's',
    'ț': 't',
    'ţ': 't',
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
  };
  final substituted = input
      .toLowerCase()
      .split('')
      .map((character) => substitutions[character] ?? character);
  return substituted
      .join()
      .replaceAll(RegExp(r'[^a-zа-яё0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool _migrationRulesReject(String sql, String input) {
  final normalized = _normalizeLikeMigration(input);
  final compact = normalized.replaceAll(' ', '');
  final rules = RegExp(
    r"\('[^']+',\s*'(?:en|ro|ru)',\s*'[^']+',\s*'(token|compact_contains)',\s*'([^']+)'\)",
  ).allMatches(sql);
  for (final rule in rules) {
    final mode = rule.group(1)!;
    final pattern = rule.group(2)!;
    if (mode == 'token' && ' $normalized '.contains(' $pattern ')) {
      return true;
    }
    if (mode == 'compact_contains' && compact.contains(pattern)) return true;
  }
  return false;
}

void main() {
  final sql = File(
    'supabase/migrations/20260826120000_app_store_content_moderation_foundation.sql',
  ).readAsStringSync().toLowerCase();

  group('server-authoritative objectionable text filtering', () {
    test('covers every public or inter-user free-text persistence surface', () {
      for (final table in <String>['listings', 'seller_profiles', 'messages']) {
        expect(sql, contains("tg_table_name = '$table'"), reason: table);
        expect(sql, contains('create trigger ${table}_enforce_user_text'));
      }
      for (final surface in <String>[
        'listing_title',
        'listing_description',
        'listing_registration',
        'listing_make',
        'listing_model',
        'listing_city',
        'seller_display_name',
        'message_body',
      ]) {
        expect(sql, contains("'$surface'"), reason: surface);
      }
    });

    test('normalizes common evasion while retaining RU RO EN rules', () {
      expect(sql, contains("regexp_replace("));
      expect(sql, contains("'[^[:alnum:]]+'"));
      expect(sql, contains("'ăâîșşțţ013457'"));
      expect(sql, contains("language in ('en', 'ro', 'ru')"));
      expect(sql, contains("'compact_contains'"));
      expect(sql, contains("'token'"));
    });

    test('rejects baseline RU RO EN content and separator evasion', () {
      expect(_migrationRulesReject(sql, 'K.I.L.L --- Y0URSELF'), isTrue);
      expect(_migrationRulesReject(sql, 'câștig   garantat'), isTrue);
      expect(
        _migrationRulesReject(sql, 'г а р а н т и р о в а н н ы й доход'),
        isTrue,
      );
    });

    test(
      'ordinary vehicle and support text is not a baseline false positive',
      () {
        expect(
          _migrationRulesReject(
            sql,
            'Продам Renault Megane, хорошее состояние, пробег 120 000 км',
          ),
          isFalse,
        );
        expect(
          _migrationRulesReject(
            sql,
            'Mașină întreținută, preț negociabil, disponibilă în Chișinău',
          ),
          isFalse,
        );
        expect(
          _migrationRulesReject(sql, 'Please send more photos of the Toyota'),
          isFalse,
        );
      },
    );

    test('returns a stable content-free rejection code', () {
      expect(sql, contains("raise exception 'carzon_content_rejected'"));
      expect(sql, contains("errcode = 'p0001'"));
      expect(sql, contains('rejected private text is not copied'));
    });

    test('does not filter private report notes and retains length limits', () {
      expect(sql, isNot(contains("tg_table_name = 'user_reports'")));
      expect(sql, isNot(contains("tg_table_name = 'listing_reports'")));
      expect(sql, isNot(contains('user_reports_enforce_user_text')));
      expect(sql, isNot(contains('listing_reports_enforce_user_text')));
      expect(sql, isNot(contains("'user_report_note'")));
      expect(sql, isNot(contains("'listing_report_note'")));
      expect(
        sql,
        contains('check (note is null or char_length(note) <= 1000)'),
      );
      expect(
        sql,
        contains('if v_note is not null and char_length(v_note) > 1000'),
      );
      expect(_migrationRulesReject(sql, 'K.I.L.L --- Y0URSELF'), isTrue);
    });
  });

  group('structured listing reporting', () {
    test('is RPC-only for authenticated clients with RLS enabled', () {
      expect(
        sql,
        contains(
          'alter table public.listing_reports enable row level security',
        ),
      );
      expect(
        sql,
        contains(
          'revoke all on table public.listing_reports from authenticated',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function public.report_listing(uuid, text, text)\n    to authenticated',
        ),
      );
      expect(sql, contains('uuid := auth.uid()'));
    });

    test('derives evidence server-side and deduplicates pending reports', () {
      expect(sql, contains('select l.* into v_listing'));
      expect(sql, contains('v_listing.seller_id = v_uid'));
      expect(
        sql,
        contains('listing_reports_one_pending_per_reporter_listing_idx'),
      );
      expect(sql, contains('already_pending := true'));
      expect(sql, contains('original_reporter_user_id'));
      expect(sql, contains('original_listing_owner_user_id'));
      expect(sql, isNot(contains('contact_phone_snapshot')));
      expect(sql, isNot(contains('vin_snapshot')));
      expect(sql, isNot(contains('image_url_snapshot')));
    });
  });

  test('operator queue and status transitions are service-role only', () {
    expect(sql, contains('public.moderation_list_pending_reports'));
    expect(sql, contains('public.moderation_update_report_status'));
    expect(sql, contains('from public, anon, authenticated'));
    expect(sql, contains('to service_role'));
    expect(sql, contains("'reviewed', 'dismissed', 'resolved'"));
  });
}
