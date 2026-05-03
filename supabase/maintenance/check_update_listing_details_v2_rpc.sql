-- Read-only diagnostics: Edit Listing v2 Phase 4A RPC (`update_listing_details_v2`)
-- plus legacy parity and gallery RPC presence.
--
-- HOW TO RUN: Supabase Dashboard → SQL Editor → paste → Run.
-- This script performs SELECT introspection ONLY (no DDL/DML).

------------------------------------------------------------------------------
-- Presence: legacy vs v2 vs replace_listing_images
------------------------------------------------------------------------------

SELECT p.proname                               AS routine_name,
       p.oid::regprocedure                     AS regprocedure_oid,
       pg_catalog.oidvectortypes(p.proargtypes) AS signature_arg_types
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'::name
  AND p.proname in (
           'update_listing_details'::name,
           'update_listing_details_v2'::name,
           'replace_listing_images'::name
       )
ORDER BY p.proname;

------------------------------------------------------------------------------
-- update_listing_details_v2 — SECURITY DEFINER + DDL (manual review)
------------------------------------------------------------------------------

SELECT p.prosecdef AS is_security_definer,
       p.proconfig AS proconfig_defaults,
       pg_catalog.pg_get_functiondef(p.oid::regprocedure) AS full_definition_sql
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'::name
  AND p.proname = 'update_listing_details_v2'::name;

------------------------------------------------------------------------------
-- Grants: EXECUTE should exist for authenticated on v2 RPC
------------------------------------------------------------------------------
-- Prefer pg_proc + aclitem explosion pattern (consistent with main check scripts).

SELECT n.nspname                               AS routine_schema,
       p.proname                               AS routine_name,
       p.oid::regprocedure                     AS regprocedure_oid,
       x.grantee::pg_catalog.regrole::text AS execute_grantee,
       CASE WHEN x.is_grantable THEN 'YES'::text ELSE 'NO'::text END AS is_grantable
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
LEFT JOIN LATERAL (
           SELECT xe.grantee,
                  xe.privilege_type,
                  xe.is_grantable
           FROM pg_catalog.aclexplode(
                  COALESCE(
                    p.proacl,
                    acldefault(CAST('f' AS pg_catalog."char"), p.proowner))) xe
           WHERE btrim(xe.privilege_type::text) = 'EXECUTE'
       ) AS x ON TRUE
WHERE n.nspname = 'public'::name
  AND p.proname in ('update_listing_details_v2'::name, 'replace_listing_images'::name)
ORDER BY routine_name,
         execute_grantee;

------------------------------------------------------------------------------
-- Policies: listings + listing_images must have no broad client mutating paths
------------------------------------------------------------------------------
-- Mirror expectations: INSERT may exist ONLY as legacy `listings_insert_own` audit;
-- Phase 4A migration MUST NOT introduce new INSERT/UPDATE/DELETE on listings or listing_images.

SELECT ns.nspname          AS schema,
       rel.relname         AS table_name,
       COUNT(*) FILTER (WHERE trim(pol.polcmd::text) = 'a') AS insert_policies,
       COUNT(*) FILTER (WHERE trim(pol.polcmd::text) = 'w') AS update_policies,
       COUNT(*) FILTER (WHERE trim(pol.polcmd::text) = 'd') AS delete_policies,
       COUNT(*) FILTER (WHERE trim(pol.polcmd::text) = 'r') AS select_policies
FROM pg_catalog.pg_class rel
JOIN pg_catalog.pg_namespace ns ON ns.oid = rel.relnamespace
LEFT JOIN pg_catalog.pg_policy pol ON pol.polrelid = rel.oid
WHERE ns.nspname = 'public'::name
  AND rel.relname in ('listings'::name, 'listing_images'::name)
  AND rel.relkind = 'r'
GROUP BY ns.nspname, rel.relname
ORDER BY rel.relname;

SELECT pol.polname,
       CASE trim(pol.polcmd::text)
         WHEN 'r' THEN 'SELECT'
         WHEN 'a' THEN 'INSERT'
         WHEN 'w' THEN 'UPDATE'
         WHEN 'd' THEN 'DELETE'
       END AS cmd
FROM pg_catalog.pg_policy pol
JOIN pg_catalog.pg_class rel ON rel.oid = pol.polrelid
JOIN pg_catalog.pg_namespace ns ON ns.oid = rel.relnamespace
WHERE ns.nspname = 'public'::name
  AND rel.relname = 'listing_images'::name
ORDER BY pol.polname;
