-- =============================================================================
-- Carzon — MANUAL MAINTENANCE: remove dev listings owned by test@gmail.com
-- =============================================================================
--
-- WHAT THIS IS
--   Standalone cleanup SQL for ops / pre-launch hygiene. NOT a migration.
--   Do not add this file to `supabase/migrations/` and do not pipe it into CI.
--
-- WHEN TO RUN
--   Before production launch or when clearing temporary listings created via
--   the real app using the designated development Supabase Auth account:
--     Email: test@gmail.com
--
-- WHAT IT REMOVES
--   • All rows in public.listings with seller_id = that user id
--   • All favorites rows referencing those listings (via FK CASCADE; see below)
--   • Objects in Storage bucket listing-images whose object names start with
--     listings/<that_user_uuid>/
--
-- WHAT IT DOES NOT REMOVE BY DEFAULT
--   • The auth user row for test@gmail.com (intentionally kept)
--   • Any listing with seller_id IS NULL (e.g. seed / photo-demo style rows)
--   • Any listing owned by a different seller_id
--   • The d0000000-… photo demo dataset — use demo/remove_photo_demo_listings.sql
--   • Any other buckets or prefixes outside listings/<resolved_user_id>/
--
-- PREREQUISITES
--   Run in Supabase SQL Editor (or psql as a role that can modify public + auth
--   + storage catalogs). Postgres/superuser context bypasses RLS so deletes on
--   listings, favorites, and storage.objects succeed regardless of policies.
--
-- SAFETY CHECKS
--   • Aborts with an exception if no auth.users row exists for the configured
--     email below.
--   • Uses a single resolved UUID; only deletes storage paths under that id.
--
-- =============================================================================

DO $$
DECLARE
    -- Canonical dev listing account resolved from Supabase Auth.
    v_expected_email constant text := 'test@gmail.com';

    v_user_id uuid;
    v_listing_count bigint;
    v_favorite_count bigint;
    v_storage_object_count bigint;
    v_deleted_listings bigint;
    v_deleted_storage bigint;
BEGIN
    ------------------------------------------------------------
    -- 1. Resolve developer user id
    ------------------------------------------------------------
    SELECT u.id
      INTO v_user_id
      FROM auth.users AS u
     WHERE lower(trim(u.email)) = lower(trim(v_expected_email))
     ORDER BY u.created_at ASC
     LIMIT 1;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION
            USING MESSAGE = '[cleanup_test_user_listings] No auth.users row for email '
                             || quote_literal(v_expected_email)
                             || '. Nothing deleted. Aborting.';
    END IF;

    RAISE NOTICE '[cleanup_test_user_listings] Resolved test user id: % (%).',
                 v_user_id, v_expected_email;

    ------------------------------------------------------------
    -- 2. Count impacted rows/objects (audit trail before delete)
    ------------------------------------------------------------
    SELECT count(*) INTO v_listing_count
      FROM public.listings
     WHERE seller_id = v_user_id;

    SELECT count(*) INTO v_favorite_count
      FROM public.favorites AS f
     WHERE EXISTS (
             SELECT 1
               FROM public.listings AS l
              WHERE l.id = f.listing_id
                AND l.seller_id = v_user_id
           );

    SELECT count(*) INTO v_storage_object_count
      FROM storage.objects AS o
     WHERE o.bucket_id = 'listing-images'
       AND o.name COLLATE "C"
           LIKE ('listings/' || v_user_id::text || '/%');

    RAISE NOTICE '[cleanup_test_user_listings] Rows to delete: listings=%, favorites=%, '
                  'listing-images.objects=% '
                  '(favorites will drop automatically with listings due to ON DELETE CASCADE '
                  'on favorites.listing_id → listings.id).',
                 v_listing_count, v_favorite_count, v_storage_object_count;

    ------------------------------------------------------------
    -- 3. Remove Storage objects for this user's folder ONLY
    --    Bucket + prefix match aligns with Flutter upload path convention.
    ------------------------------------------------------------
    DELETE FROM storage.objects AS o
     WHERE o.bucket_id = 'listing-images'
       AND o.name COLLATE "C"
           LIKE ('listings/' || v_user_id::text || '/%');

    GET DIAGNOSTICS v_deleted_storage = ROW_COUNT;

    ------------------------------------------------------------
    -- 4. Remove listings owned by this user
    --
    --    Schema note (migration 20260423140000_create_favorites.sql):
    --      favorites.listing_id references listings(id) ON DELETE CASCADE,
    --    so referencing favorites rows disappear when their listing is deleted.
    --    No separate DELETE FROM favorites is required for correctness.
    ------------------------------------------------------------
    DELETE FROM public.listings AS lt
     WHERE lt.seller_id = v_user_id;

    GET DIAGNOSTICS v_deleted_listings = ROW_COUNT;

    RAISE NOTICE '[cleanup_test_user_listings] Deleted storage.objects rows: %.', v_deleted_storage;
    RAISE NOTICE '[cleanup_test_user_listings] Deleted listings rows: %.', v_deleted_listings;

    IF v_deleted_listings <> v_listing_count THEN
        RAISE WARNING
            '[cleanup_test_user_listings] Deleted listing row count (%), expected (%). '
            'Another session may have changed data concurrently.',
            v_deleted_listings, v_listing_count;
    END IF;

    IF v_deleted_storage <> v_storage_object_count THEN
        RAISE WARNING
            '[cleanup_test_user_listings] Deleted storage.objects row count (%), expected (%). '
            'Concurrent storage activity may explain the mismatch.',
            v_deleted_storage, v_storage_object_count;
    END IF;

    RAISE NOTICE '[cleanup_test_user_listings] Done. Auth user % was NOT removed.',
                 v_expected_email;
END $$;
