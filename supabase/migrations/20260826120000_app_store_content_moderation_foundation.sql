-- CARZON App Store Phase 1: server-authoritative UGC filtering, structured
-- listing reports, and a minimal operator-only moderation queue.
--
-- This migration is additive. It does not remove content, suspend users, or
-- resolve reports automatically. Image review remains a human moderation task.

create schema if not exists carzon_private;
revoke all on schema carzon_private from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 1 — Maintainable objectionable-text baseline
-- ---------------------------------------------------------------------------

create table if not exists carzon_private.moderation_text_rules (
    code       text primary key,
    language   text not null,
    category   text not null,
    match_mode text not null,
    pattern    text not null,
    enabled    boolean not null default true,
    created_at timestamptz not null default now(),

    constraint moderation_text_rules_language_chk
        check (language in ('en', 'ro', 'ru')),
    constraint moderation_text_rules_category_chk
        check (category in ('abuse', 'sexual_safety', 'threat', 'scam')),
    constraint moderation_text_rules_match_mode_chk
        check (match_mode in ('token', 'compact_contains')),
    constraint moderation_text_rules_pattern_chk
        check (pattern = lower(pattern) and char_length(pattern) between 3 and 80)
);

revoke all on table carzon_private.moderation_text_rules
    from public, anon, authenticated;

insert into carzon_private.moderation_text_rules (
    code,
    language,
    category,
    match_mode,
    pattern
) values
    ('en_abuse_slur_1', 'en', 'abuse', 'token', 'nigger'),
    ('en_threat_1', 'en', 'threat', 'compact_contains', 'killyourself'),
    ('en_child_safety_1', 'en', 'sexual_safety', 'compact_contains', 'childporn'),
    ('en_scam_1', 'en', 'scam', 'compact_contains', 'guaranteedprofit'),
    ('ro_abuse_1', 'ro', 'abuse', 'token', 'muie'),
    ('ro_threat_1', 'ro', 'threat', 'compact_contains', 'teomor'),
    ('ro_child_safety_1', 'ro', 'sexual_safety', 'compact_contains', 'pornografieinfantila'),
    ('ro_scam_1', 'ro', 'scam', 'compact_contains', 'castiggarantat'),
    ('ru_abuse_1', 'ru', 'abuse', 'compact_contains', 'пошелнахуй'),
    ('ru_abuse_2', 'ru', 'abuse', 'compact_contains', 'пошланахуй'),
    ('ru_threat_1', 'ru', 'threat', 'compact_contains', 'убьютебя'),
    ('ru_threat_2', 'ru', 'threat', 'compact_contains', 'убьювас'),
    ('ru_child_safety_1', 'ru', 'sexual_safety', 'compact_contains', 'детскоепорно'),
    ('ru_scam_1', 'ru', 'scam', 'compact_contains', 'гарантированныйдоход')
on conflict (code) do update
   set language = excluded.language,
       category = excluded.category,
       match_mode = excluded.match_mode,
       pattern = excluded.pattern;

