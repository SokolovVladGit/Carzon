-- Read-only diagnostics: listings with NULL body_type (Carzon).
--
-- WHY: Body-type feed chips filter with `WHERE body_type = <value>`. Rows with
-- NULL never match those filters — this is expected SQL behavior, not a bug.
--
-- HOW TO RUN: Supabase Dashboard → SQL Editor → paste → Run (SELECT only).
--
-- This script does NOT INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, or TRUNCATE.
-- Optional COUNT is read-only.

-------------------------------------------------------------------------------
-- Rows missing body_type (newest first). Adjust LIMIT in the editor if needed.
-------------------------------------------------------------------------------

SELECT
    id,
    title,
    make,
    model,
    year,
    city,
    market_region,
    body_type,
    created_at
FROM public.listings
WHERE body_type IS NULL
ORDER BY created_at DESC;

-- Uncomment to see totals only:
-- SELECT COUNT(*) AS listings_missing_body_type
-- FROM public.listings
-- WHERE body_type IS NULL;

-------------------------------------------------------------------------------
-- Manual fix examples — DO NOT run in production without verifying the listing
-- id and choosing the correct taxonomy value (sedan | hatchback | wagon | suv |
-- coupe | convertible | minivan | pickup | van | other).
-------------------------------------------------------------------------------

-- UPDATE public.listings
-- SET body_type = 'sedan'
-- WHERE id = '<listing_uuid>';
