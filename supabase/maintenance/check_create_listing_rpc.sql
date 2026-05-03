-- Read-only diagnostics for listing creation via RPC (+ Phase 1 gallery foundations).
--
-- HOW TO RUN (production or staging Supabase project):
--   Dashboard → SQL Editor → paste this file → Run
--
-- This script MUST NOT INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, or TRUNCATE
-- anything — it only runs SELECT introspection queries.
--
-- NOTES
-- -----
-- • The SELECT against `storage.buckets` targets Supabase. On plain PostgreSQL it
--   errors unless you comment out that block (everything else stays portable PG15+).

------------------------------------------------------------------------------
-- OPTIONAL E — sanity checks (catalog + Supabase storage)
------------------------------------------------------------------------------

SELECT EXISTS (
           SELECT 1
           FROM pg_catalog.pg_class c
           JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
           WHERE n.nspname = 'public'::name
             AND c.relkind IN ('r', 'p')
             AND NOT c.relispartition
             AND c.relname = 'listings'::name
       )                                   AS public_listings_table_present;

SELECT EXISTS (
           SELECT 1
           FROM pg_catalog.pg_proc p
           JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public'::name
             AND p.proname = 'create_listing'::name
       )                                   AS create_listing_routine_present;

SELECT EXISTS (
           SELECT 1
           FROM storage.buckets b
           WHERE b.id = 'listing-images'::text
       )                                   AS listing_images_bucket_present;

------------------------------------------------------------------------------
-- A — public.create_listing: identity + owner (`pg_catalog.pg_proc`)
------------------------------------------------------------------------------

SELECT n.nspname                               AS routine_schema,
       p.proname                               AS routine_name,
       oidvectortypes(p.proargtypes)           AS argument_signature,
       pg_get_function_identity_arguments(p.oid::regprocedure)
                                               AS identity_args,
       pg_get_function_arguments(p.oid::regprocedure)
                                               AS full_args,
       p.oid::regprocedure                     AS regprocedure_oid,
       pg_catalog.pg_get_userbyid(p.proowner)::text AS owner
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'::name
  AND p.proname = 'create_listing'::name;

------------------------------------------------------------------------------
-- Function DDL (SECURITY DEFINER, search_path, ...)
------------------------------------------------------------------------------

SELECT pg_catalog.pg_get_functiondef(p.oid::regprocedure) AS function_definition
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'::name
  AND p.proname = 'create_listing'::name;

------------------------------------------------------------------------------
-- B — EXECUTE privileges on create_listing (pg_catalog aclitem explosion)
--
-- `information_schema.routine_privileges` does not provide `routine_name` /
-- `routine_schema` / `table_schema` the same way relational privileges do —
-- this path reads `pg_proc.proacl` and explodes EXECUTE aclitems only.
------------------------------------------------------------------------------

SELECT n.nspname                               AS routine_schema,
       p.proname                               AS routine_name,
       p.oid::regprocedure                     AS regprocedure_oid,
       pg_catalog.pg_get_userbyid(p.proowner)::text AS owner,
       COALESCE(
         p.proacl,
         acldefault(CAST('f' AS pg_catalog."char"), p.proowner)
       )::text                                 AS aclitems_raw_text,
       x.grantee::pg_catalog.regrole::text AS execute_grantee,
       x.grantor::pg_catalog.regrole::text AS execute_grantor,
       btrim(x.privilege_type::text) AS privilege_type,
       CASE WHEN x.is_grantable THEN 'YES'::text ELSE 'NO'::text END AS is_grantable
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
LEFT JOIN LATERAL (
           SELECT xe.grantee,
                  xe.grantor,
                  xe.privilege_type,
                  xe.is_grantable
           FROM pg_catalog.aclexplode(
                  COALESCE(
                    p.proacl,
                    acldefault(CAST('f' AS pg_catalog."char"), p.proowner))) xe
           WHERE btrim(xe.privilege_type::text) = 'EXECUTE'
       ) AS x ON TRUE
WHERE n.nspname = 'public'::name
  AND p.proname = 'create_listing'::name
ORDER BY routine_schema,
         routine_name,
         execute_grantee;

------------------------------------------------------------------------------
-- C — Legacy direct-insert policy `listings_insert_own` (`pg_policy` catalogs)
------------------------------------------------------------------------------

SELECT EXISTS (
           SELECT 1
           FROM pg_catalog.pg_policy pol
           JOIN pg_catalog.pg_class rel ON rel.oid = pol.polrelid
           JOIN pg_catalog.pg_namespace ns ON ns.oid = rel.relnamespace
           WHERE ns.nspname = 'public'::name
             AND rel.relname = 'listings'::name
             AND pol.polname = 'listings_insert_own'::name
       )                                   AS listings_insert_own_policy_present,
       CASE
         WHEN EXISTS (
                SELECT 1
                FROM pg_catalog.pg_policy pol
                JOIN pg_catalog.pg_class rel ON rel.oid = pol.polrelid
                JOIN pg_catalog.pg_namespace ns ON ns.oid = rel.relnamespace
                WHERE ns.nspname = 'public'::name
                  AND rel.relname = 'listings'::name
                  AND pol.polname = 'listings_insert_own'::name)
         THEN text 'OBSERVED: listings_insert_own still present; apply RPC migration to drop INSERT policy.'
         ELSE text 'EXPECTED: absent (clients publish via RPC, not INSERT policy).'
       END                                 AS expectation;

