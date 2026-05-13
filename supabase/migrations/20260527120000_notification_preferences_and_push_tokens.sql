-- Carzon — Phase 1: notification preferences + push token storage (foundation only).
--
-- No notification delivery, no Edge Functions, no FCM sends. Defaults keep all
-- preference flags false until future phases enable permission/token/delivery.
-- Clients should use SECURITY DEFINER RPCs below for writes; direct DML on these
-- tables is not granted to authenticated (except optional future reads via RLS).

------------------------------------------------------------------------------
-- 1 — notification_preferences
------------------------------------------------------------------------------

create table if not exists public.notification_preferences (
    user_id                 uuid primary key references auth.users (id) on delete cascade,
    global_enabled          boolean not null default false,
    messages_enabled         boolean not null default false,
    filter_alerts_enabled   boolean not null default false,
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now()
);

comment on table public.notification_preferences is
    'Phase 1 foundation: per-user toggles for future push. All default false; no delivery implied.';
comment on column public.notification_preferences.global_enabled is
    'Future: master switch after OS permission + FCM registration.';
comment on column public.notification_preferences.messages_enabled is
    'Future: in-app chat push opt-in.';
comment on column public.notification_preferences.filter_alerts_enabled is
    'Future: new-listing alert opt-in (requires matching + dedup).';

------------------------------------------------------------------------------
-- 2 — user_push_tokens
------------------------------------------------------------------------------

create table if not exists public.user_push_tokens (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users (id) on delete cascade,
    token           text not null,
    platform        text not null,
    app_version     text,
    device_id       text,
    locale          text,
    is_active       boolean not null default true,
    last_seen_at    timestamptz not null default now(),
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),

    constraint user_push_tokens_platform_chk check (
        platform in ('android', 'ios', 'web', 'unknown')
    ),
    constraint user_push_tokens_token_nonempty_chk check (char_length(trim(both from token)) > 0),
    constraint user_push_tokens_user_token_uniq unique (user_id, token)
);

comment on table public.user_push_tokens is
    'Phase 1: device FCM/APNs token registry (future). is_active supports soft revoke.';

create index if not exists user_push_tokens_user_id_idx
    on public.user_push_tokens (user_id);

create index if not exists user_push_tokens_active_by_user_idx
    on public.user_push_tokens (user_id)
    where is_active = true;

------------------------------------------------------------------------------
-- 3 — updated_at triggers
------------------------------------------------------------------------------

create or replace function public.touch_notification_preferences_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists notification_preferences_touch_updated_at
    on public.notification_preferences;
create trigger notification_preferences_touch_updated_at
    before update on public.notification_preferences
    for each row
    execute function public.touch_notification_preferences_updated_at();

create or replace function public.touch_user_push_tokens_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists user_push_tokens_touch_updated_at on public.user_push_tokens;
create trigger user_push_tokens_touch_updated_at
    before update on public.user_push_tokens
    for each row
    execute function public.touch_user_push_tokens_updated_at();

------------------------------------------------------------------------------
-- 4 — RLS
------------------------------------------------------------------------------

alter table public.notification_preferences enable row level security;
alter table public.user_push_tokens enable row level security;

-- Read-only direct access: own rows (RPCs handle writes).
drop policy if exists notification_preferences_select_own on public.notification_preferences;
create policy notification_preferences_select_own
    on public.notification_preferences
    for select
    to authenticated
    using (user_id = (select auth.uid()));

drop policy if exists user_push_tokens_select_own on public.user_push_tokens;
create policy user_push_tokens_select_own
    on public.user_push_tokens
    for select
    to authenticated
    using (user_id = (select auth.uid()));

-- No insert/update/delete policies for authenticated — mutations via RPC only.

------------------------------------------------------------------------------
-- 5 — Table privileges (Data API / PostgREST): SELECT own rows only
------------------------------------------------------------------------------

revoke all on table public.notification_preferences from public;
revoke insert, update, delete on table public.notification_preferences from authenticated;

revoke all on table public.user_push_tokens from public;
revoke insert, update, delete on table public.user_push_tokens from authenticated;

grant select on table public.notification_preferences to authenticated;
grant select on table public.user_push_tokens to authenticated;

------------------------------------------------------------------------------
-- 6 — RPC: get_my_notification_preferences
------------------------------------------------------------------------------

create or replace function public.get_my_notification_preferences()
returns public.notification_preferences
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_row public.notification_preferences;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    insert into public.notification_preferences (user_id)
    values (v_uid)
    on conflict (user_id) do nothing;

    select *
      into strict v_row
      from public.notification_preferences np
     where np.user_id = v_uid;

    return v_row;
exception
    when no_data_found then
        raise exception 'notification preferences missing'
            using errcode = '22000';
end;
$$;

revoke all on function public.get_my_notification_preferences() from public;
revoke all on function public.get_my_notification_preferences() from anon;
grant execute on function public.get_my_notification_preferences() to authenticated;

------------------------------------------------------------------------------
-- 7 — RPC: update_my_notification_preferences
------------------------------------------------------------------------------

create or replace function public.update_my_notification_preferences(
    p_global_enabled boolean,
    p_messages_enabled boolean,
    p_filter_alerts_enabled boolean
) returns public.notification_preferences
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_row public.notification_preferences;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    insert into public.notification_preferences (
        user_id,
        global_enabled,
        messages_enabled,
        filter_alerts_enabled
    ) values (
        v_uid,
        coalesce(p_global_enabled, false),
        coalesce(p_messages_enabled, false),
        coalesce(p_filter_alerts_enabled, false)
    )
    on conflict (user_id) do update
        set global_enabled = excluded.global_enabled,
            messages_enabled = excluded.messages_enabled,
            filter_alerts_enabled = excluded.filter_alerts_enabled,
            updated_at = now()
    returning * into strict v_row;

    return v_row;
end;
$$;

revoke all on function public.update_my_notification_preferences(boolean, boolean, boolean) from public;
revoke all on function public.update_my_notification_preferences(boolean, boolean, boolean) from anon;
grant execute on function public.update_my_notification_preferences(boolean, boolean, boolean) to authenticated;

------------------------------------------------------------------------------
-- 8 — RPC: register_push_token
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

revoke all on function public.register_push_token(text, text, text, text, text) from public;
revoke all on function public.register_push_token(text, text, text, text, text) from anon;
grant execute on function public.register_push_token(text, text, text, text, text) to authenticated;

------------------------------------------------------------------------------
-- 9 — RPC: deactivate_push_token
------------------------------------------------------------------------------

create or replace function public.deactivate_push_token(p_token text) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_tok text := trim(both from coalesce(p_token, ''));
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if v_tok = '' then
        raise exception 'token is required'
            using errcode = '22023';
    end if;

    update public.user_push_tokens
       set is_active = false,
           updated_at = now()
     where user_id = v_uid
       and token = v_tok;
end;
$$;

revoke all on function public.deactivate_push_token(text) from public;
revoke all on function public.deactivate_push_token(text) from anon;
grant execute on function public.deactivate_push_token(text) to authenticated;

------------------------------------------------------------------------------
-- 10 — RPC: deactivate_my_push_tokens
------------------------------------------------------------------------------

create or replace function public.deactivate_my_push_tokens() returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    update public.user_push_tokens
       set is_active = false,
           updated_at = now()
     where user_id = v_uid
       and is_active = true;
end;
$$;

revoke all on function public.deactivate_my_push_tokens() from public;
revoke all on function public.deactivate_my_push_tokens() from anon;
grant execute on function public.deactivate_my_push_tokens() to authenticated;
