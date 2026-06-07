-- Generate missing migration metadata INSERT statements — READ-ONLY output only.
--
-- PURPOSE:
--   When check_hosted_migration_parity.sql reports STOP but
--   check_hosted_runtime_contracts.sql reports PASS, hosted objects exist but
--   supabase_migrations.schema_migrations is incomplete (metadata drift).
--
--   This helper compares the repo inventory to hosted schema_migrations and
--   returns ready-to-copy INSERT text. It does NOT execute any INSERT itself.
--
-- PREREQUISITES (owner must confirm before using generated SQL):
--   1. check_hosted_runtime_contracts.sql → overall_runtime_contract_result = PASS
--      (no STOP; no unresolved WARN if you require strict gate)
--   2. Owner explicit approval to write metadata rows
--
-- HOW TO RUN:
--   Supabase Dashboard → SQL Editor → paste this ENTIRE file → Run
--
-- OUTPUT:
--   version | migration_name | category | status | metadata_insert_sql
--   Plus summary rows: combined block + approval gate reminders.
--
-- AFTER OWNER APPROVES AND RUNS GENERATED INSERTS:
--   Re-run supabase/maintenance/check_hosted_migration_parity.sql
--   Expected: hosted_migration_parity_result = PASS
--
-- SAFETY: SELECT / CTE / VALUES ONLY in this file. Generated SQL is metadata-only.
-- Pair with: docs/hosted_migration_metadata_reconciliation.md

