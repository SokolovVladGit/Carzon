-- Carzon — owner-only listing status update via a narrow RPC.
--
-- Goal: let an authenticated listing owner change their listing's
-- `status` (active / hidden / sold / archived) from "My Listings"
-- without introducing a broad UPDATE RLS policy that would also allow
-- editing every other column before the edit-listing feature exists.
--
-- Design:
--   * `public.set_listing_status(p_listing_id uuid, p_status text)` is a
--     SECURITY DEFINER function. It runs as the function owner (which
--     bypasses RLS) but its body enforces:
--       - caller is authenticated (auth.uid() is not null)
--       - requested status is one of the allowed values
--       - the target row exists AND belongs to the caller
--       (enforced via `where id = p_listing_id and seller_id = auth.uid()`
--        inside the UPDATE, so ownership is checked atomically)
--     Only the `status` column is updated — no other field can be
--     influenced by the caller.
--
--   * `search_path` is pinned explicitly to defuse search_path-based
--     privilege escalation in SECURITY DEFINER bodies.
--
--   * Execute is revoked from PUBLIC/anon and granted only to the
--     `authenticated` role, matching existing RLS posture. No direct
--     UPDATE policy is added; `anon` and even generic `authenticated`
--     cannot UPDATE `public.listings` directly.
--
-- Not in scope here:
--   * full edit-listing (title, price, year, etc.)
--   * permanent delete
--   * moderation / admin actions

create or replace function public.set_listing_status(
    p_listing_id uuid,
    p_status     text
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row public.listings;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_status not in ('active', 'hidden', 'sold', 'archived') then
        raise exception 'invalid listing status: %', p_status
            using errcode = '22023';
    end if;

    update public.listings
       set status = p_status
     where id = p_listing_id
       and seller_id = auth.uid()
    returning * into v_row;

    if not found then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    return v_row;
end;
$$;

-- Lock down the function: Postgres grants EXECUTE to PUBLIC by default.
revoke all on function public.set_listing_status(uuid, text) from public;
revoke all on function public.set_listing_status(uuid, text) from anon;
grant execute on function public.set_listing_status(uuid, text) to authenticated;
