import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guard: migrations that define `public` tables or functions must keep
/// explicit PostgreSQL `GRANT`s so PostgREST / Supabase Data API access keeps
/// working when implicit `public` privileges are tightened for new projects.
///
/// RLS remains authoritative for row visibility; this test only enforces that
/// each migrated object used by the client stack is granted to the appropriate
/// roles somewhere in the migration chain.
///
/// Does not run SQL against Postgres and does not prove hosted Supabase parity.
void main() {
  late String combined;
  late Set<String> createdTables;
  late Set<String> createdFunctions;

  /// Functions that must **not** be treated as Flutter/PostgREST RPCs: trigger
  /// bodies, revoked SECURITY DEFINER helpers, or other maintenance entry points
  /// that are not `.rpc(...)` from the app. They do **not** require
  /// `GRANT EXECUTE` for client roles; some older migrations may still contain
  /// historical `GRANT` lines — forward-only `REVOKE` migrations define the
  /// intended exposure. Add new names here when introducing internal-only
  /// `public` functions, or the test will require a client `GRANT EXECUTE`.
  const internalFunctionsExemptFromClientExecuteGrant = <String>{
    'ensure_seller_profile',
    'listings_after_insert_ensure_seller_profile',
    'touch_seller_profiles_updated_at',
    'touch_filter_alert_settings_updated_at',
    'touch_saved_searches_updated_at',
    'enforce_saved_searches_max_per_user',
    'saved_searches_validate_name',
    'saved_searches_validate_criteria',
    'set_listings_updated_at',
    // After INSERT on `messages`; not Flutter-called — client EXECUTE revoked in
    // 20260526120000_revoke_internal_trigger_function_execute.sql.
    'touch_conversation_from_message',
    'touch_notification_preferences_updated_at',
    'touch_user_push_tokens_updated_at',
    // Phase 3A internal notification queue (Edge + trigger only).
    'touch_notification_delivery_events_updated_at',
    'enqueue_message_notification_event',
    'claim_notification_events_for_processing',
    // Phase 4A filter alerts (SQL match + enqueue + Edge claim + pg_cron worker only).
    'listing_matches_saved_discovery_criteria',
    'enqueue_filter_alert_notification_events_for_listing',
    'trigger_enqueue_filter_alert_notifications',
    'claim_filter_alert_notification_events_for_processing',
    // Phase 3E: pg_cron-only worker; REVOKE from anon/authenticated in scheduler migration.
    'carzon_invoke_process_message_notifications_worker',
    // Phase 4A: pg_cron-only worker; REVOKE from anon/authenticated in 20260601 migration.
    'carzon_invoke_process_filter_alert_notifications_worker',
    // Internal pg_cron-only maintenance; client execution is explicitly revoked.
    'carzon_cleanup_cron_job_run_details',
    // P2 V1 price drop favorites (enqueue on listing edit + Edge claim + pg_cron worker only).
    'enqueue_price_drop_favorite_notification_events',
    'claim_price_drop_notification_events_for_processing',
    'carzon_invoke_process_price_drop_notifications_worker',
    // VIN Phase 2C scheduler: pg_cron-only worker; REVOKE from anon/authenticated.
    'carzon_invoke_process_vin_decode_jobs_worker',
    // Phase 1 VIN: SECURITY DEFINER listing RPCs only; revoked from clients in migration.
    'carzon_normalize_vin_input',
    'carzon_normalized_vin_syntax_ok',
    // VIN hash helper (pgcrypto); revoked from clients — RPC-only use.
    'carzon_sha256_hex_utf8',
    // Phase 2A VIN processing foundation (trigger + enqueue helper only).
    'carzon_enqueue_vin_decode_from_identity',
    'carzon_after_listing_vehicle_identity_vin_hash_change',
    'carzon_after_listing_vehicle_identity_deleted',
    // Phase 2B VIN decode worker RPCs (service_role / Edge only).
    'claim_vin_decode_jobs_for_processing',
    'complete_vin_decode_job_success',
    'complete_vin_decode_job_failure',
    // Phase 2C VIN provider plumbing (service_role / Edge only).
    'get_vin_for_decode_job',
    'requeue_vin_decode_job_for_listing',
    // Chat attachments: BEFORE INSERT trigger on message_attachments only.
    'validate_message_attachment_conversation',
    // Model Passport SQL helpers (SECURITY DEFINER; revoked from client roles).
    'carzon_model_data_fold_whitespace',
    'carzon_model_data_normalize_make_key',
    'carzon_model_data_normalize_model_key',
    'carzon_model_data_apply_make_alias_key',
    'carzon_model_data_canonical_make_label',
    'carzon_model_data_resolve_identity',
    'carzon_model_data_default_limitation_codes',
    'carzon_model_data_build_cache_key',
    // Model Passport worker RPCs (service_role / Edge only).
    'enqueue_vehicle_model_fetch_if_needed',
    'claim_vehicle_model_fetch_jobs_for_processing',
    'complete_vehicle_model_fetch_job_success',
    'complete_vehicle_model_fetch_job_failure',
    'get_listing_vin_model_fetch_hints',
    // Model Passport pg_cron worker; REVOKE from anon/authenticated.
    'carzon_invoke_process_model_data_jobs_worker',
    // Recall SQL helpers + worker RPCs (service_role / Edge only).
    'carzon_recall_data_build_cache_key',
    'carzon_recall_data_resolve_identity',
    'carzon_recall_data_default_limitation_codes',
    'enqueue_vehicle_recall_fetch_if_needed',
    'claim_vehicle_recall_fetch_jobs_for_processing',
    'complete_vehicle_recall_fetch_job_success',
    'complete_vehicle_recall_fetch_job_failure',
    'carzon_invoke_process_recall_data_jobs_worker',
    // Fuel Prices v1: internal SQL helpers + pg_cron worker (not Flutter `.rpc()`).
    // Public buyer path is `get_fuel_prices_for_app()` only.
    'carzon_fuel_price_territory_for_cache_key',
    'carzon_fuel_price_source_for_cache_key',
    'carzon_fuel_price_default_limitation_codes',
    'carzon_invoke_process_fuel_price_jobs_worker',
    // M0.3 messaging block/report helpers (trigger/RPC-internal only).
    'carzon_is_support_user_id',
    'carzon_users_are_blocked',
    'carzon_messaging_peer_from_conversation',
    // Retained moderation evidence guard: table trigger only, never app-called.
    'protect_user_report_original_evidence',
    // App Store moderation: trigger-only filter/evidence helpers. Client access
    // is through report_listing; operator RPCs are service_role-only.
    'carzon_enforce_user_text',
    'protect_listing_report_original_evidence',
  };

  /// Internal `public` tables with RLS that must **not** receive `GRANT` to
  /// `anon` / `authenticated` (Edge worker uses `service_role` only).
  const internalTablesWithoutDataApiGrant = <String>{
    'notification_delivery_events',
    'notification_delivery_attempts',
    // Owner-private VIN storage; RPC-only access (revoked from anon/authenticated).
    'listing_vehicle_identity',
    // Phase 2A internal VIN queue/cache/snapshot (service_role / workers only).
    'vin_processing_jobs',
    'vin_decode_cache',
    'listing_vin_report_snapshot',
    // Phase 2E: per-source normalized outcomes (service_role / workers only).
    'listing_vin_source_results',
    // Listing view analytics (RPC-only writes; hashed dedupe store).
    'listing_view_daily',
    'listing_view_dedupe',
    // Model Passport worker cache/queue (service_role / Edge only).
    'vehicle_model_source_cache',
    'vehicle_model_fetch_jobs',
    // Recall worker cache/queue (service_role / Edge only).
    'vehicle_recall_source_cache',
    'vehicle_recall_fetch_jobs',
    // Fuel Prices worker cache/queue (service_role / Edge only).
    'fuel_price_source_cache',
    'fuel_price_fetch_jobs',
    // M0.3 reports: RPC-only writes; no client table access.
    'user_reports',
    'listing_reports',
    // Canonical model catalog: RPC-only public read; no Data API table grants.
    'vehicle_model_catalog',
  };

  /// `public` tables created by this repo: must match migrations exactly.
  /// **New table:** add the name here **and** add an explicit `GRANT` in the
  /// migration chain (or document a rare non–Data-API exception with review).
  const expectedPublicTables = <String>{
    'listings',
    'favorites',
    'listing_images',
    'conversations',
    'messages',
    'user_conversation_state',
    'seller_profiles',
    'filter_alert_settings',
    'saved_searches',
    'notification_preferences',
    'user_push_tokens',
    'notification_delivery_events',
    'notification_delivery_attempts',
    'listing_vehicle_identity',
    'vin_processing_jobs',
    'vin_decode_cache',
    'listing_vin_report_snapshot',
    'listing_vin_source_results',
    'listing_view_daily',
    'listing_view_dedupe',
    'message_attachments',
    'vehicle_model_source_cache',
    'vehicle_model_fetch_jobs',
    'vehicle_recall_source_cache',
    'vehicle_recall_fetch_jobs',
    'fuel_price_source_cache',
    'fuel_price_fetch_jobs',
    'user_blocks',
    'user_reports',
    'listing_reports',
    'vehicle_model_catalog',
  };

  setUpAll(() {
    final dir = Directory('supabase/migrations');
    expect(dir.existsSync(), isTrue, reason: 'supabase/migrations must exist');
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty, reason: 'migrations folder must contain SQL');
    combined = files.map((f) => f.readAsStringSync()).join('\n');
    final lower = combined.toLowerCase();

    createdTables = {
      for (final m in RegExp(
        r'create\s+table\s+if\s+not\s+exists\s+public\.(\w+)',
        caseSensitive: false,
      ).allMatches(lower))
        m.group(1)!,
    };
    if (!createdTables.contains('listings')) {
      throw StateError(
        'Table parser failed — expected listings in migrations.',
      );
    }

    createdFunctions = {
      for (final m in RegExp(
        r'create\s+(?:or\s+replace\s+)?function\s+public\.(\w+)\s*\(',
        caseSensitive: false,
      ).allMatches(lower))
        m.group(1)!,
    };
  });

  group('public tables vs GRANT coverage', () {
    test(
      'migrations and expectedPublicTables stay in sync (no surprise tables)',
      () {
        final unexpected = createdTables.difference(expectedPublicTables);
        expect(
          unexpected,
          isEmpty,
          reason:
              'Undocumented `public` table(s) in migrations: ${unexpected.join(', ')}. '
              'Add each to [expectedPublicTables] with an explicit `GRANT` in a '
              'migration, or document a justified non–Data-API exception.',
        );
        final missing = expectedPublicTables.difference(createdTables);
        expect(
          missing,
          isEmpty,
          reason:
              'Stale entries in [expectedPublicTables] (not created in '
              'migrations): ${missing.join(', ')} — remove or fix migrations.',
        );
      },
    );

    test(
      'each client-facing public table has an explicit ON public.<table> GRANT '
      '(internal queue tables exempt)',
      () {
        for (final t in expectedPublicTables) {
          if (internalTablesWithoutDataApiGrant.contains(t)) {
            expect(
              _tableHasGrantToAnonOrAuthenticated(combined, t),
              isFalse,
              reason:
                  'Internal table public.$t must not grant Data API privileges '
                  'to anon or authenticated.',
            );
            final lower = combined.toLowerCase();
            expect(
              lower,
              contains('revoke all on table public.$t from authenticated'),
              reason: 'Revoke client roles from internal table public.$t.',
            );
            continue;
          }
          expect(
            _hasGrantOnPublicTable(combined, t),
            isTrue,
            reason:
                'Add a GRANT referencing public.$t (Data API requires explicit '
                'object privilege on fresh Supabase projects).',
          );
        }
      },
    );
  });

  group('public functions vs GRANT EXECUTE coverage', () {
    test(
      'each client-facing public function has GRANT EXECUTE (exemptions explicit)',
      () {
        final undocumentedInternal =
            internalFunctionsExemptFromClientExecuteGrant.difference(
              createdFunctions,
            );
        expect(
          undocumentedInternal,
          isEmpty,
          reason:
              'Exemption list references unknown function(s): '
              '${undocumentedInternal.join(', ')} — typo or remove.',
        );

        for (final name in createdFunctions) {
          if (internalFunctionsExemptFromClientExecuteGrant.contains(name)) {
            continue;
          }
          expect(
            RegExp(
              r'grant\s+execute\s+on\s+function\s+public\.' +
                  RegExp.escape(name) +
                  r'\s*\(',
              caseSensitive: false,
            ).hasMatch(combined),
            isTrue,
            reason:
                'Add GRANT EXECUTE for public.$name(...) for client/Data API use, '
                'or add to [internalFunctionsExemptFromClientExecuteGrant] with '
                'a comment that it is not Flutter-called.',
          );
        }
      },
    );
  });

  group('20260525120000_explicit_data_api_grants.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260525120000_explicit_data_api_grants.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'explicit grants migration exists',
      );
      sql = f.readAsStringSync().toLowerCase();
    });

    test('documents Data API / GRANT rationale', () {
      expect(sql, contains('data api'));
      expect(sql, contains('grant'));
    });
  });

  group('20260526120000_revoke_internal_trigger_function_execute.sql', () {
    test('exists and revokes execute on message trigger helper', () {
      final f = File(
        'supabase/migrations/20260526120000_revoke_internal_trigger_function_execute.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'revoke-internal migration exists',
      );
      final lower = f.readAsStringSync().toLowerCase();
      expect(lower, contains('touch_conversation_from_message'));
      expect(lower, contains('revoke'));
    });
  });
}

bool _hasGrantOnPublicTable(String migrationSql, String table) {
  final t = RegExp.escape(table);
  return RegExp(
    r'grant\s[^;]+on\s+(?:table\s+)?public\.' + t + r'\b',
    caseSensitive: false,
  ).hasMatch(migrationSql);
}

/// Whether any `GRANT` statement targets both this table and anon/authenticated.
bool _tableHasGrantToAnonOrAuthenticated(String migrationSql, String table) {
  final t = RegExp.escape(table);
  final re = RegExp(
    r'grant\s+[^;]+on\s+(?:table\s+)?public\.' + t + r'\b[^;]*;',
    caseSensitive: false,
  );
  for (final m in re.allMatches(migrationSql)) {
    final stmt = m.group(0)!.toLowerCase();
    if (stmt.contains(' to anon') ||
        stmt.contains(' to authenticated') ||
        stmt.contains(', anon') ||
        stmt.contains(', authenticated')) {
      return true;
    }
  }
  return false;
}
