-- Read-only contact hardening verification — single summary table for SQL Editor.
--
-- HOW TO RUN:
--   Supabase Dashboard → SQL Editor → paste this ENTIRE file → Run
--
-- OUTPUT:
--   One table: check_name | status | details
--   Screenshot or copy the FULL result (especially overall_sql_metadata_result).
--
--   PASS on overall → proceed to Phase 3 API checks (verification runbook).
--   STOP on overall → public/client exposure or missing migration/RPC; ask owner / tech lead.
--   STOP applies only to anon, authenticated, and PUBLIC grants — not postgres/service_role.
--
-- SAFETY: SELECT / catalog introspection ONLY. No DML/DDL/GRANT/REVOKE.
-- Pair with: docs/supabase_contact_hardening_verification.md

WITH
migration_present AS (
    SELECT EXISTS (
        SELECT 1
          FROM supabase_migrations.schema_migrations
         WHERE version = '20260630120000'
    ) AS ok
),
forbidden_grants AS (
    SELECT cp.grantee,
           cp.table_name,
           cp.column_name
      FROM information_schema.column_privileges cp
     WHERE cp.table_schema = 'public'
       AND cp.privilege_type = 'SELECT'
       AND (
             lower(cp.grantee) IN ('anon', 'authenticated')
          OR cp.grantee = 'PUBLIC'
           )
       AND lower(cp.grantee) NOT IN (
             'postgres',
             'service_role',
             'supabase_admin',
             'supabase_auth_admin',
             'supabase_storage_admin',
             'dashboard_user'
           )
       AND (
             (
                 cp.table_name = 'listings'
                 AND cp.column_name IN (
                     'contact_phone',
                     'telegram_username',
                     'whatsapp_enabled'
                 )
             )
          OR (
                 cp.table_name = 'listing_images'
                 AND cp.column_name = 'storage_path'
             )
           )
),
forbidden_summary AS (
    SELECT COUNT(*)::bigint AS offender_count,
           COALESCE(
             string_agg(
               fg.grantee || ':' || fg.table_name || '.' || fg.column_name,
               '; '
               ORDER BY fg.grantee, fg.table_name, fg.column_name
             ),
             ''
           ) AS offenders
      FROM forbidden_grants fg
),
privileged_grants AS (
    SELECT cp.grantee,
           cp.table_name,
           cp.column_name
      FROM information_schema.column_privileges cp
     WHERE cp.table_schema = 'public'
       AND cp.privilege_type = 'SELECT'
       AND lower(cp.grantee) IN (
             'postgres',
             'service_role',
             'supabase_admin',
             'supabase_auth_admin',
             'supabase_storage_admin',
             'dashboard_user'
           )
       AND (
             (
                 cp.table_name = 'listings'
                 AND cp.column_name IN (
                     'contact_phone',
                     'telegram_username',
                     'whatsapp_enabled'
                 )
             )
          OR (
                 cp.table_name = 'listing_images'
                 AND cp.column_name = 'storage_path'
             )
           )
),
privileged_summary AS (
    SELECT COUNT(*)::bigint AS privileged_count,
           COALESCE(
             string_agg(
               DISTINCT pg.grantee,
               ', '
               ORDER BY pg.grantee
             ),
             ''
           ) AS privileged_grantees,
           COALESCE(
             string_agg(
               pg.grantee || ':' || pg.table_name || '.' || pg.column_name,
               '; '
               ORDER BY pg.grantee, pg.table_name, pg.column_name
             ),
             ''
           ) AS privileged_details
      FROM privileged_grants pg
),
rpc_public_contact AS (
    SELECT pg_get_function_identity_arguments(p.oid) AS args,
           pg_get_function_result(p.oid) AS result_type,
           p.prosecdef AS security_definer
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname = 'get_listing_public_contact'
     LIMIT 1
),
rpc_owner_edit AS (
    SELECT pg_get_function_identity_arguments(p.oid) AS args,
           pg_get_function_result(p.oid) AS result_type,
           p.prosecdef AS security_definer
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname = 'get_my_listing_for_edit'
     LIMIT 1
),
rpc_seller_profile AS (
    SELECT pg_get_function_result(p.oid) AS result_type
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname = 'get_seller_public_profile'
     LIMIT 1
),
rpc_inbox AS (
    SELECT pg_get_function_result(p.oid) AS result_type
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname = 'list_inbox_conversations'
     LIMIT 1
),
check_rows AS (
    SELECT 10 AS sort_key,
           'hardening_migration_applied'::text AS check_name,
           CASE
             WHEN (SELECT ok FROM migration_present)
             THEN 'PASS'
             ELSE 'STOP'
           END AS status,
           CASE
             WHEN (SELECT ok FROM migration_present)
             THEN 'Migration 20260630120000 is recorded in schema_migrations.'
             ELSE 'Migration 20260630120000 is missing. Do not apply during verification; ask owner before manual apply.'
           END AS details

    UNION ALL

    SELECT 20,
           'forbidden_direct_contact_grants',
           CASE
             WHEN (SELECT offender_count FROM forbidden_summary) = 0
             THEN 'PASS'
             ELSE 'STOP'
           END,
           CASE
             WHEN (SELECT offender_count FROM forbidden_summary) = 0
             THEN 'No forbidden SELECT grants for public/client roles (anon, authenticated, PUBLIC) on contact_phone, telegram_username, whatsapp_enabled, or listing_images.storage_path. Privileged roles (postgres, service_role, etc.) are ignored — not public exposure.'
             ELSE 'Forbidden public/client column SELECT grants: '
                  || (SELECT offenders FROM forbidden_summary)
           END

    UNION ALL

    SELECT 25,
           'privileged_internal_grants',
           'INFO',
           CASE
             WHEN (SELECT privileged_count FROM privileged_summary) = 0
             THEN 'No privileged-role SELECT on protected columns reported in information_schema (optional sanity).'
             ELSE 'Expected internal/admin SELECT on protected columns for: '
                  || (SELECT privileged_grantees FROM privileged_summary)
                  || '. Not PostgREST client exposure; do not REVOKE. Examples: '
                  || (SELECT privileged_details FROM privileged_summary)
           END

    UNION ALL

    SELECT 30,
           'rpc_get_listing_public_contact',
           CASE
             WHEN EXISTS (SELECT 1 FROM rpc_public_contact)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           CASE
             WHEN EXISTS (SELECT 1 FROM rpc_public_contact)
             THEN 'public.get_listing_public_contact('
                  || COALESCE((SELECT args FROM rpc_public_contact), '')
                  || ') → '
                  || COALESCE((SELECT result_type FROM rpc_public_contact), '')
                  || '; security_definer='
                  || COALESCE((SELECT security_definer::text FROM rpc_public_contact), 'unknown')
             ELSE 'Function public.get_listing_public_contact not found.'
           END

    UNION ALL

    SELECT 40,
           'rpc_get_my_listing_for_edit',
           CASE
             WHEN EXISTS (SELECT 1 FROM rpc_owner_edit)
             THEN 'PASS'
             ELSE 'STOP'
           END,
           CASE
             WHEN EXISTS (SELECT 1 FROM rpc_owner_edit)
             THEN 'public.get_my_listing_for_edit('
                  || COALESCE((SELECT args FROM rpc_owner_edit), '')
                  || ') → '
                  || COALESCE((SELECT result_type FROM rpc_owner_edit), '')
                  || '; security_definer='
                  || COALESCE((SELECT security_definer::text FROM rpc_owner_edit), 'unknown')
             ELSE 'Function public.get_my_listing_for_edit not found.'
           END

    UNION ALL

    SELECT 50,
           'seller_public_profile_return_shape',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_seller_profile)
             THEN 'INFO'
             WHEN lower(COALESCE((SELECT result_type FROM rpc_seller_profile), ''))
                  ~ E'(contact_phone|telegram_username|whatsapp_enabled|\\memail\\M)'
             THEN 'STOP'
             ELSE 'PASS'
           END,
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_seller_profile)
             THEN 'Function public.get_seller_public_profile not found; shape not inspectable.'
             ELSE 'Return type: '
                  || COALESCE((SELECT result_type FROM rpc_seller_profile), '(empty)')
                  || CASE
                       WHEN lower(COALESCE((SELECT result_type FROM rpc_seller_profile), ''))
                            ~ E'(contact_phone|telegram_username|whatsapp_enabled|\\memail\\M)'
                       THEN ' — contains forbidden contact/email column name.'
                       ELSE ' — no contact_phone, telegram_username, whatsapp_enabled, or bare email column.'
                     END
           END

    UNION ALL

    SELECT 60,
           'messaging_inbox_return_shape',
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_inbox)
             THEN 'INFO'
             WHEN lower(COALESCE((SELECT result_type FROM rpc_inbox), ''))
                  ~ E'(contact_phone|telegram_username|whatsapp_enabled|\\memail\\M)'
             THEN 'STOP'
             ELSE 'PASS'
           END,
           CASE
             WHEN NOT EXISTS (SELECT 1 FROM rpc_inbox)
             THEN 'Function public.list_inbox_conversations not found; shape not inspectable.'
             ELSE 'Return type: '
                  || COALESCE((SELECT result_type FROM rpc_inbox), '(empty)')
                  || CASE
                       WHEN lower(COALESCE((SELECT result_type FROM rpc_inbox), ''))
                            ~ E'(contact_phone|telegram_username|whatsapp_enabled|\\memail\\M)'
                       THEN ' — contains forbidden contact/email column name.'
                       ELSE ' — no obvious contact column names in RPC return shape (jsonb listings body not inspected here).'
                     END
           END

    UNION ALL

    SELECT 70,
           'manual_postgrest_api_checks',
           'MANUAL',
           'Phase 3: run read-only PostgREST checks from docs/supabase_contact_hardening_verification.md (forbidden column select, contact RPC active/inactive, seller profile, inbox). Requires anon key and test JWTs outside repo.'
),
blocking AS (
    SELECT COUNT(*) FILTER (WHERE status = 'STOP') AS stop_count
      FROM check_rows
)
SELECT cr.check_name,
       cr.status,
       cr.details
  FROM (
        SELECT * FROM check_rows
        UNION ALL
        SELECT 99,
               'overall_sql_metadata_result',
               CASE
                 WHEN (SELECT stop_count FROM blocking) > 0
                 THEN 'STOP'
                 ELSE 'PASS'
               END,
               CASE
                 WHEN (SELECT stop_count FROM blocking) > 0
                 THEN (SELECT stop_count FROM blocking)::text
                      || ' blocking check(s) failed. Do NOT apply migrations. Fix hosted state or ask owner before apply. Do NOT proceed to Phase 3 until resolved.'
                 ELSE 'All blocking SQL metadata checks passed. Proceed to Phase 3 read-only PostgREST/API checks, then Phase 4 Flutter smoke.'
               END
       ) cr
 ORDER BY cr.sort_key;
