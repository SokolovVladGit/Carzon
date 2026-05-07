-- Carzon — Phase 1A: buyer–seller messaging foundation (schema + RLS + RPCs).
--
-- Scope: text-only threads; one conversation per (listing_id, buyer_id).
-- Mutations are RPC-only; clients use get_or_create_conversation and send_message.
--
-- Future (not in this migration):
--   * Realtime subscriptions on public.messages / public.conversations
--   * Unread / read receipts (optional columns or participant state)
--   * Attachments: add public.message_attachments + a private Storage bucket;
--     do NOT reuse the public listing-images bucket for chat media.
--   * Moderation / block / report

-- ---------------------------------------------------------------------------
-- TABLES
-- ---------------------------------------------------------------------------

create table if not exists public.conversations (
    id                  uuid primary key default gen_random_uuid(),
    listing_id          uuid        not null references public.listings(id) on delete cascade,
    buyer_id            uuid        not null references auth.users(id) on delete cascade,
    seller_id           uuid        not null references auth.users(id) on delete cascade,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    last_message_at     timestamptz,
    last_message_preview text,

    constraint conversations_buyer_not_seller_chk
        check (buyer_id <> seller_id),
    constraint conversations_listing_buyer_uniq
        unique (listing_id, buyer_id)
);

create table if not exists public.messages (
    id               uuid primary key default gen_random_uuid(),
    conversation_id  uuid        not null references public.conversations(id) on delete cascade,
    sender_id        uuid        not null references auth.users(id) on delete cascade,
    body             text        not null,
    created_at       timestamptz not null default now(),

    constraint messages_body_nonempty_chk check (
        char_length(trim(both from body)) > 0
        and char_length(body) <= 4000
    )
);

comment on table public.conversations is
    'Buyer–seller thread per listing; participants are buyer_id and seller_id.';
comment on table public.messages is
    'In-app chat text rows; attachment metadata will live in a future message_attachments table.';

create index if not exists conversations_buyer_updated_at_idx
    on public.conversations (buyer_id, updated_at desc);

create index if not exists conversations_seller_updated_at_idx
    on public.conversations (seller_id, updated_at desc);

create index if not exists conversations_listing_id_idx
    on public.conversations (listing_id);

create index if not exists messages_conversation_created_at_idx
    on public.messages (conversation_id, created_at desc);

create index if not exists messages_sender_created_at_idx
    on public.messages (sender_id, created_at desc);

-- ---------------------------------------------------------------------------
-- TRIGGER: keep conversation timestamps + preview in sync after each message
-- ---------------------------------------------------------------------------

create or replace function public.touch_conversation_from_message()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    update public.conversations
       set updated_at = now(),
           last_message_at = new.created_at,
           last_message_preview = left(new.body, 200)
     where id = new.conversation_id;
    return new;
end;
$$;

drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation
    after insert on public.messages
    for each row
    execute function public.touch_conversation_from_message();

revoke all on function public.touch_conversation_from_message() from public;
revoke all on function public.touch_conversation_from_message() from anon;
grant execute on function public.touch_conversation_from_message() to authenticated;

-- ---------------------------------------------------------------------------
-- RLS: participant-only reads; no direct client writes
-- ---------------------------------------------------------------------------

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

drop policy if exists "conversations_participant_select" on public.conversations;
create policy "conversations_participant_select"
    on public.conversations
    for select
    to authenticated
    using (
        auth.uid() = buyer_id
        or auth.uid() = seller_id
    );

drop policy if exists "messages_participant_select" on public.messages;
create policy "messages_participant_select"
    on public.messages
    for select
    to authenticated
    using (
        exists (
            select 1
              from public.conversations c
             where c.id = messages.conversation_id
               and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
        )
    );

-- Intentionally no INSERT / UPDATE / DELETE policies on these tables.
-- Writes go only through SECURITY DEFINER RPCs below.

-- ---------------------------------------------------------------------------
-- RPC: get_or_create_conversation(p_listing_id uuid) -> uuid
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

    select c.id
      into v_conv_id
      from public.conversations c
     where c.listing_id = p_listing_id
       and c.buyer_id = v_uid;

    if v_conv_id is not null then
        return v_conv_id;
    end if;

    begin
        insert into public.conversations (
            listing_id,
            buyer_id,
            seller_id
        ) values (
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
               and c.buyer_id = v_uid;
            if v_conv_id is null then
                raise;
            end if;
            return v_conv_id;
    end;
end;
$$;

revoke all on function public.get_or_create_conversation(uuid) from public;
revoke all on function public.get_or_create_conversation(uuid) from anon;
grant execute on function public.get_or_create_conversation(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: send_message(p_conversation_id uuid, p_body text) -> uuid
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

    select c.buyer_id, c.seller_id
      into v_buyer_id, v_seller_id
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

revoke all on function public.send_message(uuid, text) from public;
revoke all on function public.send_message(uuid, text) from anon;
grant execute on function public.send_message(uuid, text) to authenticated;
