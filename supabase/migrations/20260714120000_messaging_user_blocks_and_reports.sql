-- Carzon — Milestone 0.3 Phase A: user block/report foundation for listing conversations.
--
-- Adds user_blocks + user_reports tables, block/report RPCs, bidirectional block helper,
-- and gates on send_message, send_message_with_attachment, get_or_create_conversation,
-- and enqueue_message_notification_event.
--
-- Support conversations remain exempt from block/report/send gates.
-- Does not expose auth private fields, VIN, or official-data internals.

-- ---------------------------------------------------------------------------
-- 1 — user_blocks
-- ---------------------------------------------------------------------------

create table if not exists public.user_blocks (
    blocker_user_id uuid        not null references auth.users (id) on delete cascade,
    blocked_user_id uuid        not null references auth.users (id) on delete cascade,
    created_at      timestamptz not null default now(),

    primary key (blocker_user_id, blocked_user_id),
    constraint user_blocks_no_self_block_chk
        check (blocker_user_id <> blocked_user_id)
);

comment on table public.user_blocks is
    'One-way user blocks for listing chat safety. Mutations via RPC only.';

create index if not exists user_blocks_blocker_created_at_idx
    on public.user_blocks (blocker_user_id, created_at desc);

alter table public.user_blocks enable row level security;

revoke insert, update, delete on public.user_blocks from anon;
revoke insert, update, delete on public.user_blocks from authenticated;
revoke insert, update, delete on public.user_blocks from public;

drop policy if exists user_blocks_blocker_select on public.user_blocks;
create policy user_blocks_blocker_select
    on public.user_blocks
    for select
    to authenticated
    using (blocker_user_id = auth.uid());

grant select on public.user_blocks to authenticated;

-- ---------------------------------------------------------------------------
-- 2 — user_reports
-- ---------------------------------------------------------------------------

create table if not exists public.user_reports (
    id               uuid primary key default gen_random_uuid(),
    reporter_user_id uuid        not null references auth.users (id) on delete cascade,
    reported_user_id uuid        not null references auth.users (id) on delete cascade,
    conversation_id  uuid        not null references public.conversations (id) on delete cascade,
    listing_id       uuid        null references public.listings (id) on delete set null,
    reason           text        not null,
    note             text        null,
    status           text        not null default 'pending',
    created_at       timestamptz not null default now(),

    constraint user_reports_reporter_not_reported_chk
        check (reporter_user_id <> reported_user_id),
    constraint user_reports_reason_chk
        check (reason in ('harassment', 'spam', 'scam', 'inappropriate', 'other')),
    constraint user_reports_status_chk
        check (status in ('pending', 'reviewed', 'dismissed')),
    constraint user_reports_note_len_chk
        check (note is null or char_length(note) <= 1000)
);

comment on table public.user_reports is
    'User safety reports tied to listing conversations. Insert via report_user RPC only.';

create index if not exists user_reports_reporter_created_at_idx
    on public.user_reports (reporter_user_id, created_at desc);

create index if not exists user_reports_conversation_created_at_idx
    on public.user_reports (conversation_id, created_at desc);

alter table public.user_reports enable row level security;

revoke all on table public.user_reports from anon;
revoke all on table public.user_reports from authenticated;
revoke all on table public.user_reports from public;

-- ---------------------------------------------------------------------------
-- 3 — Internal helpers
-- ---------------------------------------------------------------------------

create or replace function public.carzon_is_support_user_id(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
          from auth.users u
         where u.id = p_user_id
           and lower(trim(u.email)) = lower(trim('admin@carzon.com'))
    );
$$;

comment on function public.carzon_is_support_user_id(uuid) is
    'True when p_user_id is the configured Carzon support account.';

revoke all on function public.carzon_is_support_user_id(uuid) from public;
revoke all on function public.carzon_is_support_user_id(uuid) from anon;
revoke all on function public.carzon_is_support_user_id(uuid) from authenticated;

