-- Carzon — owner-only permanent listing delete via a narrow RPC.
--
-- Goal: let an authenticated listing owner permanently remove their
-- listing from "My Listings" without introducing a broad DELETE RLS
-- policy on `public.listings`. Archive (status = archived) remains the
-- reversible option; this RPC is the destructive, one-way counterpart.
--
-- Design:
--   * `public.delete_listing(p_listing_id uuid)` is a SECURITY DEFINER
--     function. It runs as the function owner (which bypasses RLS) but
--     its body enforces:
--       - caller is authenticated (auth.uid() is not null)
--       - the target row exists AND belongs to the caller
--       (enforced atomically via
--        `where id = p_listing_id and seller_id = auth.uid()`
--        inside the DELETE, so ownership is checked in the same
--        statement that performs the mutation)
--     If no row matches, a generic error is raised — the caller cannot
--     distinguish "not found" from "not owned", matching the existing
--     `set_listing_status` RPC's posture.
--
--   * `search_path` is pinned explicitly to defuse search_path-based
--     privilege escalation in SECURITY DEFINER bodies.
--
--   * Execute is revoked from PUBLIC/anon and granted only to the
--     `authenticated` role, matching the rest of the RLS posture. No
--     direct DELETE policy is added to `public.listings`; `anon` and
--     generic `authenticated` cannot DELETE the table directly.
--
--   * `public.favorites.listing_id` FK is declared
--     `on delete cascade`, so favorite rows for a deleted listing are
--     removed automatically by Postgres in the same transaction. No
--     manual cleanup is needed here.
--
--   * Storage cleanup (orphan cover image objects in the
--     `listing-images` bucket) is intentionally out of scope for this
--     migration. Orphan public images are an accepted MVP tradeoff; a
--     dedicated cleanup path can be added later without changing this
--     RPC's contract.
--
-- Not in scope here:
--   * moderation / admin delete
--   * bulk delete
--   * soft delete (archive already exists for that purpose)
--   * storage object cleanup

create or replace function public.delete_listing(
    p_listing_id uuid
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_deleted_count integer;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    delete from public.listings
     where id = p_listing_id
       and seller_id = auth.uid();

    get diagnostics v_deleted_count = row_count;

    if v_deleted_count = 0 then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;
end;
$$;

-- Lock down the function: Postgres grants EXECUTE to PUBLIC by default.
revoke all on function public.delete_listing(uuid) from public;
revoke all on function public.delete_listing(uuid) from anon;
grant execute on function public.delete_listing(uuid) to authenticated;
