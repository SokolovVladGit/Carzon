-- Carzon — allow authenticated users to create their own listings.
--
-- Scope: INSERT only. Update/delete policies are intentionally NOT added
-- in this migration — they will land with the edit/delete features.
--
-- Ownership rule: a row may be inserted only if its seller_id equals the
-- caller's auth.uid(). This makes ownership tamper-proof at the DB level,
-- regardless of what the client sends.

drop policy if exists "listings_insert_own" on public.listings;
create policy "listings_insert_own"
    on public.listings
    for insert
    to authenticated
    with check (
        seller_id is not null
        and seller_id = auth.uid()
    );
