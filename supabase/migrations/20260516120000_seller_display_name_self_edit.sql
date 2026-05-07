-- Carzon — authenticated seller display_name self-service (RPC only).
--
-- Adds:
--   * get_my_seller_profile() — safe self row for account UI (no email).
--   * update_my_seller_display_name(p_display_name text) — trim, empty→null,
--     max length 80, updates display_name only for auth.uid().
--
-- Privacy:
--   * No client-supplied user id; auth.uid() only.
--   * Does not read or write email / auth metadata beyond ensure_seller_profile.

------------------------------------------------------------------------------
-- get_my_seller_profile
------------------------------------------------------------------------------

create or replace function public.get_my_seller_profile()
returns table (
    display_name        text,
    avatar_url          text,
    member_since        timestamptz,
    public_visibility   boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated';
    end if;

    perform public.ensure_seller_profile(v_uid);

    return query
    select sp.display_name,
           sp.avatar_url,
           sp.member_since,
           sp.public_visibility
      from public.seller_profiles sp
     where sp.user_id = v_uid;
end;
$$;

comment on function public.get_my_seller_profile() is
    'Authenticated caller reads own seller_profiles row for account editing (no email).';

revoke all on function public.get_my_seller_profile() from public;
revoke all on function public.get_my_seller_profile() from anon;
grant execute on function public.get_my_seller_profile() to authenticated;

------------------------------------------------------------------------------
-- update_my_seller_display_name
------------------------------------------------------------------------------

create or replace function public.update_my_seller_display_name(p_display_name text)
returns table (
    display_name        text,
    avatar_url          text,
    member_since        timestamptz,
    public_visibility   boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid   uuid;
    v_clean text;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated';
    end if;

    v_clean := nullif(btrim(coalesce(p_display_name, '')), '');
    if v_clean is not null and char_length(v_clean) > 80 then
        raise exception 'seller_display_name_too_long';
    end if;

    perform public.ensure_seller_profile(v_uid);

    update public.seller_profiles sp
       set display_name = v_clean
     where sp.user_id = v_uid;

    return query
    select sp.display_name,
           sp.avatar_url,
           sp.member_since,
           sp.public_visibility
      from public.seller_profiles sp
     where sp.user_id = v_uid;
end;
$$;

comment on function public.update_my_seller_display_name(text) is
    'Authenticated caller updates own seller_profiles.display_name only; empty clears to null; max 80 chars.';

revoke all on function public.update_my_seller_display_name(text) from public;
revoke all on function public.update_my_seller_display_name(text) from anon;
grant execute on function public.update_my_seller_display_name(text) to authenticated;
