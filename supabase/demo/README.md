# Supabase — Temporary Photo Demo Dataset

This directory holds **temporary UI-development-only** seed data for
Carzon. It is deliberately separate from `supabase/seed.sql` (the
production-safe synthetic seed) and is **never** applied as part of
the normal migration/seed flow.

## What lives here

- `photo_demo_listings.sql` — inserts 20 synthetic listings that
  carry real-looking car cover photos.
- `remove_photo_demo_listings.sql` — deletes those same 20 rows by
  explicit id.
- `README.md` — this file.

## Intent

These rows exist so the product team can polish the Flutter UI
(listing cards, feed layout, detail screens, placeholder behavior)
against realistic-looking data. Nothing in this directory is meant
for production.

## Important caveats — read before applying

- **External photos**: `cover_image_url` values point to
  `content.kareta.md`. Carzon does **not** own or license these
  images. They are used here only for internal UI mockups.
- **May disappear**: the remote host can rotate or delete these
  files at any time. Expect missing images eventually; the app's
  `ListingCoverImage` placeholder handles this gracefully.
- **Not production-safe**: do **not** import this file into a
  production project, copy these URLs into Flutter code, paste them
  into `supabase/seed.sql`, or reference them from documentation
  aimed at production.
- **Duplicate cover**: photo #1 and photo #6 in the source URL list
  are the same file. Two rows
  (`d0000000-0000-4000-8000-000000000001` and `...000000006`)
  therefore share the same `cover_image_url` on purpose — 20
  distinct listings, 19 distinct cover images.
- **RLS / schema**: nothing here touches schema, policies, indexes,
  functions, extensions, grants, or revokes. It is pure `INSERT` /
  `DELETE` against `public.listings`.

## Dataset properties

All rows inserted by `photo_demo_listings.sql`:

| Property           | Value                                                  |
| ------------------ | ------------------------------------------------------ |
| Total rows         | 20                                                     |
| Transnistria rows  | 10                                                     |
| Moldova rows       | 10                                                     |
| `status`           | `active` (every row)                                   |
| `seller_id`        | `null` (every row — rows are un-owned)                 |
| ID namespace       | `d0000000-0000-4000-8000-0000000000XX` where XX = 01…20 |
| `contact_phone`    | `+373 000 100 XXX` where XXX = 001…020                 |
| `telegram_username`| `@carzon_photo_demo_XX` where XX = 01…20               |
| `whatsapp_enabled` | mix of `true` / `false`                                |
| `type`             | mix of `sale` / `exchange` / `both`                    |
| `cover_image_url`  | `https://content.kareta.md/items/original/<uuid>.webp` |

The `d000...` UUID namespace is reserved for this photo demo set and
is deliberately distinct from the `c000...` namespace used by
`supabase/seed.sql`, so cleanup stays surgical and cannot touch
real or normal-seed rows.

## How to apply

### Via the Supabase SQL Editor

1. Open the Supabase Dashboard for the target **local / dev /
   staging** project. **Not production.**
2. Open the SQL Editor.
3. Paste the contents of `photo_demo_listings.sql` and run it.

The script uses `ON CONFLICT (id) DO UPDATE`, so re-running it is
safe and idempotent — it converges on the latest values rather than
duplicating rows.

### Via `psql`

```bash
psql "$SUPABASE_DB_URL" -f supabase/demo/photo_demo_listings.sql
```

Replace `$SUPABASE_DB_URL` with the connection string for your local
or development database. Do **not** run this against a production
database.

## How to remove

```bash
psql "$SUPABASE_DB_URL" -f supabase/demo/remove_photo_demo_listings.sql
```

Or paste `remove_photo_demo_listings.sql` into the SQL Editor.

The cleanup script deletes only the 20 `d0000000-0000-4000-8000-...`
ids it created. It does not use broad predicates
(`seller_id is null`, `status = ...`, `market_region = ...`,
`cover_image_url like ...`) and therefore cannot damage the normal
`supabase/seed.sql` rows or any real user-owned listing. Running it
twice in a row is a harmless no-op.

## Related

- `supabase/seed.sql` — the production-safe synthetic seed (no
  external photos, placeholder `+373 000 000 XXX` phones,
  `carzon_demo_NN` Telegram handles, `c000...` UUID namespace).
- `test/supabase/photo_demo_listings_test.dart` — static
  inspection tests guarding the demo dataset shape and the "no
  schema/RLS changes" / "surgical cleanup" invariants.
