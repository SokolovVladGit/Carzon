-- Carzon — single per-user filter alert settings (criteria JSON, future notifications flag).
--
-- Scope:
--   * Table `filter_alert_settings`: at most one row per user (`user_id` PK).
--   * `criteria` nullable until the user configures a filter in Account settings.
--   * `notifications_enabled` reserved for future delivery — client keeps it false.
--   * RLS: authenticated users read/write only their own row.
--   * Direct PostgREST from Flutter (anon + RLS), no SECURITY DEFINER RPCs.
--   * No unrelated table teardown in migration history — remove stray experimental
--     tables manually in local databases if ever needed.

------------------------------------------------------------------------------
-- 1 — Table
------------------------------------------------------------------------------

create table if not exists public.filter_alert_settings (
    user_id                 uuid primary key references auth.users (id) on delete cascade,
    criteria                jsonb,
    notifications_enabled   boolean not null default false,
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now()
);

comment on table public.filter_alert_settings is
    'Single saved listing-discovery snapshot per user for future new-listing alerts; delivery not implemented yet.';
comment on column public.filter_alert_settings.criteria is
    'Structured criteria JSON (Flutter schemaVersion) or null if unset.';
comment on column public.filter_alert_settings.notifications_enabled is
    'Future: opt-in to push when infrastructure exists. App does not enable this in MVP.';

------------------------------------------------------------------------------
-- 2 — updated_at trigger
------------------------------------------------------------------------------

create or replace function public.touch_filter_alert_settings_updated_at()
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

drop trigger if exists filter_alert_settings_touch_updated_at on public.filter_alert_settings;

create trigger filter_alert_settings_touch_updated_at
    before update on public.filter_alert_settings
    for each row execute function public.touch_filter_alert_settings_updated_at();

------------------------------------------------------------------------------
-- 3 — Row Level Security
------------------------------------------------------------------------------

alter table public.filter_alert_settings enable row level security;

grant select, insert, update, delete on public.filter_alert_settings to authenticated;

drop policy if exists filter_alert_settings_select_own on public.filter_alert_settings;
create policy filter_alert_settings_select_own
    on public.filter_alert_settings
    for select
    to authenticated
    using (user_id = (select auth.uid()));

drop policy if exists filter_alert_settings_insert_own on public.filter_alert_settings;
create policy filter_alert_settings_insert_own
    on public.filter_alert_settings
    for insert
    to authenticated
    with check (
        user_id = (select auth.uid())
        and user_id is not null
    );

drop policy if exists filter_alert_settings_update_own on public.filter_alert_settings;
create policy filter_alert_settings_update_own
    on public.filter_alert_settings
    for update
    to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

drop policy if exists filter_alert_settings_delete_own on public.filter_alert_settings;
create policy filter_alert_settings_delete_own
    on public.filter_alert_settings
    for delete
    to authenticated
    using (user_id = (select auth.uid()));
