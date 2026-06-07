-- Read-only hosted runtime contract audit — single summary table for SQL Editor.
--
-- USE WHEN: check_hosted_migration_parity.sql reports STOP (missing schema_migrations
-- rows) but the app may still work if SQL was applied manually without metadata.
--
-- HOW TO RUN:
--   Supabase Dashboard → SQL Editor → paste this ENTIRE file → Run
--
-- OUTPUT:
--   One table: area | check_name | status | details
--   Screenshot or copy the FULL result (especially overall_runtime_contract_result).
--
--   PASS on overall → hosted DB contains app-critical runtime objects; metadata drift
--                     may still need reconciliation (see docs).
--   STOP on overall → at least one app-critical object is missing; do NOT release.
--   WARN on overall → no STOP, but optional/background objects need manual review.
--
-- SAFETY: SELECT / catalog introspection ONLY. No DML/DDL/GRANT/REVOKE.
-- Does NOT read or write supabase_migrations.schema_migrations for PASS/STOP.
-- Pair with: docs/hosted_migration_parity_verification.md

WITH
helpers AS (
    SELECT
        to_regclass('cron.job') AS cron_job_regclass
),
fn_exists AS (
    SELECT p.proname,
           bool_or(true) AS ok
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
     GROUP BY p.proname
),
fn_auth_exec AS (
    SELECT p.proname,
           bool_or(has_function_privilege('authenticated', p.oid, 'EXECUTE')) AS ok
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
     GROUP BY p.proname
),
fn_anon_exec AS (
    SELECT p.proname,
           bool_or(has_function_privilege('anon', p.oid, 'EXECUTE')) AS ok
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
     GROUP BY p.proname
),
col_exists AS (
    SELECT table_name,
           column_name,
           true AS ok
      FROM information_schema.columns
     WHERE table_schema = 'public'
),
tbl_exists AS (
    SELECT table_name,
           true AS ok
      FROM information_schema.tables
     WHERE table_schema = 'public'
       AND table_type = 'BASE TABLE'
),
rpc_record_listing_view AS (
    SELECT p.oid,
           pg_get_function_identity_arguments(p.oid) AS identity_args,
           pg_get_function_result(p.oid) AS result_type,
           oidvectortypes(p.proargtypes) AS arg_types
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname = 'record_listing_view'
     ORDER BY p.oid
     LIMIT 1
),
check_rows AS (
    -- meta -------------------------------------------------------------------
    SELECT 0 AS sort_key,
           'meta'::text AS area,
           'runtime_contract_scope'::text AS check_name,
           'INFO'::text AS status,
           'Read-only runtime object audit for Flutter client contracts. '
           || 'Does not use schema_migrations. Run after migration parity STOP '
           || 'to distinguish metadata drift from missing objects.'::text AS details

    UNION ALL

    SELECT 1, 'meta', 'migration_metadata_note', 'INFO',
           'Missing schema_migrations rows do NOT affect this helper. '
           || 'If overall here is PASS but parity helper is STOP, plan metadata '
           || 'reconciliation separately — not blind migration apply.'

    UNION ALL

    SELECT 2, 'meta', 'contact_hardening_reference', 'INFO',
           'Contact column grants / get_listing_public_contact: use '
           || 'supabase/maintenance/check_contact_hardening.sql separately.'

    -- listings / create / edit ------------------------------------------------
    UNION ALL

    SELECT 10, 'listings', 'table_listings',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listings')
                THEN 'PASS' ELSE 'STOP' END,
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listings')
                THEN 'public.listings exists'
                ELSE 'Missing public.listings — core feed/details blocked' END

    UNION ALL

    SELECT 11, 'listings', 'table_listing_images',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_images')
                THEN 'PASS' ELSE 'STOP' END,
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_images')
                THEN 'public.listing_images exists (create/edit v2 gallery)'
                ELSE 'Missing public.listing_images — multi-photo create/edit blocked' END

    UNION ALL

    SELECT 12, 'listings', 'column_listings_body_type',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'listings' AND c.column_name = 'body_type'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Client public select includes listings.body_type'

    UNION ALL

    SELECT 13, 'listings', 'column_listings_description',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'listings' AND c.column_name = 'description'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Client public select includes listings.description'

    UNION ALL

    SELECT 14, 'listings', 'column_listings_price_currency',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'listings' AND c.column_name = 'price_currency'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Required by create_listing_v2 / update_listing_details_v2'

    UNION ALL

    SELECT 15, 'listings', 'column_listings_updated_at',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'listings' AND c.column_name = 'updated_at'
                ) THEN 'PASS' ELSE 'WARN' END,
           'Not in public feed projection; missing may indicate partial May apply'

    UNION ALL

    SELECT 16, 'listings', 'column_listings_vin_status',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'listings' AND c.column_name = 'vin_status'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Client public select + VIN surfaces depend on listings.vin_status'

    UNION ALL

    SELECT 17, 'listings', 'rpc_create_listing_v2',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'create_listing_v2')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'create_listing_v2'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Primary create path (CreateListingCubit → create_listing_v2)'

    UNION ALL

    SELECT 18, 'listings', 'rpc_update_listing_details_v2',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'update_listing_details_v2')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'update_listing_details_v2'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Primary edit path (EditListingCubit → update_listing_details_v2)'

    UNION ALL

    SELECT 19, 'listings', 'rpc_replace_listing_images',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'replace_listing_images')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'replace_listing_images'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Gallery replace on create/edit'

    UNION ALL

    SELECT 20, 'listings', 'rpc_set_listing_status',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'set_listing_status')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'set_listing_status'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'My listings status changes'

    UNION ALL

    SELECT 21, 'listings', 'rpc_delete_listing',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'delete_listing')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'delete_listing'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'My listings delete'

    UNION ALL

    SELECT 22, 'listings', 'rpc_update_listing_cover_image',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'update_listing_cover_image')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'update_listing_cover_image'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Cover image updates'

    UNION ALL

    SELECT 23, 'listings', 'rpc_get_my_listing_for_edit',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_my_listing_for_edit')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_my_listing_for_edit'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Owner edit load path (contact hardening RPC)'

    UNION ALL

    SELECT 24, 'listings', 'rpc_get_my_listing_images_for_edit',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_my_listing_images_for_edit')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_my_listing_images_for_edit'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Owner gallery load for edit'

    UNION ALL

    SELECT 25, 'listings', 'rpc_create_listing_legacy', 'INFO',
           CASE
             WHEN EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'create_listing')
             THEN 'public.create_listing exists (legacy; app uses create_listing_v2)'
             ELSE 'Legacy create_listing absent — OK if v2 present'
           END

    UNION ALL

    SELECT 26, 'listings', 'trigger_listings_set_updated_at',
           CASE WHEN EXISTS (
                    SELECT 1
                      FROM pg_trigger t
                      JOIN pg_class c ON c.oid = t.tgrelid
                      JOIN pg_namespace n ON n.oid = c.relnamespace
                     WHERE n.nspname = 'public'
                       AND c.relname = 'listings'
                       AND NOT t.tgisinternal
                       AND t.tgname = 'listings_set_updated_at'
                ) THEN 'PASS' ELSE 'WARN' END,
           'Backend consistency trigger; not required for basic client reads'

    -- seller profiles ---------------------------------------------------------
    UNION ALL

    SELECT 30, 'seller profiles', 'table_seller_profiles',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'seller_profiles')
                THEN 'PASS' ELSE 'STOP' END,
           'Seller public profile + account identity'

    UNION ALL

    SELECT 31, 'seller profiles', 'seller_profiles_core_columns',
           CASE WHEN (
                    SELECT COUNT(*)
                      FROM col_exists c
                     WHERE c.table_name = 'seller_profiles'
                       AND c.column_name IN (
                           'user_id', 'display_name', 'avatar_url', 'seller_type',
                           'verified_phone', 'verified_email', 'created_at', 'updated_at'
                       )
                ) = 8 THEN 'PASS' ELSE 'STOP' END,
           'Expected seller_profiles columns for client models/RPCs'

    UNION ALL

    SELECT 32, 'seller profiles', 'rpc_get_seller_public_profile',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_seller_public_profile')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_anon_exec f WHERE f.proname = 'get_seller_public_profile'), false)
                  AND COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_seller_public_profile'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Listing details + seller page public reads'

    UNION ALL

    SELECT 33, 'seller profiles', 'rpc_get_my_seller_profile',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_my_seller_profile')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_my_seller_profile'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Profile account seller identity'

    UNION ALL

    SELECT 34, 'seller profiles', 'rpc_update_my_seller_display_name',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'update_my_seller_display_name')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'update_my_seller_display_name'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Display name self-edit'

    UNION ALL

    SELECT 35, 'seller profiles', 'rpc_update_my_seller_avatar',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'update_my_seller_avatar')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'update_my_seller_avatar'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Avatar upload metadata RPC'

    UNION ALL

    SELECT 36, 'seller profiles', 'rpc_clear_my_seller_avatar',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'clear_my_seller_avatar')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'clear_my_seller_avatar'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Avatar clear RPC'

    -- messaging ---------------------------------------------------------------
    UNION ALL

    SELECT 40, 'messaging', 'table_conversations',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'conversations')
                THEN 'PASS' ELSE 'STOP' END,
           'Inbox + thread header'

    UNION ALL

    SELECT 41, 'messaging', 'table_messages',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'messages')
                THEN 'PASS' ELSE 'STOP' END,
           'Thread message history'

    UNION ALL

    SELECT 42, 'messaging', 'table_user_conversation_state',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'user_conversation_state')
                THEN 'PASS' ELSE 'STOP' END,
           'Unread/read receipts'

    UNION ALL

    SELECT 43, 'messaging', 'rpc_get_or_create_conversation',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_or_create_conversation')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_or_create_conversation'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Open chat from listing details'

    UNION ALL

    SELECT 44, 'messaging', 'rpc_send_message',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'send_message')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'send_message'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Send chat message'

    UNION ALL

    SELECT 45, 'messaging', 'rpc_list_inbox_conversations',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'list_inbox_conversations')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'list_inbox_conversations'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Messages inbox'

    UNION ALL

    SELECT 46, 'messaging', 'rpc_mark_conversation_read',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'mark_conversation_read')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'mark_conversation_read'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Mark thread read'

    UNION ALL

    SELECT 47, 'messaging', 'rpc_get_unread_conversation_count',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_unread_conversation_count')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_unread_conversation_count'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Profile/menu unread badge'

    -- filter alerts -----------------------------------------------------------
    UNION ALL

    SELECT 50, 'filter alerts', 'table_filter_alert_settings',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'filter_alert_settings')
                THEN 'PASS' ELSE 'STOP' END,
           'Direct PostgREST CRUD from FilterAlertsRemoteDataSource'

    UNION ALL

    SELECT 51, 'filter alerts', 'filter_alert_settings_columns',
           CASE WHEN (
                    SELECT COUNT(*)
                      FROM col_exists c
                     WHERE c.table_name = 'filter_alert_settings'
                       AND c.column_name IN (
                           'user_id', 'criteria', 'notifications_enabled',
                           'created_at', 'updated_at'
                       )
                ) = 5 THEN 'PASS' ELSE 'STOP' END,
           'Client select/upsert columns'

    UNION ALL

    SELECT 52, 'filter alerts', 'rpc_claim_filter_alert_notification_events',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'claim_filter_alert_notification_events_for_processing'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'Background worker RPC (live filter push only; app settings work without it)'

    UNION ALL

    SELECT 53, 'filter alerts', 'cron_filter_alert_notifications',
           CASE
             WHEN (SELECT cron_job_regclass FROM helpers) IS NULL THEN 'WARN'
             WHEN EXISTS (
                    SELECT 1 FROM cron.job j
                     WHERE j.jobname = 'carzon_process_filter_alert_notifications_1m'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'pg_cron job for filter-alert Edge worker (optional unless live push)'

    -- notifications -----------------------------------------------------------
    UNION ALL

    SELECT 60, 'notifications', 'table_notification_preferences',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'notification_preferences')
                THEN 'PASS' ELSE 'STOP' END,
           'Notification settings page'

    UNION ALL

    SELECT 61, 'notifications', 'table_user_push_tokens',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'user_push_tokens')
                THEN 'PASS' ELSE 'STOP' END,
           'Push token registration when PUSH_NOTIFICATIONS_ENABLED'

    UNION ALL

    SELECT 62, 'notifications', 'rpc_get_my_notification_preferences',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_my_notification_preferences')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_my_notification_preferences'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Load notification settings'

    UNION ALL

    SELECT 63, 'notifications', 'rpc_update_my_notification_preferences',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'update_my_notification_preferences')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'update_my_notification_preferences'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Save notification toggles'

    UNION ALL

    SELECT 64, 'notifications', 'rpc_register_push_token',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'register_push_token')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'register_push_token'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'FCM/APNs token registration RPC'

    UNION ALL

    SELECT 65, 'notifications', 'rpc_deactivate_my_push_tokens',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'deactivate_my_push_tokens')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'deactivate_my_push_tokens'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Sign-out token cleanup'

    UNION ALL

    SELECT 66, 'notifications', 'table_notification_delivery_events',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'notification_delivery_events')
                THEN 'PASS' ELSE 'WARN' END,
           'Message/filter push queue — WARN if absent (in-app chat still works)'

    UNION ALL

    SELECT 67, 'notifications', 'rpc_claim_notification_events_for_processing',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'claim_notification_events_for_processing'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'Edge worker claim RPC (service_role); not client-called'

    UNION ALL

    SELECT 68, 'notifications', 'cron_message_notifications',
           CASE
             WHEN (SELECT cron_job_regclass FROM helpers) IS NULL THEN 'WARN'
             WHEN EXISTS (
                    SELECT 1 FROM cron.job j
                     WHERE j.jobname = 'carzon_process_message_notifications_1m'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'pg_cron job for message push worker (optional unless live push)'

    -- VIN ---------------------------------------------------------------------
    UNION ALL

    SELECT 70, 'VIN', 'table_listing_vehicle_identity',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_vehicle_identity')
                THEN 'PASS' ELSE 'STOP' END,
           'Owner-private VIN storage (edit flow)'

    UNION ALL

    SELECT 71, 'VIN', 'table_listing_vin_report_snapshot',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_vin_report_snapshot')
                THEN 'PASS' ELSE 'STOP' END,
           'Owner/buyer VIN report summaries'

    UNION ALL

    SELECT 72, 'VIN', 'table_listing_vin_source_results',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_vin_source_results')
                THEN 'PASS' ELSE 'STOP' END,
           'Owner source results section on edit listing'

    UNION ALL

    SELECT 73, 'VIN', 'table_vin_processing_jobs',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'vin_processing_jobs')
                THEN 'PASS' ELSE 'WARN' END,
           'Decode queue — WARN if absent (VIN entry still possible; decode may not run)'

    UNION ALL

    SELECT 74, 'VIN', 'rpc_get_my_listing_vehicle_identity',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_my_listing_vehicle_identity')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_my_listing_vehicle_identity'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Owner VIN field prefill on edit'

    UNION ALL

    SELECT 75, 'VIN', 'rpc_get_my_listing_vin_report_status',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_my_listing_vin_report_status')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_my_listing_vin_report_status'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Owner VIN status panel on edit listing'

    UNION ALL

    SELECT 76, 'VIN', 'rpc_get_my_listing_vin_source_results',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_my_listing_vin_source_results')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_my_listing_vin_source_results'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Owner VIN source results on edit listing'

    UNION ALL

    SELECT 77, 'VIN', 'rpc_get_listing_vin_report_for_buyer',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_listing_vin_report_for_buyer')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_anon_exec f WHERE f.proname = 'get_listing_vin_report_for_buyer'), false)
                  AND COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_listing_vin_report_for_buyer'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Buyer VIN report on listing details (fails soft in client if broken)'

    UNION ALL

    SELECT 78, 'VIN', 'rpc_claim_vin_decode_jobs_for_processing',
           CASE
             WHEN EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'claim_vin_decode_jobs_for_processing')
             THEN 'PASS'
             ELSE 'WARN'
           END,
           'Background VIN worker RPC (service_role)'

    UNION ALL

    SELECT 79, 'VIN', 'cron_vin_decode_jobs',
           CASE
             WHEN (SELECT cron_job_regclass FROM helpers) IS NULL THEN 'WARN'
             WHEN EXISTS (
                    SELECT 1 FROM cron.job j
                     WHERE j.jobname = 'carzon_process_vin_decode_jobs_5m'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'pg_cron VIN decode scheduler (decode completion optional for MVP browse)'

    UNION ALL

    SELECT 80, 'listings', 'column_listings_view_count',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'listings' AND c.column_name = 'view_count'
                ) THEN 'PASS' ELSE 'WARN' END,
           'Public listing details metadata reads listings.view_count'

    UNION ALL

    SELECT 81, 'listings', 'rpc_record_listing_view',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_record_listing_view)
             THEN 'WARN'
             WHEN NOT has_function_privilege('anon', (SELECT oid FROM rpc_record_listing_view), 'EXECUTE')
                  OR NOT has_function_privilege('authenticated', (SELECT oid FROM rpc_record_listing_view), 'EXECUTE')
             THEN 'WARN'
             ELSE 'PASS'
           END,
           'Listing details view recording RPC EXECUTE for anon + authenticated'

    UNION ALL

    SELECT 84, 'listings', 'rpc_record_listing_view_signature',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_record_listing_view)
             THEN 'WARN'
             WHEN (SELECT arg_types FROM rpc_record_listing_view) IS DISTINCT FROM 'uuid, text'
             THEN 'WARN'
             ELSE 'PASS'
           END,
           'record_listing_view(uuid, text) — expected arg types uuid, text; '
           || 'identity: '
           || coalesce((SELECT identity_args FROM rpc_record_listing_view), '(missing)')

    UNION ALL

    SELECT 85, 'listings', 'rpc_record_listing_view_return_columns',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_record_listing_view)
             THEN 'WARN'
             WHEN lower(coalesce((SELECT result_type FROM rpc_record_listing_view), '')) NOT LIKE '%total_views%integer%'
                  OR lower(coalesce((SELECT result_type FROM rpc_record_listing_view), '')) NOT LIKE '%today_views%integer%'
             THEN 'WARN'
             ELSE 'PASS'
           END,
           'RETURNS TABLE(total_views integer, today_views integer); '
           || 'actual: '
           || coalesce((SELECT result_type FROM rpc_record_listing_view), '(missing)')

    UNION ALL

    SELECT 82, 'listings', 'table_listing_view_daily',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_view_daily')
                THEN 'PASS' ELSE 'WARN' END,
           'Moldova-local daily view buckets (RPC-only writes)'

    UNION ALL

    SELECT 83, 'listings', 'table_listing_view_dedupe',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_view_dedupe')
                THEN 'PASS' ELSE 'WARN' END,
           'Per-viewer per-day dedupe store (hashed viewer identity)'

    -- grants / security reference ---------------------------------------------
    UNION ALL

    SELECT 90, 'grants', 'rpc_get_listing_public_contact',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'get_listing_public_contact')
             THEN 'WARN'
             WHEN COALESCE((SELECT ok FROM fn_anon_exec f WHERE f.proname = 'get_listing_public_contact'), false)
                  AND COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'get_listing_public_contact'), false)
             THEN 'PASS'
             ELSE 'WARN'
           END,
           'Contact reveal RPC; full grant/column audit in check_contact_hardening.sql'

    UNION ALL

    SELECT 91, 'grants', 'authenticated_filter_alert_settings_dml',
           CASE
             WHEN has_table_privilege('authenticated', 'public.filter_alert_settings', 'SELECT')
                  AND has_table_privilege('authenticated', 'public.filter_alert_settings', 'INSERT')
                  AND has_table_privilege('authenticated', 'public.filter_alert_settings', 'UPDATE')
             THEN 'PASS'
             WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'filter_alert_settings')
             THEN 'WARN'
             ELSE 'STOP'
           END,
           'Direct table grants from explicit_data_api_grants / filter_alert_settings migration'

    UNION ALL

    SELECT 92, 'grants', 'listing_view_analytics_not_client_exposed',
           CASE
             WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_view_daily')
                  AND EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_view_dedupe')
                  AND NOT has_table_privilege('anon', 'public.listing_view_daily', 'SELECT')
                  AND NOT has_table_privilege('authenticated', 'public.listing_view_daily', 'SELECT')
                  AND NOT has_table_privilege('anon', 'public.listing_view_dedupe', 'SELECT')
                  AND NOT has_table_privilege('authenticated', 'public.listing_view_dedupe', 'SELECT')
             THEN 'PASS'
             WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_view_daily')
                  OR EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'listing_view_dedupe')
             THEN 'WARN'
             ELSE 'WARN'
           END,
           'Analytics tables must not be direct PostgREST surfaces for anon/authenticated'
),
blocking AS (
    SELECT COUNT(*) FILTER (WHERE status = 'STOP') AS stop_count,
           COUNT(*) FILTER (WHERE status = 'WARN') AS warn_count
      FROM check_rows
)
SELECT cr.area,
       cr.check_name,
       cr.status,
       cr.details
  FROM (
        SELECT * FROM check_rows
        UNION ALL
        SELECT 99,
               'summary',
               'overall_runtime_contract_result',
               CASE
                 WHEN (SELECT stop_count FROM blocking) > 0 THEN 'STOP'
                 WHEN (SELECT warn_count FROM blocking) > 0 THEN 'WARN'
                 ELSE 'PASS'
               END,
               CASE
                 WHEN (SELECT stop_count FROM blocking) > 0
                 THEN (SELECT stop_count FROM blocking)::text
                      || ' app-critical STOP check(s). Hosted runtime contract incomplete — '
                      || 'plan targeted apply for missing groups; do NOT bulk-apply 33 migrations blindly.'
                 WHEN (SELECT warn_count FROM blocking) > 0
                 THEN 'No STOP; '
                      || (SELECT warn_count FROM blocking)::text
                      || ' WARN check(s) (cron/background/optional). Review before declaring live push/VIN decode.'
                 ELSE 'All app-critical runtime contracts present. If migration parity is STOP, '
                      || 'treat as metadata drift — plan schema_migrations reconciliation, not re-apply.'
               END
       ) cr
 ORDER BY cr.sort_key,
          cr.check_name;
