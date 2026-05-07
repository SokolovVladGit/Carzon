-- Carzon — authenticated seller avatar self-service (RPC) + extended self-profile shape.
--
-- Because Postgres cannot reliably derive Supabase project public URLs inside generic SQL,
-- update_my_seller_avatar accepts BOTH path (validated ownership) and client-supplied URL
-- from Flutter Storage SDK after upload; URL length and HTTPS scheme are enforced server-side.
--
-- Scope:
--   * Extend get_my_seller_profile() — adds avatar_path to RETURNS TABLE.
--   * Extend update_my_seller_display_name() — SELECT returns avatar_path.
--   * update_my_seller_avatar(p_avatar_path, p_avatar_url) — updates avatar columns only.
--   * clear_my_seller_avatar() — nulls avatar_url / avatar_path; Storage cleanup is client-side.

------------------------------------------------------------------------------
-- Drop existing RPCs whose RETURNS TABLE / OUT shape changes
--
-- Postgres rejects CREATE OR REPLACE when the row type of RETURNS TABLE differs.
-- Prior migrations already defined get_my_seller_profile / update_my_seller_display_name
-- without avatar_path in the return row; drop then recreate below.
------------------------------------------------------------------------------

drop function if exists public.get_my_seller_profile();
drop function if exists public.update_my_seller_display_name(text);
drop function if exists public.update_my_seller_avatar(text, text);
drop function if exists public.clear_my_seller_avatar();

------------------------------------------------------------------------------
-- get_my_seller_profile (extended)
------------------------------------------------------------------------------

create or replace function public.get_my_seller_profile()
returns table (
    display_name        text,
    avatar_url          text,
    avatar_path         text,
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
           sp.avatar_path,
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
-- update_my_seller_display_name (extended return shape only)
------------------------------------------------------------------------------

create or replace function public.update_my_seller_display_name(p_display_name text)
returns table (
    display_name        text,
    avatar_url          text,
    avatar_path         text,
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
           sp.avatar_path,
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

------------------------------------------------------------------------------
-- update_my_seller_avatar
------------------------------------------------------------------------------

create or replace function public.update_my_seller_avatar(
    p_avatar_path text,
    p_avatar_url text
)
returns table (
    display_name        text,
    avatar_url          text,
    avatar_path         text,
    member_since        timestamptz,
    public_visibility   boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid    uuid;
    v_path   text;
    v_url    text;
    v_prefix text;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated';
    end if;

    v_path := btrim(coalesce(p_avatar_path, ''));
    v_url := btrim(coalesce(p_avatar_url, ''));

    if v_path = '' or v_url = '' then
        raise exception 'seller_avatar_invalid_payload';
    end if;

    if position('..' in v_path) > 0 then
        raise exception 'seller_avatar_invalid_path';
    end if;

    if char_length(v_path) > 1024 then
        raise exception 'seller_avatar_path_too_long';
    end if;

    if char_length(v_url) > 2048 then
        raise exception 'seller_avatar_url_too_long';
    end if;

    if substring(v_url from 1 for 8) <> 'https://' then
        raise exception 'seller_avatar_invalid_url';
    end if;

    v_prefix := 'avatars/' || v_uid::text || '/';
    if length(v_path) < length(v_prefix) + 1
       or substring(v_path from 1 for length(v_prefix)) <> v_prefix
    then
        raise exception 'seller_avatar_invalid_path';
    end if;

    perform public.ensure_seller_profile(v_uid);

    update public.seller_profiles sp
       set avatar_path = v_path,
           avatar_url = v_url
     where sp.user_id = v_uid;

    return query
    select sp.display_name,
           sp.avatar_url,
           sp.avatar_path,
           sp.member_since,
           sp.public_visibility
      from public.seller_profiles sp
     where sp.user_id = v_uid;
end;
$$;

comment on function public.update_my_seller_avatar(text, text) is
    'Authenticated caller sets own seller_profiles.avatar_path and avatar_url; path must be under avatars/<uid>/; URL must be HTTPS (client from Storage public URL).';

revoke all on function public.update_my_seller_avatar(text, text) from public;
revoke all on function public.update_my_seller_avatar(text, text) from anon;
grant execute on function public.update_my_seller_avatar(text, text) to authenticated;

------------------------------------------------------------------------------
-- clear_my_seller_avatar
------------------------------------------------------------------------------

create or replace function public.clear_my_seller_avatar()
returns table (
    display_name        text,
    avatar_url          text,
    avatar_path         text,
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

    update public.seller_profiles sp
       set avatar_path = null,
           avatar_url = null
     where sp.user_id = v_uid;

    return query
    select sp.display_name,
           sp.avatar_url,
           sp.avatar_path,
           sp.member_since,
           sp.public_visibility
      from public.seller_profiles sp
     where sp.user_id = v_uid;
end;
$$;

comment on function public.clear_my_seller_avatar() is
    'Authenticated caller clears own avatar_url and avatar_path; Storage object deletion is client-side only.';

revoke all on function public.clear_my_seller_avatar() from public;
revoke all on function public.clear_my_seller_avatar() from anon;
grant execute on function public.clear_my_seller_avatar() to authenticated;
