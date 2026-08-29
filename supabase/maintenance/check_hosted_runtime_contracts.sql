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

    UNION ALL

    SELECT 27, 'moderation', 'table_listing_reports',
           CASE WHEN EXISTS (
                    SELECT 1 FROM tbl_exists t
                     WHERE t.table_name = 'listing_reports'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Structured listing-report storage; direct client table access must remain revoked'

    UNION ALL

    SELECT 28, 'moderation', 'rpc_report_listing',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'report_listing')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'report_listing'), false)
                  AND NOT COALESCE((SELECT ok FROM fn_anon_exec f WHERE f.proname = 'report_listing'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Native listing reporting requires authenticated EXECUTE and no anon EXECUTE'

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

    UNION ALL

    SELECT 48, 'messaging', 'column_conversations_conversation_kind',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'conversations'
                       AND c.column_name = 'conversation_kind'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Support vs listing threads (settings support chat)'

    UNION ALL

    SELECT 49, 'messaging', 'rpc_get_or_create_support_conversation',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'get_or_create_support_conversation'
                ) THEN 'STOP'
             WHEN COALESCE(
                    (SELECT ok FROM fn_auth_exec f
                      WHERE f.proname = 'get_or_create_support_conversation'),
                    false
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Settings → Contact support thread'

    UNION ALL

    SELECT 491, 'messaging', 'table_message_attachments',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'message_attachments')
                THEN 'PASS' ELSE 'STOP' END,
           'Chat attachment metadata (RPC-only writes)'

    UNION ALL

    SELECT 492, 'messaging', 'rpc_send_message_with_attachment',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'send_message_with_attachment'
                ) THEN 'STOP'
             WHEN COALESCE(
                    (SELECT ok FROM fn_auth_exec f
                      WHERE f.proname = 'send_message_with_attachment'),
                    false
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Send chat message with attachment metadata'

    UNION ALL

    SELECT 493, 'messaging', 'storage_bucket_chat_attachments',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM storage.buckets b
                     WHERE b.id = 'chat-attachments'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'Private chat-attachments bucket (WARN if migrations not fully applied)'

    UNION ALL

    SELECT 494, 'messaging', 'table_user_blocks',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'user_blocks')
                THEN 'PASS' ELSE 'STOP' END,
           'User block safety (RPC-only mutations)'

    UNION ALL

    SELECT 495, 'messaging', 'table_user_reports',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'user_reports')
                THEN 'PASS' ELSE 'STOP' END,
           'User report safety (insert via report_user RPC only)'

    UNION ALL

    SELECT 496, 'messaging', 'rpc_block_user',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'block_user')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'block_user'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Thread safety overflow → block peer'

    UNION ALL

    SELECT 497, 'messaging', 'rpc_unblock_user',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'unblock_user')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'unblock_user'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Blocked users list → unblock'

    UNION ALL

    SELECT 498, 'messaging', 'rpc_list_blocked_users',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'list_blocked_users')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'list_blocked_users'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Settings → blocked users screen'

    UNION ALL

    SELECT 499, 'messaging', 'rpc_report_user',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'report_user')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'report_user'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Thread safety overflow → report peer'

    UNION ALL

    SELECT 4991, 'messaging', 'fn_carzon_users_are_blocked',
           CASE
             WHEN EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'carzon_users_are_blocked')
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Internal block gate helper (send/enqueue paths depend on it)'

    UNION ALL

    SELECT 4992, 'messaging', 'fn_carzon_messaging_peer_from_conversation',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'carzon_messaging_peer_from_conversation'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Internal peer resolver for block/report RPCs'

    UNION ALL

    SELECT 4993, 'messaging', 'fn_enqueue_message_notification_event',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'enqueue_message_notification_event'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'Message push enqueue trigger function (must include block gate after M0.3 migration)'

    -- account privacy ---------------------------------------------------------
    UNION ALL

    SELECT 4995, 'account privacy', 'rpc_delete_own_account',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'delete_own_account')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'delete_own_account'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Settings → delete account (Edge Function also calls this RPC)'

    -- filter alerts -----------------------------------------------------------
    UNION ALL

    SELECT 50, 'filter alerts', 'table_filter_alert_settings',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'filter_alert_settings')
                THEN 'PASS' ELSE 'WARN' END,
           'Legacy v1 table retained for backfill only — active UX uses saved_searches'

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
                ) = 5 THEN 'PASS' ELSE 'WARN' END,
           'Legacy filter_alert_settings columns (backfill source for saved_searches v2)'

    UNION ALL

    SELECT 511, 'filter alerts', 'table_saved_searches',
           CASE WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'saved_searches')
                THEN 'PASS' ELSE 'STOP' END,
           'P1 M1.4 active saved-search model (up to 5 per user)'

    UNION ALL

    SELECT 512, 'filter alerts', 'saved_searches_core_columns',
           CASE WHEN (
                    SELECT COUNT(*)
                      FROM col_exists c
                     WHERE c.table_name = 'saved_searches'
                       AND c.column_name IN (
                           'id', 'user_id', 'name', 'criteria', 'alerts_enabled',
                           'created_at', 'updated_at', 'last_notified_at'
                       )
                ) = 8 THEN 'PASS' ELSE 'STOP' END,
           'saved_searches columns for SavedSearchesCubit / FilterAlertsRemoteDataSource'

    UNION ALL

    SELECT 513, 'filter alerts', 'meta_saved_searches_v2_active_model', 'INFO',
           'Active client UX: saved_searches RPCs (list/create/update/delete/set alerts). '
           || 'filter_alert_settings is legacy/backfill-only after 20260801120000.'

    UNION ALL

    SELECT 514, 'filter alerts', 'rpc_list_my_saved_searches',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'list_my_saved_searches')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'list_my_saved_searches'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Load saved searches manager screen'

    UNION ALL

    SELECT 515, 'filter alerts', 'rpc_create_saved_search',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'create_saved_search')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'create_saved_search'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Catalog bell → save current discovery criteria'

    UNION ALL

    SELECT 516, 'filter alerts', 'rpc_update_saved_search',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'update_saved_search')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'update_saved_search'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Edit saved search name/criteria/alerts'

    UNION ALL

    SELECT 517, 'filter alerts', 'rpc_delete_saved_search',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM fn_exists f WHERE f.proname = 'delete_saved_search')
             THEN 'STOP'
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'delete_saved_search'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'Remove saved search row'

    UNION ALL

    SELECT 518, 'filter alerts', 'rpc_set_saved_search_alerts_enabled',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'set_saved_search_alerts_enabled'
                ) THEN 'STOP'
             WHEN COALESCE(
                    (SELECT ok FROM fn_auth_exec f
                      WHERE f.proname = 'set_saved_search_alerts_enabled'),
                    false
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Toggle push alerts per saved search'

    UNION ALL

    SELECT 519, 'filter alerts', 'rpc_find_saved_search_by_criteria',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'find_saved_search_by_criteria'
                ) THEN 'STOP'
             WHEN COALESCE(
                      (SELECT ok FROM fn_auth_exec f
                        WHERE f.proname = 'find_saved_search_by_criteria'),
                      false
                  ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Catalog bell duplicate detection by criteria JSON'

    UNION ALL

    SELECT 520, 'filter alerts', 'fn_listing_matches_saved_discovery_criteria_drivetrain',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'listing_matches_saved_discovery_criteria'
                ) THEN 'STOP'
             WHEN EXISTS (
                    SELECT 1
                      FROM pg_proc p
                      JOIN pg_namespace n ON n.oid = p.pronamespace
                     WHERE n.nspname = 'public'
                       AND p.proname = 'listing_matches_saved_discovery_criteria'
                       AND pg_get_functiondef(p.oid) ILIKE '%drivetrain%'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Saved-search/filter-alert matcher supports optional drivetrain criteria key'

    UNION ALL

    SELECT 52, 'filter alerts', 'rpc_claim_filter_alert_notification_events',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'claim_filter_alert_notification_events_for_processing'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Background worker RPC (filter-alert Edge worker; saved_searches enqueue path)'

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
                THEN 'PASS' ELSE 'STOP' END,
           'Message/filter/price-drop push queue — required for live notification delivery'

    UNION ALL

    SELECT 681, 'notifications', 'column_notification_preferences_price_drops_enabled',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'notification_preferences'
                       AND c.column_name = 'price_drops_enabled'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Opt-in price drop alerts toggle (default false after 20260802120000)'

    UNION ALL

    SELECT 682, 'notifications', 'event_type_price_drop_favorite',
           CASE
             WHEN EXISTS (
                    SELECT 1
                      FROM pg_constraint c
                      JOIN pg_class t ON t.oid = c.conrelid
                      JOIN pg_namespace n ON n.oid = t.relnamespace
                     WHERE n.nspname = 'public'
                       AND t.relname = 'notification_delivery_events'
                       AND c.conname = 'notification_delivery_events_event_type_chk'
                       AND pg_get_constraintdef(c.oid) ILIKE '%price_drop_favorite%'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Queue event_type allows price_drop_favorite'

    UNION ALL

    SELECT 683, 'notifications', 'index_notification_delivery_events_price_drop_dedup',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM pg_indexes i
                     WHERE i.schemaname = 'public'
                       AND i.indexname = 'notification_delivery_events_price_drop_dedup_idx'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Dedup one event per recipient + listing + new price transition'

    UNION ALL

    SELECT 684, 'notifications', 'fn_enqueue_price_drop_favorite_notification_events',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'enqueue_price_drop_favorite_notification_events'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Enqueue on listing price decrease (update_listing_details_v2 path)'

    UNION ALL

    SELECT 685, 'notifications', 'rpc_claim_price_drop_notification_events_for_processing',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'claim_price_drop_notification_events_for_processing'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Background worker RPC (price-drop Edge worker; service_role only)'

    UNION ALL

    SELECT 686, 'notifications', 'fn_carzon_invoke_process_price_drop_notifications_worker',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'carzon_invoke_process_price_drop_notifications_worker'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'pg_cron/pg_net invoke helper for process-price-drop-notifications'

    UNION ALL

    SELECT 687, 'notifications', 'cron_price_drop_notifications',
           CASE
             WHEN (SELECT cron_job_regclass FROM helpers) IS NULL THEN 'WARN'
             WHEN EXISTS (
                    SELECT 1 FROM cron.job j
                     WHERE j.jobname = 'carzon_process_price_drop_notifications_1m'
                       AND j.schedule = '* * * * *'
                ) THEN 'PASS'
             WHEN EXISTS (
                    SELECT 1 FROM cron.job j
                     WHERE j.jobname = 'carzon_process_price_drop_notifications_1m'
                ) THEN 'WARN'
             ELSE 'WARN'
           END,
           'pg_cron job for price-drop Edge worker (optional unless live push)'

    UNION ALL

    SELECT 688, 'notifications', 'grants_enqueue_price_drop_not_client',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'enqueue_price_drop_favorite_notification_events'
                ) THEN 'WARN'
             WHEN EXISTS (
                    SELECT 1
                      FROM pg_proc p
                      JOIN pg_namespace n ON n.oid = p.pronamespace
                     WHERE n.nspname = 'public'
                       AND p.proname = 'enqueue_price_drop_favorite_notification_events'
                       AND (
                           has_function_privilege('authenticated', p.oid, 'EXECUTE')
                           OR has_function_privilege('anon', p.oid, 'EXECUTE')
                       )
                ) THEN 'STOP'
             ELSE 'PASS'
           END,
           'enqueue_price_drop_favorite_notification_events must not be client EXECUTE'

    UNION ALL

    SELECT 689, 'notifications', 'grants_claim_price_drop_not_client',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'claim_price_drop_notification_events_for_processing'
                ) THEN 'WARN'
             WHEN EXISTS (
                    SELECT 1
                      FROM pg_proc p
                      JOIN pg_namespace n ON n.oid = p.pronamespace
                     WHERE n.nspname = 'public'
                       AND p.proname = 'claim_price_drop_notification_events_for_processing'
                       AND (
                           has_function_privilege('authenticated', p.oid, 'EXECUTE')
                           OR has_function_privilege('anon', p.oid, 'EXECUTE')
                       )
                ) THEN 'STOP'
             ELSE 'PASS'
           END,
           'claim_price_drop_notification_events_for_processing must not be client EXECUTE'

    UNION ALL

    SELECT 690, 'notifications', 'edge_process_price_drop_notifications_contract', 'INFO',
           'Edge Function process-price-drop-notifications must be deployed ACTIVE with '
           || 'verify_jwt=false (see supabase/config.toml). Not introspectable from Postgres; '
           || 'verify via Dashboard or curl smoke after Vault secrets are set.'

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
                THEN 'PASS' ELSE 'STOP' END,
           'VIN decode queue — create/edit explicit enqueue depends on worker drain'

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
                ) THEN 'PASS' ELSE 'STOP' END,
           'Public listing details metadata reads listings.view_count'

    UNION ALL

    SELECT 801, 'listings', 'column_listings_transmission_type',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'listings'
                       AND c.column_name = 'transmission_type'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Discovery filter + listing details transmission field'

    UNION ALL

    SELECT 802, 'listings', 'column_listings_drivetrain',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'listings'
                       AND c.column_name = 'drivetrain'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Discovery filter + listing details drivetrain field'

    UNION ALL

    SELECT 803, 'listings', 'index_listings_feed_active_region_drivetrain_created',
           CASE WHEN EXISTS (
                    SELECT 1 FROM pg_indexes i
                     WHERE i.schemaname = 'public'
                       AND i.indexname = 'listings_feed_active_region_drivetrain_created_idx'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Partial index for active feed drivetrain filter (20260803120000)'

    UNION ALL

    SELECT 81, 'listings', 'rpc_record_listing_view',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_record_listing_view)
             THEN 'STOP'
             WHEN NOT has_function_privilege('anon', (SELECT oid FROM rpc_record_listing_view), 'EXECUTE')
                  OR NOT has_function_privilege('authenticated', (SELECT oid FROM rpc_record_listing_view), 'EXECUTE')
             THEN 'STOP'
             ELSE 'PASS'
           END,
           'Listing details view recording RPC EXECUTE for anon + authenticated'

    UNION ALL

    SELECT 84, 'listings', 'rpc_record_listing_view_signature',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_record_listing_view)
             THEN 'STOP'
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
             THEN 'STOP'
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

    -- official data (model passport + recall) ---------------------------------
    UNION ALL

    SELECT 94, 'official data', 'table_vehicle_model_fetch_jobs',
           CASE WHEN EXISTS (
                    SELECT 1 FROM tbl_exists t
                     WHERE t.table_name = 'vehicle_model_fetch_jobs'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Model Passport background fetch queue'

    UNION ALL

    SELECT 941, 'official data', 'column_vehicle_model_fetch_jobs_listing_id',
           CASE WHEN EXISTS (
                    SELECT 1 FROM col_exists c
                     WHERE c.table_name = 'vehicle_model_fetch_jobs'
                       AND c.column_name = 'listing_id'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Optional listing_id on jobs (VIN decode hints for EPA candidates)'

    UNION ALL

    SELECT 942, 'official data', 'table_vehicle_model_source_cache',
           CASE WHEN EXISTS (
                    SELECT 1 FROM tbl_exists t
                     WHERE t.table_name = 'vehicle_model_source_cache'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Sanitized Model Passport cache rows'

    UNION ALL

    SELECT 943, 'official data', 'table_vehicle_recall_fetch_jobs',
           CASE WHEN EXISTS (
                    SELECT 1 FROM tbl_exists t
                     WHERE t.table_name = 'vehicle_recall_fetch_jobs'
                ) THEN 'PASS' ELSE 'WARN' END,
           'Recall campaign fetch queue (WARN if recall section hidden only)'

    UNION ALL

    SELECT 944, 'official data', 'table_vehicle_recall_source_cache',
           CASE WHEN EXISTS (
                    SELECT 1 FROM tbl_exists t
                     WHERE t.table_name = 'vehicle_recall_source_cache'
                ) THEN 'PASS' ELSE 'STOP' END,
           'Model/year recall campaign cache (not VIN-level status)'

    UNION ALL

    SELECT 945, 'official data', 'rpc_get_listing_model_data_for_buyer',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'get_listing_model_data_for_buyer'
                ) THEN 'STOP'
             WHEN COALESCE(
                    (SELECT ok FROM fn_anon_exec f
                      WHERE f.proname = 'get_listing_model_data_for_buyer'),
                    false
                )
                  AND COALESCE(
                    (SELECT ok FROM fn_auth_exec f
                      WHERE f.proname = 'get_listing_model_data_for_buyer'),
                    false
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Buyer Model Passport section on listing details'

    UNION ALL

    SELECT 946, 'official data', 'rpc_get_listing_recalls_for_buyer',
           CASE
             WHEN NOT EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'get_listing_recalls_for_buyer'
                ) THEN 'STOP'
             WHEN COALESCE(
                    (SELECT ok FROM fn_anon_exec f
                      WHERE f.proname = 'get_listing_recalls_for_buyer'),
                    false
                )
                  AND COALESCE(
                    (SELECT ok FROM fn_auth_exec f
                      WHERE f.proname = 'get_listing_recalls_for_buyer'),
                    false
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Buyer recall campaigns section (model/year only; not exact-vehicle status)'

    UNION ALL

    SELECT 947, 'official data', 'fn_get_listing_vin_model_fetch_hints',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'get_listing_vin_model_fetch_hints'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Worker-only VIN hints RPC (service_role; must exist after model_fetch migration)'

    UNION ALL

    SELECT 948, 'VIN', 'fn_carzon_enqueue_vin_decode_from_identity',
           CASE
             WHEN EXISTS (
                    SELECT 1 FROM fn_exists f
                     WHERE f.proname = 'carzon_enqueue_vin_decode_from_identity'
                ) THEN 'PASS'
             ELSE 'STOP'
           END,
           'Explicit VIN decode enqueue helper (create_listing_v2 / update_listing_details_v2)'

    UNION ALL

    SELECT 949, 'official data', 'cron_model_data_jobs',
           CASE
             WHEN (SELECT cron_job_regclass FROM helpers) IS NULL THEN 'WARN'
             WHEN EXISTS (
                    SELECT 1 FROM cron.job j
                     WHERE j.jobname = 'carzon_process_model_data_jobs_30m'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'pg_cron Model Passport worker (optional unless live official data)'

    UNION ALL

    SELECT 9491, 'official data', 'cron_recall_data_jobs',
           CASE
             WHEN (SELECT cron_job_regclass FROM helpers) IS NULL THEN 'WARN'
             WHEN EXISTS (
                    SELECT 1 FROM cron.job j
                     WHERE j.jobname = 'carzon_process_recall_data_jobs_30m'
                ) THEN 'PASS'
             ELSE 'WARN'
           END,
           'pg_cron recall worker (optional unless live recall data)'

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
             THEN 'WARN'
             WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'filter_alert_settings')
             THEN 'WARN'
             ELSE 'WARN'
           END,
           'Legacy filter_alert_settings direct DML — active UX uses saved_searches RPCs after v2'

    UNION ALL

    SELECT 911, 'grants', 'authenticated_saved_searches_select',
           CASE
             WHEN has_table_privilege('authenticated', 'public.saved_searches', 'SELECT')
             THEN 'PASS'
             WHEN EXISTS (SELECT 1 FROM tbl_exists t WHERE t.table_name = 'saved_searches')
             THEN 'STOP'
             ELSE 'STOP'
           END,
           'saved_searches SELECT for authenticated (writes via RPC only)'

    UNION ALL

    SELECT 912, 'grants', 'authenticated_saved_searches_rpc_exec',
           CASE
             WHEN COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'list_my_saved_searches'), false)
                  AND COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'create_saved_search'), false)
                  AND COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'update_saved_search'), false)
                  AND COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'delete_saved_search'), false)
                  AND COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'set_saved_search_alerts_enabled'), false)
                  AND COALESCE((SELECT ok FROM fn_auth_exec f WHERE f.proname = 'find_saved_search_by_criteria'), false)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           'EXECUTE on saved_searches v2 client RPCs for authenticated'

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
                      || 'plan targeted apply for missing migration groups; do NOT bulk-apply all migrations blindly.'
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