WITH
expected AS (
    SELECT *
      FROM (
        VALUES
            ('20260423120000', 'create_listings',                         'listings'),
            ('20260423130000', 'listings_insert_policy',                  'listings'),
            ('20260423140000', 'create_favorites',                        'favorites'),
            ('20260423150000', 'listings_owner_read_policy',              'listings'),
            ('20260424120000', 'add_listings_market_region',              'listings'),
            ('20260424130000', 'listings_owner_status_rpc',               'listings'),
            ('20260424140000', 'listing_images_storage',                  'storage'),
            ('20260425120000', 'add_listings_contact_fields',             'listings'),
            ('20260425130000', 'update_listing_details_rpc',              'listings'),
            ('20260425140000', 'delete_listing_rpc',                      'listings'),
            ('20260425150000', 'update_listing_cover_image_rpc',          'listings'),
            ('20260503120000', 'create_listing_rpc',                      'listings'),
            ('20260504180000', 'create_listing_v2_foundation',            'listings'),
            ('20260506140000', 'update_listing_details_v2_rpc',           'listings'),
            ('20260510120000', 'messaging_phase1a',                       'messaging'),
            ('20260511120000', 'listings_body_type',                      'listings'),
            ('20260515120000', 'seller_profiles_foundation',              'seller profiles'),
            ('20260516120000', 'seller_display_name_self_edit',           'seller profiles'),
            ('20260517120000', 'seller_avatar_self_edit',                 'seller profiles'),
            ('20260518100000', 'user_conversation_state',                 'messaging'),
            ('20260520120000', 'list_inbox_conversations_rpc',            'messaging'),
            ('20260521120000', 'listing_specs_description',               'listings'),
            ('20260523120000', 'filter_alert_settings',                   'filter alerts'),
            ('20260524120000', 'listings_updated_at',                     'listings'),
            ('20260525120000', 'explicit_data_api_grants',                'grants'),
            ('20260526120000', 'revoke_internal_trigger_function_execute','grants'),
            ('20260527120000', 'notification_preferences_and_push_tokens','notifications'),
            ('20260528120000', 'message_notification_delivery_pipeline',  'notifications'),
            ('20260529120000', 'schedule_process_message_notifications_cron','notifications'),
            ('20260601120000', 'filter_alert_notifications_queue_and_cron','filter alerts'),
            ('20260616120000', 'listing_vin_phase1',                      'VIN'),
            ('20260617120000', 'fix_listing_vin_pgcrypto_digest',         'VIN'),
            ('20260618120000', 'vin_phase2a_processing_foundation',       'VIN'),
            ('20260619120000', 'vin_phase2b_worker_rpcs',                 'VIN'),
            ('20260620120000', 'vin_phase2c_provider_foundation',         'VIN'),
            ('20260621120000', 'schedule_process_vin_decode_jobs_cron',   'VIN'),
            ('20260622120000', 'owner_vin_report_rpc_decoded_summary',    'VIN'),
            ('20260623120000', 'vin_phase2e_listing_vin_source_results',  'VIN'),
            ('20260624120000', 'vin_phase2f_nhtsa_source_results_bridge','VIN'),
            ('20260625120000', 'vin_phase2g_backfill_nhtsa_source_results','VIN'),
            ('20260626120000', 'vin_phase2h_owner_source_results_rpc',    'VIN'),
            ('20260627120000', 'vin_phase2j_buyer_report_rpc',            'VIN'),
            ('20260628120000', 'vin_phase2k_public_nhtsa_basic_decode',   'VIN'),
            ('20260629120000', 'vin_report_v2b_nhtsa_expanded_summary',   'VIN'),
            ('20260630120000', 'public_contact_projection_hardening',     'contact hardening')
           ) AS t(version, migration_name, category)
),
hosted AS (
    SELECT sm.version
      FROM supabase_migrations.schema_migrations sm
),
missing AS (
    SELECT e.version,
           e.migration_name,
           e.category,
           'insert into supabase_migrations.schema_migrations (version, name) values ('''
           || e.version
           || ''', '''
           || replace(e.migration_name, '''', '''''')
           || ''') on conflict (version) do nothing;' AS metadata_insert_sql
      FROM expected e
      LEFT JOIN hosted h ON h.version = e.version
     WHERE h.version IS NULL
),
missing_summary AS (
    SELECT COUNT(*)::bigint AS missing_count,
           COALESCE(
             string_agg(
               m.metadata_insert_sql,
               E'\n'
               ORDER BY m.version
             ),
             ''
           ) AS combined_sql
      FROM missing m
),
gate_rows AS (
    SELECT 0 AS sort_key,
           'gate'::text AS version,
           'runtime_contract_prerequisite'::text AS migration_name,
           'meta'::text AS category,
           'INFO'::text AS status,
           'Do NOT use generated INSERTs unless check_hosted_runtime_contracts.sql '
           || 'reports overall_runtime_contract_result = PASS (no STOP). '
           || 'If runtime STOP/WARN, fix objects first — metadata inserts will not help.'::text
           AS metadata_insert_sql

    UNION ALL

    SELECT 1,
           'gate',
           'owner_approval_required',
           'meta',
           'INFO',
           'This file does not execute INSERTs. Copy generated SQL to a NEW SQL Editor '
           || 'tab only after explicit owner approval. Do not re-run migration .sql files.'

    UNION ALL

    SELECT 2,
           'summary',
           'missing_metadata_count',
           'meta',
           'INFO',
           (SELECT missing_count FROM missing_summary)::text
           || ' repo migration version(s) missing from hosted schema_migrations. '
           || 'See per-row metadata_insert_sql below and combined block at end.'
),
per_missing AS (
    SELECT 10 AS sort_key,
           m.version,
           m.migration_name,
           m.category,
           'MISSING'::text AS status,
           m.metadata_insert_sql
      FROM missing m
),
combined_row AS (
    SELECT 98 AS sort_key,
           'combined'::text AS version,
           'all_missing_metadata_inserts'::text AS migration_name,
           'meta'::text AS category,
           CASE
             WHEN (SELECT missing_count FROM missing_summary) = 0 THEN 'NONE'
             ELSE 'COPY'
           END AS status,
           CASE
             WHEN (SELECT missing_count FROM missing_summary) = 0
             THEN '-- No missing metadata rows; parity should already PASS.'
             ELSE '-- RUN ONLY AFTER runtime contracts PASS and owner approval.'
                  || E'\n'
                  || (SELECT combined_sql FROM missing_summary)
           END AS metadata_insert_sql
),
done_row AS (
    SELECT 99 AS sort_key,
           'summary'::text AS version,
           'metadata_reconciliation_next_step'::text AS migration_name,
           'meta'::text AS category,
           CASE
             WHEN (SELECT missing_count FROM missing_summary) = 0 THEN 'PASS'
             ELSE 'PENDING'
           END AS status,
           CASE
             WHEN (SELECT missing_count FROM missing_summary) = 0
             THEN 'All 45 repo versions already recorded. Re-run check_hosted_migration_parity.sql to confirm.'
             ELSE 'Review generated INSERTs. After owner approval, run combined block in a separate '
                  || 'SQL Editor session. Then re-run check_hosted_migration_parity.sql → expect PASS.'
           END AS metadata_insert_sql
)
SELECT r.version,
       r.migration_name,
       r.category,
       r.status,
       r.metadata_insert_sql
  FROM (
        SELECT * FROM gate_rows
        UNION ALL
        SELECT * FROM per_missing
        UNION ALL
        SELECT * FROM combined_row
        UNION ALL
        SELECT * FROM done_row
       ) r
 ORDER BY r.sort_key,
          r.version;
