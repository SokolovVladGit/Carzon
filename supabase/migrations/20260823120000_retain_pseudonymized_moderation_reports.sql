-- Retain moderation reports when referenced application entities are deleted.
--
-- Live foreign-key references are nullable and use ON DELETE SET NULL. Separate
-- pseudonymized UUID snapshots preserve the minimum original subject context
-- required for internal moderation without retaining profile/contact data,
-- conversation history, attachments, or listing/VIN details.

alter table public.user_reports
    add column if not exists original_reporter_user_id uuid,
    add column if not exists original_reported_user_id uuid,
    add column if not exists original_conversation_id uuid,
    add column if not exists original_listing_id uuid;

-- Backfill while the live references still exist. The listing snapshot remains
-- nullable because a listing may already have been deleted.
update public.user_reports
   set original_reporter_user_id =
           coalesce(original_reporter_user_id, reporter_user_id),
       original_reported_user_id =
           coalesce(original_reported_user_id, reported_user_id),
       original_conversation_id =
           coalesce(original_conversation_id, conversation_id),
       original_listing_id =
           coalesce(original_listing_id, listing_id);

alter table public.user_reports
    alter column original_reporter_user_id set not null,
    alter column original_reported_user_id set not null,
    alter column original_conversation_id set not null;

alter table public.user_reports
    drop constraint if exists user_reports_reporter_user_id_fkey,
    drop constraint if exists user_reports_reported_user_id_fkey,
    drop constraint if exists user_reports_conversation_id_fkey,
    drop constraint if exists user_reports_listing_id_fkey;

alter table public.user_reports
    alter column reporter_user_id drop not null,
    alter column reported_user_id drop not null,
    alter column conversation_id drop not null;

alter table public.user_reports
    add constraint user_reports_reporter_user_id_fkey
        foreign key (reporter_user_id)
        references auth.users (id)
        on delete set null,
    add constraint user_reports_reported_user_id_fkey
        foreign key (reported_user_id)
        references auth.users (id)
        on delete set null,
    add constraint user_reports_conversation_id_fkey
        foreign key (conversation_id)
        references public.conversations (id)
        on delete set null,
    add constraint user_reports_listing_id_fkey
        foreign key (listing_id)
        references public.listings (id)
        on delete set null;

comment on table public.user_reports is
    'Retained moderation reports. Live foreign-key references may be cleared on '
    'entity deletion; pseudonymized snapshots remain for internal moderation access.';

comment on column public.user_reports.original_reporter_user_id is
    'Pseudonymized snapshot of the authenticated reporter UUID at submission.';
comment on column public.user_reports.original_reported_user_id is
    'Pseudonymized snapshot of the validated reported-user UUID at submission.';
comment on column public.user_reports.original_conversation_id is
    'Pseudonymized snapshot of the validated conversation UUID at submission.';
comment on column public.user_reports.original_listing_id is
    'Optional pseudonymized snapshot of the validated listing UUID at submission.';

-- Preserve original submitted evidence while allowing moderation workflow
-- updates and foreign-key-driven clearing of live references.
create or replace function public.protect_user_report_original_evidence()
returns trigger
language plpgsql
set search_path = pg_catalog, pg_temp
as $$
begin
    if new.original_reporter_user_id is distinct from old.original_reporter_user_id
        or new.original_reported_user_id is distinct from old.original_reported_user_id
        or new.original_conversation_id is distinct from old.original_conversation_id
        or new.original_listing_id is distinct from old.original_listing_id
        or new.reason is distinct from old.reason
        or new.note is distinct from old.note
        or new.created_at is distinct from old.created_at then
        raise exception 'moderation_report_original_evidence_is_immutable'
            using errcode = '22000';
    end if;

    return new;
end;
$$;

revoke all on function public.protect_user_report_original_evidence() from public;
revoke all on function public.protect_user_report_original_evidence() from anon;
revoke all on function public.protect_user_report_original_evidence() from authenticated;

drop trigger if exists protect_user_report_original_evidence_before_update
    on public.user_reports;
create trigger protect_user_report_original_evidence_before_update
    before update on public.user_reports
    for each row
    execute function public.protect_user_report_original_evidence();

-- Preserve the existing client contract while deriving every snapshot from
-- authenticated or validated server-side values.
create or replace function public.report_user(
    p_conversation_id uuid,
    p_reason          text,
    p_note            text default null
)
returns table (
    report_id  uuid,
    status     text,
    created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid           uuid := auth.uid();
    v_other_user_id uuid;
    v_listing_id    uuid;
    v_kind          text;
    v_reason        text := lower(trim(both from coalesce(p_reason, '')));
    v_note          text := nullif(trim(both from coalesce(p_note, '')), '');
    v_report_id     uuid;
    v_created_at    timestamptz;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if v_reason = '' then
        raise exception 'report reason is required'
            using errcode = '22023';
    end if;

    if v_reason not in ('harassment', 'spam', 'scam', 'inappropriate', 'other') then
        raise exception 'invalid report reason'
            using errcode = '22023';
    end if;

    if v_note is not null and char_length(v_note) > 1000 then
        raise exception 'report note is too long'
            using errcode = '22023';
    end if;

    select p.other_user_id, p.listing_id, p.conversation_kind
      into v_other_user_id, v_listing_id, v_kind
      from public.carzon_messaging_peer_from_conversation(p_conversation_id, v_uid) p;

    if v_kind = 'support'
        or public.carzon_is_support_user_id(v_other_user_id) then
        raise exception 'not available for support conversations'
            using errcode = '42501';
    end if;

    insert into public.user_reports (
        reporter_user_id,
        reported_user_id,
        conversation_id,
        listing_id,
        original_reporter_user_id,
        original_reported_user_id,
        original_conversation_id,
        original_listing_id,
        reason,
        note,
        status
    ) values (
        v_uid,
        v_other_user_id,
        p_conversation_id,
        v_listing_id,
        v_uid,
        v_other_user_id,
        p_conversation_id,
        v_listing_id,
        v_reason,
        v_note,
        'pending'
    )
    returning id, created_at
      into v_report_id, v_created_at;

    report_id := v_report_id;
    status := 'pending';
    created_at := v_created_at;
    return next;
end;
$$;

comment on function public.report_user(uuid, text, text) is
    'Stores a retained moderation report; live subjects are validated and '
    'pseudonymized snapshot UUIDs are derived server-side.';

alter table public.user_reports enable row level security;

revoke all on table public.user_reports from anon;
revoke all on table public.user_reports from authenticated;
revoke all on table public.user_reports from public;

revoke all on function public.report_user(uuid, text, text) from public;
revoke all on function public.report_user(uuid, text, text) from anon;
grant execute on function public.report_user(uuid, text, text) to authenticated;
