import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260623120000_vin_phase2e_listing_vin_source_results.sql`.
void main() {
  group('20260623120000_vin_phase2e_listing_vin_source_results.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260623120000_vin_phase2e_listing_vin_source_results.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'Phase 2E source results migration must exist');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('does not alter public.listings or listing vin_status', () {
      expect(lower, isNot(contains('alter table public.listings')));
    });

    test('defines listing_vin_source_results internal table', () {
      expect(lower, contains('create table'));
      expect(lower, contains('public.listing_vin_source_results'));
    });

    test('enables RLS and revokes anon/authenticated', () {
      expect(
        lower,
        contains(
          'alter table public.listing_vin_source_results enable row level security',
        ),
      );
      expect(lower, contains('revoke all on table public.listing_vin_source_results'));
      expect(lower, contains('from anon'));
      expect(lower, contains('from authenticated'));
    });

    test('does not grant table privileges to anon or authenticated', () {
      expect(lower, isNot(contains('grant select on table public.listing_vin_source_results')));
      expect(lower, isNot(contains('grant insert on table public.listing_vin_source_results')));
      expect(lower, isNot(contains('grant all on table public.listing_vin_source_results')));
    });

    test('has no forbidden secret or VIN identity columns in table definition', () {
      bool lineLooksLikeColumnDef(String line) {
        final t = line.trimLeft();
        if (t.startsWith('constraint ')) return false;
        if (t.startsWith('--')) return false;
        return RegExp(r'^[a-z_][a-z0-9_]*\s+').hasMatch(t);
      }

      final forbiddenName = RegExp(
        r'^(vin_hash|vin_normalized|raw_|.*payload|credential|access_token|api_key|refresh_token|password)\b',
        caseSensitive: false,
      );
      for (final line in sql.split('\n')) {
        if (!lineLooksLikeColumnDef(line)) continue;
        final name = line.trimLeft().split(RegExp(r'\s+')).first;
        expect(
          forbiddenName.hasMatch(name),
          isFalse,
          reason: 'Unexpected column $name in listing_vin_source_results',
        );
      }
    });

    test('CHECK lists required access_mode literals', () {
      for (final v in [
        'carzon_partner_api',
        'user_delegated',
        'seller_uploaded_document',
        'manual_external_check',
        'commercial_api',
      ]) {
        expect(lower, contains("'$v'"), reason: 'access_mode must include $v');
      }
      expect(lower, contains("'not_available'"));
      expect(lower, contains("'unknown'"));
    });

    test('CHECK lists required status literals', () {
      for (final v in [
        'no_data',
        'requires_user_consent',
        'requires_partner_access',
        'requires_manual_action',
        'rate_limited',
        'quota_exceeded',
      ]) {
        expect(lower, contains("'$v'"), reason: 'status must include $v');
      }
    });

    test('comments forbid auto-registration and describe manual_external_check', () {
      expect(lower, contains('must not auto-register'));
      expect(lower, contains('auto-register users'));
      expect(lower, contains('manual_external_check'));
      expect(lower, contains('explicit consent'));
    });

    test('clears source results when listing_vehicle_identity deleted', () {
      expect(lower, contains('carzon_after_listing_vehicle_identity_deleted'));
      expect(lower, contains('delete from public.listing_vin_source_results'));
    });

    test('has unique (listing_id, source_id)', () {
      expect(lower, contains('unique (listing_id, source_id)'));
    });

    test('has normalized_summary and source_metadata object checks', () {
      expect(lower, contains('jsonb_typeof(normalized_summary)'));
      expect(lower, contains('jsonb_typeof(source_metadata)'));
    });

    test('no HTTP URLs in SQL', () {
      expect(lower, isNot(contains('http://')));
      expect(lower, isNot(contains('https://')));
    });

    test('no new owner/client RPC for source results in this migration', () {
      expect(lower, isNot(contains('get_my_listing_vin_source_results')));
      expect(lower, isNot(contains('create or replace function public.get_')));
    });
  });
}
