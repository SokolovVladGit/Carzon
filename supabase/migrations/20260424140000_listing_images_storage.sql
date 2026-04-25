-- Carzon — Supabase Storage bucket for listing images.
--
-- Scope: MVP single cover image per listing. Gallery support is
-- intentionally out of scope and will arrive with a dedicated
-- `listing_images` table in a later migration.
--
-- Security model:
--   * Bucket `listing-images` is public — listing photos are meant to
--     be served to anonymous visitors via `Image.network`. This avoids
--     signed-URL plumbing on the client for MVP.
--   * All objects live under `listings/<auth.uid()>/...`. The INSERT /
--     UPDATE / DELETE policies enforce that the second path segment
--     matches the caller's uid, so authenticated users can only write
--     their own folder.
--   * SELECT is open to `anon` and `authenticated` (public bucket).
--   * This migration deliberately does NOT touch `public.listings` RLS
--     policies or grants on the application schema. It scopes every
--     new policy to `bucket_id = 'listing-images'` to avoid collateral
--     impact on any other bucket a project may hold.

-- 1. Bucket.
insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

-- 2. Policies on storage.objects, scoped to the listing-images bucket.
--    Drop-if-exists + create ensures the migration is safe to re-run.

drop policy if exists "listing_images_public_read" on storage.objects;
create policy "listing_images_public_read"
    on storage.objects
    for select
    to anon, authenticated
    using (bucket_id = 'listing-images');

drop policy if exists "listing_images_owner_insert" on storage.objects;
create policy "listing_images_owner_insert"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'listing-images'
        and split_part(name, '/', 1) = 'listings'
        and split_part(name, '/', 2) = auth.uid()::text
    );

drop policy if exists "listing_images_owner_update" on storage.objects;
create policy "listing_images_owner_update"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'listing-images'
        and split_part(name, '/', 1) = 'listings'
        and split_part(name, '/', 2) = auth.uid()::text
    )
    with check (
        bucket_id = 'listing-images'
        and split_part(name, '/', 1) = 'listings'
        and split_part(name, '/', 2) = auth.uid()::text
    );

drop policy if exists "listing_images_owner_delete" on storage.objects;
create policy "listing_images_owner_delete"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'listing-images'
        and split_part(name, '/', 1) = 'listings'
        and split_part(name, '/', 2) = auth.uid()::text
    );
