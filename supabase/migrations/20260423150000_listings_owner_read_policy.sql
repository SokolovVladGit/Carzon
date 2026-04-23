-- Carzon — owners can read all of their own listings.
--
-- The existing `listings_public_read_active` policy exposes only
-- `status = 'active'` rows to anon + authenticated. This additional
-- permissive policy lets a signed-in user also read their own
-- listings regardless of status (hidden / sold / archived) so the
-- "My Listings" page reflects the full ownership view.
--
-- RLS combines permissive policies with OR, so this policy widens
-- access only for the current user's own rows. Public visibility for
-- other users' listings is unchanged.

drop policy if exists "listings_select_own" on public.listings;
create policy "listings_select_own"
    on public.listings
    for select
    to authenticated
    using (seller_id = auth.uid());
