-- Read-only hosted migration parity check — single summary table for SQL Editor.
--
-- HOW TO RUN:
--   Supabase Dashboard → SQL Editor → paste this ENTIRE file → Run
--
-- OUTPUT:
--   One table: version | migration_name | category | status | details
--   Screenshot or copy the FULL result (especially hosted_migration_parity_result).
--
--   PASS on overall → all repo migrations are recorded in schema_migrations.
--   STOP on overall → one or more repo migrations are missing; do NOT auto-apply.
--
-- SAFETY: SELECT / CTE / VALUES ONLY. No DML/DDL/GRANT/REVOKE.
-- Pair with: docs/hosted_migration_parity_verification.md
--
-- NOTE: Compares by version only (stable). Hosted `name` may differ from repo
-- filename suffix; that does not affect PASS as long as version matches.

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
            ('20260630120000', 'public_contact_projection_hardening',     'contact hardening'),
            ('20260701120000', 'listing_view_counting',                   'listings'),
            ('20260702120000', 'support_conversations',                   'messaging'),
            ('20260703120000', 'chat_attachments_foundation',             'messaging'),
            ('20260704120000', 'chat_attachments_size_hardening',           'messaging'),
            ('20260705120000', 'listing_discovery_search_title_make_model','listings'),
            ('20260706120000', 'vehicle_model_data_foundation',             'official data'),
            ('20260706123000', 'schedule_process_model_data_jobs_cron',     'official data'),
            ('20260706130000', 'model_data_buyer_rpc_volatile',             'official data'),
            ('20260706133000', 'model_data_buyer_rpc_safe_summary',         'official data'),
            ('20260707120000', 'vehicle_recall_data_foundation',            'official data'),
            ('20260707123000', 'schedule_process_recall_data_jobs_cron',    'official data'),
            ('20260708120000', 'vin_create_rpc_explicit_enqueue',           'VIN'),
            ('20260709120000', 'buyer_official_data_pending_signals',       'official data'),
            ('20260710120000', 'model_fetch_vin_identity_hints',            'official data'),
            ('20260711120000', 'listing_transmission_type',                 'listings'),
            ('20260712120000', 'discovery_fuel_transmission_filter_alert',  'filter alerts'),
            ('20260713120000', 'delete_own_account',                        'account privacy'),
            ('20260713130000', 'delete_own_account_storage_delete_bypass',  'account privacy'),
            ('20260714120000', 'messaging_user_blocks_and_reports',         'messaging'),
            ('20260801120000', 'saved_searches_table_and_backfill',         'filter alerts'),
            ('20260802120000', 'price_drop_favorite_notifications',         'notifications'),
            ('20260803120000', 'discovery_drivetrain_filter_alert',         'filter alerts'),
            ('20260822120000', 'fuel_prices_foundation',                    'fuel prices'),
            ('20260822123000', 'schedule_process_fuel_price_jobs_cron',     'fuel prices'),
            ('20260822130000', 'fix_fuel_price_job_reenqueue',              'fuel prices'),
            ('20260823120000', 'retain_pseudonymized_moderation_reports',    'moderation'),
            ('20260826120000', 'app_store_content_moderation_foundation',     'moderation'),
            ('20260824120000', 'exclusive_active_push_token_ownership',      'notifications'),
            ('20260825120000', 'reduce_idle_background_worker_io',           'operations')
           ) AS t(version, migration_name, category)
),
hosted AS (
    SELECT sm.version,
           sm.name AS hosted_name
      FROM supabase_migrations.schema_migrations sm
),
parity_rows AS (
    SELECT e.version,
           e.migration_name,
           e.category,
           CASE
             WHEN h.version IS NOT NULL THEN 'PASS'
             ELSE 'STOP'
           END AS status,
           CASE
             WHEN h.version IS NOT NULL
             THEN 'Recorded in supabase_migrations.schema_migrations'
                  || CASE
                       WHEN h.hosted_name IS NOT NULL
                            AND h.hosted_name <> e.migration_name
                       THEN ' (hosted name: ' || h.hosted_name || ')'
                       ELSE ''
                     END
             ELSE 'Missing from hosted schema_migrations — do not auto-apply; report version to owner'
           END AS details,
           10 AS sort_key
      FROM expected e
      LEFT JOIN hosted h ON h.version = e.version
),
orphan_hosted AS (
    SELECT h.version,
           COALESCE(h.hosted_name, '(no name)') AS hosted_name
      FROM hosted h
      LEFT JOIN expected e ON e.version = h.version
     WHERE e.version IS NULL
),
orphan_summary AS (
    SELECT COUNT(*)::bigint AS orphan_count,
           COALESCE(
             string_agg(
               o.version || COALESCE(' (' || o.hosted_name || ')', ''),
               '; '
               ORDER BY o.version
             ),
             ''
           ) AS orphan_list
      FROM orphan_hosted o
),
info_rows AS (
    SELECT 'info'::text AS version,
           'parity_check_scope'::text AS migration_name,
           'meta'::text AS category,
           'INFO'::text AS status,
           'Read-only parity check for 74 repo migrations under supabase/migrations/. '
           || 'Compares hosted supabase_migrations.schema_migrations by version only. '
           || 'Staging preferred; safe on a single production project (SELECT only).'::text
           AS details,
           0 AS sort_key

    UNION ALL

    SELECT 'info',
           'hosted_only_migrations',
           'meta',
           'INFO',
           CASE
             WHEN (SELECT orphan_count FROM orphan_summary) = 0
             THEN 'No extra hosted migration versions outside repo inventory.'
             ELSE (SELECT orphan_count FROM orphan_summary)::text
                  || ' hosted-only version(s) not in repo inventory: '
                  || (SELECT orphan_list FROM orphan_summary)
                  || '. Review manually; does not fail overall parity.'
           END,
           1
),
missing_summary AS (
    SELECT COUNT(*) FILTER (WHERE status = 'STOP')::bigint AS missing_count,
           COALESCE(
             string_agg(
               pr.version,
               ', '
               ORDER BY pr.version
             )
             FILTER (WHERE pr.status = 'STOP'),
             ''
           ) AS missing_versions
      FROM parity_rows pr
),
all_rows AS (
    SELECT ir.version,
           ir.migration_name,
           ir.category,
           ir.status,
           ir.details,
           ir.sort_key
      FROM info_rows ir

    UNION ALL

    SELECT pr.version,
           pr.migration_name,
           pr.category,
           pr.status,
           pr.details,
           pr.sort_key
      FROM parity_rows pr

    UNION ALL

    SELECT 'overall',
           'hosted_migration_parity_result',
           'summary',
           CASE
             WHEN (SELECT missing_count FROM missing_summary) = 0 THEN 'PASS'
             ELSE 'STOP'
           END,
           CASE
             WHEN (SELECT missing_count FROM missing_summary) = 0
             THEN (SELECT COUNT(*) FROM expected)::text
                  || '/'
                  || (SELECT COUNT(*) FROM expected)::text
                  || ' repo migrations recorded. Proceed to feature-specific verification '
                  || '(contact hardening helper, manual release smoke). '
                  || 'Metadata parity does not prove every RPC works at runtime.'
             ELSE (SELECT missing_count FROM missing_summary)::text
                  || ' missing migration(s): '
                  || (SELECT missing_versions FROM missing_summary)
                  || '. STOP — do not auto-apply migrations. '
                  || 'Report missing versions and plan apply separately, one group at a time.'
           END,
           99
)
SELECT ar.version,
       ar.migration_name,
       ar.category,
       ar.status,
       ar.details
  FROM all_rows ar
 ORDER BY ar.sort_key,
          ar.version;
