-- =============================================================
-- Carzon — cleanup for temporary PHOTO DEMO listings
-- =============================================================
--
-- Purpose: remove the 20 rows inserted by
-- `supabase/demo/photo_demo_listings.sql`. Intended for local/dev
-- stacks where the photo demo dataset is no longer needed (e.g. once
-- the UI polish work is complete, or before a screenshot pass against
-- real seller data).
--
-- This script is SCOPED: it deletes only the 20 rows whose ids live
-- in the `d0000000-0000-4000-8000-0000000000XX` namespace reserved
-- exclusively for the photo demo dataset. It does NOT:
--   * use broad predicates like `seller_id is null`,
--   * filter by `market_region`,
--   * filter by `status`,
--   * filter by `cover_image_url`,
--   * touch the normal `c0000000-...` seed rows from `seed.sql`,
--   * touch any real user-owned listing.
--
-- Re-running this file after the rows are already gone is a no-op.
-- =============================================================

delete from public.listings
where id in (
    'd0000000-0000-4000-8000-000000000001',
    'd0000000-0000-4000-8000-000000000002',
    'd0000000-0000-4000-8000-000000000003',
    'd0000000-0000-4000-8000-000000000004',
    'd0000000-0000-4000-8000-000000000005',
    'd0000000-0000-4000-8000-000000000006',
    'd0000000-0000-4000-8000-000000000007',
    'd0000000-0000-4000-8000-000000000008',
    'd0000000-0000-4000-8000-000000000009',
    'd0000000-0000-4000-8000-000000000010',
    'd0000000-0000-4000-8000-000000000011',
    'd0000000-0000-4000-8000-000000000012',
    'd0000000-0000-4000-8000-000000000013',
    'd0000000-0000-4000-8000-000000000014',
    'd0000000-0000-4000-8000-000000000015',
    'd0000000-0000-4000-8000-000000000016',
    'd0000000-0000-4000-8000-000000000017',
    'd0000000-0000-4000-8000-000000000018',
    'd0000000-0000-4000-8000-000000000019',
    'd0000000-0000-4000-8000-000000000020'
);
