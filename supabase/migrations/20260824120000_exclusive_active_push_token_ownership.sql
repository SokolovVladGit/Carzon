-- Carzon — exclusive active ownership for physical push tokens.
--
-- A failed sign-out cleanup must not leave the same FCM token active for
-- multiple accounts. Historical inactive rows are retained.

------------------------------------------------------------------------------
-- 1 — Normalize any pre-existing duplicate active ownership
------------------------------------------------------------------------------

with ranked_active_tokens as (
    select
        id,
        row_number() over (
            partition by token
            order by
                last_seen_at desc nulls last,
                updated_at desc nulls last,
                created_at desc nulls last,
                id desc
        ) as ownership_rank
    from public.user_push_tokens
    where is_active = true
)
update public.user_push_tokens upt
   set is_active = false,
       updated_at = now()
  from ranked_active_tokens ranked
 where upt.id = ranked.id
   and ranked.ownership_rank > 1;

create unique index if not exists user_push_tokens_one_active_owner_per_token_idx
    on public.user_push_tokens (token)
    where is_active = true;

comment on index public.user_push_tokens_one_active_owner_per_token_idx is
    'A physical push token may have at most one active Carzon account owner.';

------------------------------------------------------------------------------
-- 2 — Registration atomically transfers active ownership to auth.uid()
------------------------------------------------------------------------------

create or replace function public.register_push_token(
    p_token text,
    p_platform text,
    p_app_version text default null,
    p_device_id text default null,
    p_locale text default null
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid   uuid := auth.uid();
    v_tok   text := trim(both from coalesce(p_token, ''));
    v_plat  text := lower(trim(both from coalesce(p_platform, '')));
    v_id    uuid;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if v_tok = '' then
        raise exception 'token is required'
            using errcode = '22023';
    end if;

    if v_plat not in ('android', 'ios', 'web', 'unknown') then
        raise exception 'invalid platform'
            using errcode = '22023';
    end if;

    -- Serialize registrations for this physical token. This makes the
    -- ownership transfer deterministic even when two sessions register the
    -- same token concurrently; the later transaction becomes authoritative.
    perform pg_advisory_xact_lock(hashtextextended(v_tok, 0));

    update public.user_push_tokens
       set is_active = false,
           updated_at = now()
     where token = v_tok
       and user_id <> v_uid
       and is_active = true;

    insert into public.user_push_tokens (
        user_id,
        token,
        platform,
        app_version,
        device_id,
        locale,
        is_active,
        last_seen_at
    ) values (
        v_uid,
        v_tok,
        v_plat,
        nullif(trim(both from coalesce(p_app_version, '')), ''),
        nullif(trim(both from coalesce(p_device_id, '')), ''),
        nullif(trim(both from coalesce(p_locale, '')), ''),
        true,
        now()
    )
    on conflict on constraint user_push_tokens_user_token_uniq do update
        set platform = excluded.platform,
            app_version = excluded.app_version,
            device_id = excluded.device_id,
            locale = excluded.locale,
            is_active = true,
            last_seen_at = now(),
            updated_at = now()
    returning id into v_id;

    return v_id;
end;
$$;

revoke all on function public.register_push_token(text, text, text, text, text)
    from public;
revoke all on function public.register_push_token(text, text, text, text, text)
    from anon;
grant execute on function public.register_push_token(text, text, text, text, text)
    to authenticated;
