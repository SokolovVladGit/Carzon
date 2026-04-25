-- Carzon — owner-only listing cover-image edit via a narrow RPC.
--
-- Goal: let an authenticated owner replace or remove the single cover
-- image of their own listing without broadening the existing UPDATE
-- posture on `public.listings` (which has no direct UPDATE policy —
-- all writes go through SECURITY DEFINER RPCs that whitelist columns
-- explicitly).
--
-- Design mirrors `public.update_listing_details` and
-- `public.delete_listing`:
--   * SECURITY DEFINER function; body enforces
--       - caller is authenticated (auth.uid() is not null)
--       - `cover_image_url` input is either NULL (removal) or a
--         non-blank `http://` / `https://` URL (replacement). The
--         client uploads the image to Storage first and passes the
--         resulting public URL here; this RPC never constructs URLs
--         and never touches Storage.
--       - the target row exists AND belongs to the caller (enforced
--         atomically inside the UPDATE's WHERE clause so ownership is
--         checked in the same statement that performs the mutation).
--   * `search_path` pinned to defuse search_path-based privilege
--     escalation in SECURITY DEFINER bodies.
--   * Only the `cover_image_url` column is updated. Every other
--     column — including `seller_id`, `status`, `created_at`, and
--     the text/spec/contact fields owned by `update_listing_details`
--     — is left untouched.
--   * Execute is revoked from PUBLIC/anon and granted only to the
--     `authenticated` role. No direct UPDATE policy is added to
--     `public.listings`; anon and generic authenticated callers
--     still cannot UPDATE the table directly.
--
-- Storage cleanup of the previous object is intentionally NOT done
-- here: the DB cannot safely touch Storage in a transaction, and the
-- client performs a best-effort `storage.objects` delete scoped to the
-- caller's `listings/<auth.uid()>/` folder after this RPC succeeds.
-- Orphan public images remain an accepted MVP tradeoff.
--
-- Not in scope here:
--   * multi-image gallery / ordering
--   * status change (owned by `set_listing_status`)
--   * permanent delete (owned by `delete_listing`)
--   * other editable fields (owned by `update_listing_details`)

create or replace function public.update_listing_cover_image(
    p_listing_id       uuid,
    p_cover_image_url  text
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row public.listings;
    v_url text;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    -- NULL removes the cover image. A non-null value must be a
    -- non-blank `http://` or `https://` URL. We intentionally do not
    -- enforce a Supabase-host prefix: callers pass the public URL
    -- returned by `storage.from('listing-images').getPublicUrl(...)`,
    -- which is environment-dependent (local vs cloud). Storage RLS
    -- still enforces that only the owner's folder can be written.
    if p_cover_image_url is null then
        v_url := null;
    else
        v_url := btrim(p_cover_image_url);
        if v_url = '' then
            raise exception 'cover_image_url cannot be blank'
                using errcode = '22023';
        end if;
        if v_url !~* '^https?://' then
            raise exception 'invalid cover_image_url'
                using errcode = '22023';
        end if;
    end if;

    update public.listings
       set cover_image_url = v_url
     where id = p_listing_id
       and seller_id = auth.uid()
    returning * into v_row;

    if not found then
        -- Deliberately generic: do not reveal whether the listing
        -- exists but belongs to someone else vs. does not exist at all.
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    return v_row;
end;
$$;

-- Lock down the function: Postgres grants EXECUTE to PUBLIC by default.
revoke all on function public.update_listing_cover_image(uuid, text) from public;
revoke all on function public.update_listing_cover_image(uuid, text) from anon;
grant execute on function public.update_listing_cover_image(uuid, text) to authenticated;