create or replace function public.carzon_users_are_blocked(
    p_user_a uuid,
    p_user_b uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select
        p_user_a is not null
        and p_user_b is not null
        and p_user_a <> p_user_b
        and exists (
            select 1
              from public.user_blocks b
             where (b.blocker_user_id = p_user_a and b.blocked_user_id = p_user_b)
                or (b.blocker_user_id = p_user_b and b.blocked_user_id = p_user_a)
        );
$$;

comment on function public.carzon_users_are_blocked(uuid, uuid) is
    'True when either user has blocked the other (bidirectional messaging gate).';

revoke all on function public.carzon_users_are_blocked(uuid, uuid) from public;
revoke all on function public.carzon_users_are_blocked(uuid, uuid) from anon;
revoke all on function public.carzon_users_are_blocked(uuid, uuid) from authenticated;

create or replace function public.carzon_messaging_peer_from_conversation(
    p_conversation_id uuid,
    p_caller_id       uuid
)
returns table (
    other_user_id     uuid,
    listing_id        uuid,
    conversation_kind text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_buyer_id   uuid;
    v_seller_id  uuid;
    v_kind       text;
    v_listing_id uuid;
begin
    select c.buyer_id, c.seller_id, c.conversation_kind, c.listing_id
      into v_buyer_id, v_seller_id, v_kind, v_listing_id
      from public.conversations c
     where c.id = p_conversation_id;

    if not found then
        raise exception 'conversation not found'
            using errcode = '22023';
    end if;

    if p_caller_id <> v_buyer_id and p_caller_id <> v_seller_id then
        raise exception 'not a participant in this conversation'
            using errcode = '42501';
    end if;

    other_user_id := case
        when p_caller_id = v_buyer_id then v_seller_id
        else v_buyer_id
    end;
    listing_id := v_listing_id;
    conversation_kind := v_kind;
    return next;
end;
$$;

comment on function public.carzon_messaging_peer_from_conversation(uuid, uuid) is
    'Resolves listing/support conversation peer for an authenticated participant.';

revoke all on function public.carzon_messaging_peer_from_conversation(uuid, uuid) from public;
revoke all on function public.carzon_messaging_peer_from_conversation(uuid, uuid) from anon;
revoke all on function public.carzon_messaging_peer_from_conversation(uuid, uuid) from authenticated;

-- ---------------------------------------------------------------------------
-- 4 — RPC: block_user
-- ---------------------------------------------------------------------------

create or replace function public.block_user(p_conversation_id uuid)
returns table (
    blocked_user_id uuid,
    created_at      timestamptz
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
    v_created_at    timestamptz;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    select p.other_user_id, p.listing_id, p.conversation_kind
      into v_other_user_id, v_listing_id, v_kind
      from public.carzon_messaging_peer_from_conversation(p_conversation_id, v_uid) p;

    if v_kind = 'support'
        or public.carzon_is_support_user_id(v_other_user_id) then
        raise exception 'not available for support conversations'
            using errcode = '42501';
    end if;

    insert into public.user_blocks as b (
        blocker_user_id,
        blocked_user_id
    ) values (
        v_uid,
        v_other_user_id
    )
    on conflict (blocker_user_id, blocked_user_id) do nothing;

    select b.created_at
      into v_created_at
      from public.user_blocks b
     where b.blocker_user_id = v_uid
       and b.blocked_user_id = v_other_user_id;

    blocked_user_id := v_other_user_id;
    created_at := v_created_at;
    return next;
end;
$$;

comment on function public.block_user(uuid) is
    'Authenticated participant blocks the other listing-conversation peer (derived server-side).';

revoke all on function public.block_user(uuid) from public;
revoke all on function public.block_user(uuid) from anon;
grant execute on function public.block_user(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5 — RPC: unblock_user
-- ---------------------------------------------------------------------------

create or replace function public.unblock_user(p_blocked_user_id uuid)
returns boolean
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

    if p_blocked_user_id is null or p_blocked_user_id = v_uid then
        raise exception 'invalid blocked user'
            using errcode = '22023';
    end if;

    delete from public.user_blocks b
     where b.blocker_user_id = v_uid
       and b.blocked_user_id = p_blocked_user_id;

    return found;
end;
$$;

comment on function public.unblock_user(uuid) is
    'Removes a block created by auth.uid(); idempotent when row absent.';

revoke all on function public.unblock_user(uuid) from public;
revoke all on function public.unblock_user(uuid) from anon;
grant execute on function public.unblock_user(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 6 — RPC: list_blocked_users
-- ---------------------------------------------------------------------------

create or replace function public.list_blocked_users()
returns table (
    blocked_user_id uuid,
    created_at      timestamptz,
    display_name    text,
    avatar_url      text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    return query
    select
        b.blocked_user_id,
        b.created_at,
        sp.display_name,
        sp.avatar_url
      from public.user_blocks b
      left join public.seller_profiles sp
             on sp.user_id = b.blocked_user_id
     where b.blocker_user_id = auth.uid()
     order by b.created_at desc;
end;
$$;

comment on function public.list_blocked_users() is
    'Lists users blocked by auth.uid() with optional public seller display fields only.';

revoke all on function public.list_blocked_users() from public;
revoke all on function public.list_blocked_users() from anon;
grant execute on function public.list_blocked_users() to authenticated;

-- ---------------------------------------------------------------------------
-- 7 — RPC: report_user
-- ---------------------------------------------------------------------------

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
        reason,
        note,
        status
    ) values (
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
    'Stores a listing-conversation user report; reported peer derived server-side.';

revoke all on function public.report_user(uuid, text, text) from public;
revoke all on function public.report_user(uuid, text, text) from anon;
grant execute on function public.report_user(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 8 — Gate: get_or_create_conversation (listing threads only)
-- ---------------------------------------------------------------------------

create or replace function public.get_or_create_conversation(
    p_listing_id uuid
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid          uuid := auth.uid();
    v_seller_id    uuid;
    v_status       text;
    v_conv_id      uuid;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    select l.seller_id, l.status
      into v_seller_id, v_status
      from public.listings l
     where l.id = p_listing_id;

    if not found then
        raise exception 'listing not found'
            using errcode = '22023';
    end if;

    if v_seller_id is null then
        raise exception 'chat is not available for this listing'
            using errcode = '22023';
    end if;

    if v_seller_id = v_uid then
        raise exception 'cannot start a conversation on your own listing'
            using errcode = '42501';
    end if;

    if v_status is distinct from 'active' then
        raise exception 'listing is not active'
            using errcode = '22023';
    end if;

    if public.carzon_users_are_blocked(v_uid, v_seller_id) then
        raise exception 'messaging blocked'
            using errcode = '42501';
    end if;

    select c.id
      into v_conv_id
      from public.conversations c
     where c.listing_id = p_listing_id
       and c.buyer_id = v_uid
       and c.conversation_kind = 'listing';

    if v_conv_id is not null then
        return v_conv_id;
    end if;

    begin
        insert into public.conversations (
            conversation_kind,
            listing_id,
            buyer_id,
            seller_id
        ) values (
            'listing',
            p_listing_id,
            v_uid,
            v_seller_id
        )
        returning id into v_conv_id;

        return v_conv_id;
    exception
        when unique_violation then
            select c.id
              into v_conv_id
              from public.conversations c
             where c.listing_id = p_listing_id
               and c.buyer_id = v_uid
               and c.conversation_kind = 'listing';
            if v_conv_id is null then
                raise;
            end if;
            return v_conv_id;
    end;
end;
$$;

-- ---------------------------------------------------------------------------
-- 9 — Gate: send_message
-- ---------------------------------------------------------------------------

create or replace function public.send_message(
    p_conversation_id uuid,
    p_body            text
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid         uuid := auth.uid();
    v_body        text := trim(both from coalesce(p_body, ''));
    v_message_id  uuid;
    v_buyer_id    uuid;
    v_seller_id   uuid;
    v_kind        text;
    v_other_id    uuid;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if v_body = '' then
        raise exception 'message body is required'
            using errcode = '22023';
    end if;

    if char_length(v_body) > 4000 then
        raise exception 'message body is too long'
            using errcode = '22023';
    end if;

    select c.buyer_id, c.seller_id, c.conversation_kind
      into v_buyer_id, v_seller_id, v_kind
      from public.conversations c
     where c.id = p_conversation_id;

    if not found then
        raise exception 'conversation not found'
            using errcode = '22023';
    end if;

    if v_uid <> v_buyer_id and v_uid <> v_seller_id then
        raise exception 'not a participant in this conversation'
            using errcode = '42501';
    end if;

    if v_kind is distinct from 'support' then
        v_other_id := case
            when v_uid = v_buyer_id then v_seller_id
            else v_buyer_id
        end;

        if public.carzon_users_are_blocked(v_uid, v_other_id) then
            raise exception 'messaging blocked'
                using errcode = '42501';
        end if;
    end if;

    insert into public.messages (
        conversation_id,
        sender_id,
        body
    ) values (
        p_conversation_id,
        v_uid,
        v_body
    )
    returning id into v_message_id;

    return v_message_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 10 — Gate: send_message_with_attachment
-- ---------------------------------------------------------------------------

create or replace function public.send_message_with_attachment(
    p_conversation_id uuid,
    p_storage_path    text,
    p_mime_type       text,
    p_size_bytes      bigint,
    p_body            text default null,
    p_width           integer default null,
    p_height          integer default null
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid          uuid := auth.uid();
    v_body         text := nullif(trim(both from coalesce(p_body, '')), '');
    v_path         text := trim(both from coalesce(p_storage_path, ''));
    v_mime         text := lower(trim(both from coalesce(p_mime_type, '')));
    v_message_id   uuid;
    v_buyer_id     uuid;
    v_seller_id    uuid;
    v_kind         text;
    v_other_id     uuid;
    v_conv_prefix  text;
    v_max_bytes    constant bigint := 10485760;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_size_bytes is null then
        raise exception 'attachment size is required'
            using errcode = '22023';
    end if;

    if p_size_bytes <= 0 then
        raise exception 'attachment size must be positive'
            using errcode = '22023';
    end if;

    if p_size_bytes > v_max_bytes then
        raise exception 'attachment size exceeds limit'
            using errcode = '22023';
    end if;

    if v_path = '' then
        raise exception 'storage path is required'
            using errcode = '22023';
    end if;

    if position('..' in v_path) > 0 then
        raise exception 'invalid storage path'
            using errcode = '22023';
    end if;

    v_conv_prefix := 'conversations/' || p_conversation_id::text || '/';
    if v_path not like v_conv_prefix || '%' then
        raise exception 'storage path must be under conversations/<conversation_id>/'
            using errcode = '22023';
    end if;

    if split_part(v_path, '/', 1) <> 'conversations'
        or split_part(v_path, '/', 2) <> p_conversation_id::text
        or split_part(v_path, '/', 3) <> v_uid::text
        or split_part(v_path, '/', 4) = '' then
        raise exception 'storage path must be conversations/<conversation_id>/<uploader_uid>/<filename>'
            using errcode = '22023';
    end if;

    if v_mime not in ('image/jpeg', 'image/png') then
        raise exception 'unsupported attachment mime type'
            using errcode = '22023';
    end if;

    if v_body is not null and char_length(v_body) > 4000 then
        raise exception 'message body is too long'
            using errcode = '22023';
    end if;

    select c.buyer_id, c.seller_id, c.conversation_kind
      into v_buyer_id, v_seller_id, v_kind
      from public.conversations c
     where c.id = p_conversation_id;

    if not found then
        raise exception 'conversation not found'
            using errcode = '22023';
    end if;

    if v_uid <> v_buyer_id and v_uid <> v_seller_id then
        raise exception 'not a participant in this conversation'
            using errcode = '42501';
    end if;

    if v_kind is distinct from 'support' then
        v_other_id := case
            when v_uid = v_buyer_id then v_seller_id
            else v_buyer_id
        end;

        if public.carzon_users_are_blocked(v_uid, v_other_id) then
            raise exception 'messaging blocked'
                using errcode = '42501';
        end if;
    end if;

    insert into public.messages (
        conversation_id,
        sender_id,
        body
    ) values (
        p_conversation_id,
        v_uid,
        v_body
    )
    returning id into v_message_id;

    insert into public.message_attachments (
        message_id,
        conversation_id,
        storage_bucket,
        storage_path,
        mime_type,
        size_bytes,
        width,
        height
    ) values (
        v_message_id,
        p_conversation_id,
        'chat-attachments',
        v_path,
        v_mime,
        p_size_bytes,
        p_width,
        p_height
    );

    return v_message_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 11 — Gate: enqueue_message_notification_event
-- ---------------------------------------------------------------------------

create or replace function public.enqueue_message_notification_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_buyer_id     uuid;
    v_seller_id    uuid;
    v_listing_id   uuid;
    v_kind         text;
    v_recipient_id uuid;
    v_payload      jsonb;
begin
    if new.sender_id is null then
        return new;
    end if;

    select c.buyer_id, c.seller_id, c.listing_id, c.conversation_kind
      into v_buyer_id, v_seller_id, v_listing_id, v_kind
      from public.conversations c
     where c.id = new.conversation_id;

    if not found then
        return new;
    end if;

    if new.sender_id = v_buyer_id then
        v_recipient_id := v_seller_id;
    elsif new.sender_id = v_seller_id then
        v_recipient_id := v_buyer_id;
    else
        return new;
    end if;

    if v_recipient_id is null or v_recipient_id = new.sender_id then
        return new;
    end if;

    if v_kind is distinct from 'support'
        and public.carzon_users_are_blocked(new.sender_id, v_recipient_id) then
        return new;
    end if;

    v_payload := jsonb_build_object(
        'conversation_id', new.conversation_id,
        'message_id', new.id,
        'listing_id', v_listing_id,
        'actor_user_id', new.sender_id
    );

    insert into public.notification_delivery_events (
        event_type,
        recipient_user_id,
        actor_user_id,
        conversation_id,
        message_id,
        listing_id,
        payload,
        status
    ) values (
        'message_created',
        v_recipient_id,
        new.sender_id,
        new.conversation_id,
        new.id,
        v_listing_id,
        v_payload,
        'pending'
    )
    on conflict (event_type, recipient_user_id, message_id)
        where message_id is not null
    do nothing;

    return new;
end;
$$;
