# Supabase

SQL contracts for the Carzon backend.

## Layout
- `migrations/` — ordered, append-only SQL migrations (timestamp-prefixed).
- `seed.sql` — optional sample data for local/dev verification.

## Current state
Read-only public listings feed only. Seller writes, favorites, chat, and
moderation will land in later migrations.

## Apply manually (no Supabase CLI required)
1. Open the Supabase Dashboard → SQL Editor for the project.
2. Run `migrations/20260423120000_create_listings.sql`.
3. (Optional) Run `seed.sql` to insert 3 sample listings.

## Apply via Supabase CLI (when connected)
```bash
supabase link --project-ref <ref>
supabase db push
supabase db reset    # also runs seed.sql
```