create or replace function carzon_private.normalize_moderation_text(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
    select btrim(
        regexp_replace(
            translate(
                lower(coalesce(p_text, '')),
                'ăâîșşțţ013457',
                'aaissttoieast'
            ),
            '[^[:alnum:]]+',
            ' ',
            'g'
        )
    );
$$;

create or replace function carzon_private.compact_moderation_text(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
    select regexp_replace(
        carzon_private.normalize_moderation_text(p_text),
        '[^[:alnum:]]+',
        '',
        'g'
    );
$$;

create or replace function carzon_private.assert_user_text_allowed(
    p_text text,
    p_surface text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_normalized text;
    v_compact text;
begin
    if p_text is null or btrim(p_text) = '' then
        return;
    end if;

    v_normalized := carzon_private.normalize_moderation_text(p_text);
    v_compact := carzon_private.compact_moderation_text(p_text);

    if exists (
        select 1
          from carzon_private.moderation_text_rules r
         where r.enabled
           and (
               (r.match_mode = 'token'
                and (' ' || v_normalized || ' ') like ('% ' || r.pattern || ' %'))
               or
               (r.match_mode = 'compact_contains'
                and strpos(v_compact, r.pattern) > 0)
           )
    ) then
        -- Deliberately stable and content-free: clients localize this code and
        -- rejected private text is not copied into logs or moderation tables.
        raise exception 'carzon_content_rejected'
            using errcode = 'P0001', detail = 'surface=' || coalesce(p_surface, 'unknown');
    end if;
end;
$$;

revoke all on function carzon_private.normalize_moderation_text(text)
    from public, anon, authenticated;
revoke all on function carzon_private.compact_moderation_text(text)
    from public, anon, authenticated;
revoke all on function carzon_private.assert_user_text_allowed(text, text)
    from public, anon, authenticated;

create or replace function public.carzon_enforce_user_text()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if tg_table_name = 'listings' then
        if tg_op = 'INSERT' or new.title is distinct from old.title then
            perform carzon_private.assert_user_text_allowed(new.title, 'listing_title');
        end if;
        if tg_op = 'INSERT' or new.description is distinct from old.description then
            perform carzon_private.assert_user_text_allowed(new.description, 'listing_description');
        end if;
        if tg_op = 'INSERT' or new.registration is distinct from old.registration then
            perform carzon_private.assert_user_text_allowed(new.registration, 'listing_registration');
        end if;
        if tg_op = 'INSERT' or new.make is distinct from old.make then
            perform carzon_private.assert_user_text_allowed(new.make, 'listing_make');
        end if;
        if tg_op = 'INSERT' or new.model is distinct from old.model then
            perform carzon_private.assert_user_text_allowed(new.model, 'listing_model');
        end if;
        if tg_op = 'INSERT' or new.city is distinct from old.city then
            perform carzon_private.assert_user_text_allowed(new.city, 'listing_city');
        end if;
    elsif tg_table_name = 'seller_profiles' then
        if tg_op = 'INSERT' or new.display_name is distinct from old.display_name then
            perform carzon_private.assert_user_text_allowed(new.display_name, 'seller_display_name');
        end if;
    elsif tg_table_name = 'messages' then
        if tg_op = 'INSERT' or new.body is distinct from old.body then
            perform carzon_private.assert_user_text_allowed(new.body, 'message_body');
        end if;
    end if;

    return new;
end;
$$;

revoke all on function public.carzon_enforce_user_text()
    from public, anon, authenticated;

drop trigger if exists listings_enforce_user_text on public.listings;
create trigger listings_enforce_user_text
    before insert or update on public.listings
    for each row execute function public.carzon_enforce_user_text();

drop trigger if exists seller_profiles_enforce_user_text on public.seller_profiles;
create trigger seller_profiles_enforce_user_text
    before insert or update on public.seller_profiles
    for each row execute function public.carzon_enforce_user_text();

drop trigger if exists messages_enforce_user_text on public.messages;
create trigger messages_enforce_user_text
    before insert or update on public.messages
    for each row execute function public.carzon_enforce_user_text();

-- ---------------------------------------------------------------------------
-- 2 — Structured listing reports (authenticated submission, RLS locked)
-- ---------------------------------------------------------------------------

create table if not exists public.listing_reports (
    id                              uuid primary key default gen_random_uuid(),
    reporter_user_id                uuid null references auth.users (id) on delete set null,
    listing_id                      uuid null references public.listings (id) on delete set null,
    original_reporter_user_id       uuid not null,
    original_listing_id             uuid not null,
    original_listing_owner_user_id  uuid null,
    listing_title_snapshot          text not null,
    listing_description_snapshot    text null,
    listing_vehicle_snapshot        text not null,
    reason                          text not null,
    note                            text null,
    status                          text not null default 'pending',
    moderation_note                 text null,
    created_at                      timestamptz not null default now(),
    reviewed_at                     timestamptz null,
    resolved_at                     timestamptz null,

    constraint listing_reports_reason_chk
        check (reason in (
            'scam', 'spam', 'inappropriate', 'misleading', 'prohibited', 'other'
        )),
    constraint listing_reports_note_len_chk
        check (note is null or char_length(note) <= 1000),
    constraint listing_reports_status_chk
        check (status in ('pending', 'reviewed', 'dismissed', 'resolved')),
    constraint listing_reports_moderation_note_len_chk
        check (moderation_note is null or char_length(moderation_note) <= 2000)
);

comment on table public.listing_reports is
    'Retained structured listing reports. RPC snapshots omit contact data, VIN, and image URLs.';
comment on column public.listing_reports.original_reporter_user_id is
    'Pseudonymized authenticated reporter UUID retained for abuse prevention and safety evidence.';
comment on column public.listing_reports.listing_description_snapshot is
    'Submitted listing description capped to 2000 characters; no contact, VIN, or image data.';

create index if not exists listing_reports_pending_queue_idx
    on public.listing_reports (created_at asc)
    where status = 'pending';

create index if not exists listing_reports_listing_created_at_idx
    on public.listing_reports (original_listing_id, created_at desc);

create index if not exists listing_reports_reporter_created_at_idx
    on public.listing_reports (original_reporter_user_id, created_at desc);

create unique index if not exists listing_reports_one_pending_per_reporter_listing_idx
    on public.listing_reports (reporter_user_id, listing_id)
    where status = 'pending' and reporter_user_id is not null and listing_id is not null;

alter table public.listing_reports enable row level security;
revoke all on table public.listing_reports from public;
revoke all on table public.listing_reports from anon;
revoke all on table public.listing_reports from authenticated;
grant select, update on table public.listing_reports to service_role;

create or replace function public.protect_listing_report_original_evidence()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if new.original_reporter_user_id is distinct from old.original_reporter_user_id
        or new.original_listing_id is distinct from old.original_listing_id
        or new.original_listing_owner_user_id is distinct from old.original_listing_owner_user_id
        or new.listing_title_snapshot is distinct from old.listing_title_snapshot
        or new.listing_description_snapshot is distinct from old.listing_description_snapshot
        or new.listing_vehicle_snapshot is distinct from old.listing_vehicle_snapshot
        or new.reason is distinct from old.reason
        or new.note is distinct from old.note
        or new.created_at is distinct from old.created_at then
        raise exception 'moderation_report_original_evidence_is_immutable'
            using errcode = '22000';
    end if;
    return new;
end;
$$;

revoke all on function public.protect_listing_report_original_evidence()
    from public, anon, authenticated;

drop trigger if exists protect_listing_report_original_evidence_before_update
    on public.listing_reports;
create trigger protect_listing_report_original_evidence_before_update
    before update on public.listing_reports
    for each row execute function public.protect_listing_report_original_evidence();

create or replace function public.report_listing(
    p_listing_id uuid,
    p_reason text,
    p_note text default null
)
returns table (
    report_id uuid,
    status text,
    created_at timestamptz,
    already_pending boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := auth.uid();
    v_listing public.listings;
    v_reason text := lower(btrim(coalesce(p_reason, '')));
    v_note text := nullif(btrim(coalesce(p_note, '')), '');
    v_existing public.listing_reports;
    v_report public.listing_reports;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_listing_id is null then
        raise exception 'listing not found'
            using errcode = '22023';
    end if;

    if v_reason not in ('scam', 'spam', 'inappropriate', 'misleading', 'prohibited', 'other') then
        raise exception 'invalid listing report reason'
            using errcode = '22023';
    end if;

    if v_note is not null and char_length(v_note) > 1000 then
        raise exception 'report note is too long'
            using errcode = '22023';
    end if;

    select l.* into v_listing
      from public.listings l
     where l.id = p_listing_id;

    if not found then
        raise exception 'listing not found'
            using errcode = '22023';
    end if;

    if v_listing.seller_id = v_uid then
        raise exception 'cannot report own listing'
            using errcode = '22023';
    end if;

    select r.* into v_existing
      from public.listing_reports r
     where r.reporter_user_id = v_uid
       and r.listing_id = p_listing_id
       and r.status = 'pending'
     order by r.created_at desc
     limit 1;

    if found then
        report_id := v_existing.id;
        status := v_existing.status;
        created_at := v_existing.created_at;
        already_pending := true;
        return next;
        return;
    end if;

    insert into public.listing_reports (
        reporter_user_id,
        listing_id,
        original_reporter_user_id,
        original_listing_id,
        original_listing_owner_user_id,
        listing_title_snapshot,
        listing_description_snapshot,
        listing_vehicle_snapshot,
        reason,
        note
    ) values (
        v_uid,
        v_listing.id,
        v_uid,
        v_listing.id,
        v_listing.seller_id,
        left(v_listing.title, 300),
        nullif(left(coalesce(v_listing.description, ''), 2000), ''),
        left(concat_ws(' ', v_listing.make, v_listing.model, v_listing.year::text), 500),
        v_reason,
        v_note
    )
    returning * into v_report;

    report_id := v_report.id;
    status := v_report.status;
    created_at := v_report.created_at;
    already_pending := false;
    return next;
exception
    when unique_violation then
        select r.* into v_existing
          from public.listing_reports r
         where r.reporter_user_id = v_uid
           and r.listing_id = p_listing_id
           and r.status = 'pending'
         order by r.created_at desc
         limit 1;
        if found then
            report_id := v_existing.id;
            status := v_existing.status;
            created_at := v_existing.created_at;
            already_pending := true;
            return next;
            return;
        end if;
        raise;
end;
$$;

comment on function public.report_listing(uuid, text, text) is
    'Authenticated user submits a structured listing report. Reporter and listing snapshots are derived server-side.';

revoke all on function public.report_listing(uuid, text, text)
    from public, anon;
grant execute on function public.report_listing(uuid, text, text)
    to authenticated;

-- ---------------------------------------------------------------------------
-- 3 — Minimal operator-only moderation workflow
-- ---------------------------------------------------------------------------

alter table public.user_reports
    drop constraint if exists user_reports_status_chk;
alter table public.user_reports
    add constraint user_reports_status_chk
        check (status in ('pending', 'reviewed', 'dismissed', 'resolved'));
alter table public.user_reports
    add column if not exists moderation_note text,
    add column if not exists reviewed_at timestamptz,
    add column if not exists resolved_at timestamptz;
alter table public.user_reports
    drop constraint if exists user_reports_moderation_note_len_chk;
alter table public.user_reports
    add constraint user_reports_moderation_note_len_chk
        check (moderation_note is null or char_length(moderation_note) <= 2000);

create index if not exists user_reports_pending_queue_idx
    on public.user_reports (created_at asc)
    where status = 'pending';

create or replace function public.moderation_list_pending_reports(
    p_limit integer default 100
)
returns setof jsonb
language sql
stable
security definer
set search_path = ''
as $$
    with combined as (
        select
            'user'::text as report_type,
            r.id,
            r.created_at,
            r.reason,
            r.note,
            jsonb_build_object(
                'reported_user_id', r.original_reported_user_id,
                'conversation_id', r.original_conversation_id,
                'listing_id', r.original_listing_id
            ) as context
          from public.user_reports r
         where r.status = 'pending'
        union all
        select
            'listing'::text,
            r.id,
            r.created_at,
            r.reason,
            r.note,
            jsonb_build_object(
                'listing_id', r.original_listing_id,
                'listing_owner_user_id', r.original_listing_owner_user_id,
                'title', r.listing_title_snapshot,
                'description', r.listing_description_snapshot,
                'vehicle', r.listing_vehicle_snapshot
            )
          from public.listing_reports r
         where r.status = 'pending'
    )
    select jsonb_build_object(
        'report_type', c.report_type,
        'report_id', c.id,
        'created_at', c.created_at,
        'reason', c.reason,
        'note', c.note,
        'context', c.context
    )
      from combined c
     order by c.created_at asc
     limit greatest(1, least(coalesce(p_limit, 100), 500));
$$;

create or replace function public.moderation_update_report_status(
    p_report_type text,
    p_report_id uuid,
    p_status text,
    p_moderation_note text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_status text := lower(btrim(coalesce(p_status, '')));
    v_note text := nullif(btrim(coalesce(p_moderation_note, '')), '');
begin
    if p_report_type not in ('user', 'listing') then
        raise exception 'invalid report type' using errcode = '22023';
    end if;
    if v_status not in ('reviewed', 'dismissed', 'resolved') then
        raise exception 'invalid moderation status' using errcode = '22023';
    end if;
    if v_note is not null and char_length(v_note) > 2000 then
        raise exception 'moderation note is too long' using errcode = '22023';
    end if;

    if p_report_type = 'user' then
        update public.user_reports r
           set status = v_status,
               moderation_note = v_note,
               reviewed_at = coalesce(r.reviewed_at, now()),
               resolved_at = case
                   when v_status in ('dismissed', 'resolved') then coalesce(r.resolved_at, now())
                   else null
               end
         where r.id = p_report_id;
    else
        update public.listing_reports r
           set status = v_status,
               moderation_note = v_note,
               reviewed_at = coalesce(r.reviewed_at, now()),
               resolved_at = case
                   when v_status in ('dismissed', 'resolved') then coalesce(r.resolved_at, now())
                   else null
               end
         where r.id = p_report_id;
    end if;

    return found;
end;
$$;

revoke all on function public.moderation_list_pending_reports(integer)
    from public, anon, authenticated;
revoke all on function public.moderation_update_report_status(text, uuid, text, text)
    from public, anon, authenticated;
grant execute on function public.moderation_list_pending_reports(integer)
    to service_role;
grant execute on function public.moderation_update_report_status(text, uuid, text, text)
    to service_role;

comment on function public.moderation_list_pending_reports(integer) is
    'Service-role-only combined pending moderation queue. Does not expose reporter contact details.';
comment on function public.moderation_update_report_status(text, uuid, text, text) is
    'Service-role-only status transition for user or listing reports.';