------------------------------------------------------------------------------
-- D — RLS policies on public.listings (pg_policy + pg_class + pg_namespace)
------------------------------------------------------------------------------

SELECT ns.nspname                                        AS schema,
       rel.relname                                       AS table_name,
       pol.polname                                       AS policy_name,
       CASE trim(pol.polcmd::text)
         WHEN 'r' THEN 'SELECT'
         WHEN 'a' THEN 'INSERT'
         WHEN 'w' THEN 'UPDATE'
         WHEN 'd' THEN 'DELETE'
         WHEN '*' THEN 'ALL'
         ELSE concat('OTHER(', pol.polcmd::text, ')')
       END                                               AS cmd,
       CASE WHEN pol.polroles IS NULL OR cardinality(pol.polroles) = 0
            THEN text 'PUBLIC'
            ELSE COALESCE(
              (
                  SELECT string_agg(pg_catalog.quote_ident(r.rolname), ', ')
                  FROM pg_catalog.pg_roles r
                  WHERE r.oid = ANY (pol.polroles)
              ),
              pol.polroles::text
             )
       END                                               AS roles,
       pol.polpermissive                                  AS permissive,
       pg_catalog.pg_get_expr(pol.polqual, pol.polrelid) AS qual,
       pg_catalog.pg_get_expr(pol.polwithcheck, pol.polrelid)
                                                           AS with_check
FROM pg_catalog.pg_policy pol
JOIN pg_catalog.pg_class rel ON rel.oid = pol.polrelid
JOIN pg_catalog.pg_namespace ns ON ns.oid = rel.relnamespace
WHERE ns.nspname = 'public'::name
  AND rel.relname = 'listings'::name
ORDER BY pol.polname;

------------------------------------------------------------------------------
-- E — Currency column (`listings.price_currency`)
------------------------------------------------------------------------------

SELECT EXISTS (
           SELECT 1
           FROM information_schema.columns c
           WHERE c.table_schema = 'public'::name
             AND c.table_name = 'listings'::name
             AND c.column_name = 'price_currency'::name
       )                                      AS listings_price_currency_column_present,

       EXISTS (
           SELECT 1
           FROM pg_catalog.pg_constraint con
           JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid
           JOIN pg_catalog.pg_namespace ns ON ns.oid = rel.relnamespace
           WHERE ns.nspname = 'public'::name
             AND rel.relname = 'listings'::name
             AND con.conname = 'listings_price_currency_chk'::name
       )                                      AS listings_price_currency_check_present;

------------------------------------------------------------------------------
-- F — `listing_images` child table existence + RLS posture
------------------------------------------------------------------------------

SELECT EXISTS (
           SELECT 1
           FROM pg_catalog.pg_class c
           JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
           WHERE n.nspname = 'public'::name
             AND c.relkind = 'r'
             AND NOT c.relispartition
             AND c.relname = 'listing_images'::name
       )                                      AS listing_images_table_present,

       EXISTS (
           SELECT 1
           FROM pg_catalog.pg_class c
           JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
           WHERE n.nspname = 'public'::name
             AND c.relname = 'listing_images'::name
             AND c.relrowsecurity
       )                                      AS listing_images_rls_enabled;

SELECT pol.polname,
       CASE trim(pol.polcmd::text)
         WHEN 'r' THEN 'SELECT'
         WHEN 'a' THEN 'INSERT'
         WHEN 'w' THEN 'UPDATE'
         WHEN 'd' THEN 'DELETE'
         ELSE pol.polcmd::text
       END AS cmd,
       pol.polroles::text AS role_oids_raw
FROM pg_catalog.pg_policy pol
JOIN pg_catalog.pg_class rel ON rel.oid = pol.polrelid
JOIN pg_catalog.pg_namespace ns ON ns.oid = rel.relnamespace
WHERE ns.nspname = 'public'::name
  AND rel.relname = 'listing_images'::name
ORDER BY pol.polname;

-- Expect INSERT/UPDATE/DELETE policies = 0 (RPC-only mutations).
SELECT COUNT(*) FILTER (WHERE trim(pol.polcmd::text) = 'a'::text)
           AS listing_images_insert_policies,
       COUNT(*) FILTER (WHERE trim(pol.polcmd::text) = 'w'::text)
           AS listing_images_update_policies,
       COUNT(*) FILTER (WHERE trim(pol.polcmd::text) = 'd'::text)
           AS listing_images_delete_policies
FROM pg_catalog.pg_policy pol
JOIN pg_catalog.pg_class rel ON rel.oid = pol.polrelid
JOIN pg_catalog.pg_namespace ns ON ns.oid = rel.relnamespace
WHERE ns.nspname = 'public'::name
  AND rel.relname = 'listing_images'::name;

------------------------------------------------------------------------------
-- G — create_listing_v2 + replace_listing_images routines
------------------------------------------------------------------------------

SELECT proname                                   AS routine_name,
       oidvectortypes(p.proargtypes)             AS signature_arg_types,
       p.oid::regprocedure                       AS regprocedure_oid,
       pg_catalog.pg_get_userbyid(p.proowner)    AS owner
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'::name
  AND p.proname in ('create_listing_v2'::name, 'replace_listing_images'::name)
ORDER BY proname;

SELECT pg_catalog.pg_get_functiondef(p.oid::regprocedure) AS function_definition
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'::name
  AND p.proname = 'create_listing_v2'::name;
