-- Carzon — Phase 3A: message notification delivery (DB queue + enqueue trigger only).
--
-- • Inserts rows into public.notification_delivery_events when a chat message is created.
-- • No FCM / HTTP from Postgres; a Supabase Edge Function (service_role) claims and sends.
-- • Filter-alert notifications are out of scope.
-- • Payload is minimal (ids only; never message body or email).

------------------------------------------------------------------------------
-- 1 — notification_delivery_events
------------------------------------------------------------------------------

create table if not exists public.notification_delivery_events (
    id                   uuid primary key default gen_random_uuid(),
    event_type           text        not null,
    recipient_user_id    uuid        not null references auth.users (id) on delete cascade,
    actor_user_id        uuid        null references auth.users (id) on delete set null,
    conversation_id      uuid        null references public.conversations (id) on delete cascade,
    message_id           uuid        null references public.messages (id) on delete cascade,
    listing_id           uuid        null references public.listings (id) on delete set null,
    payload              jsonb       not null default '{}'::jsonb,
    status               text        not null default 'pending',
    attempts             integer     not null default 0,
    next_attempt_at      timestamptz not null default now(),
    last_error           text        null,
    locked_at            timestamptz null,
    processed_at         timestamptz null,
    created_at           timestamptz not null default now(),
    updated_at           timestamptz not null default now(),

    constraint notification_delivery_events_event_type_chk check (
        event_type in ('message_created')
    ),
    constraint notification_delivery_events_status_chk check (
        status in ('pending', 'processing', 'sent', 'skipped', 'failed')
    ),
    constraint notification_delivery_events_attempts_nonneg_chk check (attempts >= 0)
);

comment on table public.notification_delivery_events is
    'Internal Phase 3A queue: outbound notification work (message notifications). '
    'Not exposed to PostgREST clients (no Data API grants to anon/authenticated).';

create index if not exists notification_delivery_events_status_next_created_idx
    on public.notification_delivery_events (status, next_attempt_at asc, created_at asc);

create index if not exists notification_delivery_events_recipient_idx
    on public.notification_delivery_events (recipient_user_id);

-- Dedup: one queued row per recipient + inbound message.
create unique index if not exists notification_delivery_events_message_dedup_idx
    on public.notification_delivery_events (event_type, recipient_user_id, message_id)
    where message_id is not null;

------------------------------------------------------------------------------
-- 2 — notification_delivery_attempts
------------------------------------------------------------------------------

create table if not exists public.notification_delivery_attempts (
    id                 uuid primary key default gen_random_uuid(),
    event_id           uuid        not null references public.notification_delivery_events (id) on delete cascade,
    recipient_user_id  uuid        not null references auth.users (id) on delete cascade,
    token_id           uuid        null references public.user_push_tokens (id) on delete set null,
    provider           text        not null default 'fcm',
    status             text        not null,
    provider_message_id text       null,
    error_code         text        null,
    error_message      text        null,
    created_at         timestamptz not null default now(),

    constraint notification_delivery_attempts_provider_chk check (provider = 'fcm'),
    constraint notification_delivery_attempts_status_chk check (
        status in ('success', 'failed', 'skipped')
    )
);

comment on table public.notification_delivery_attempts is
    'Internal per-token FCM attempt log; service_role / Edge only.';

create index if not exists notification_delivery_attempts_event_idx
    on public.notification_delivery_attempts (event_id);

create index if not exists notification_delivery_attempts_recipient_idx
    on public.notification_delivery_attempts (recipient_user_id);

------------------------------------------------------------------------------
-- 3 — updated_at on events
------------------------------------------------------------------------------

create or replace function public.touch_notification_delivery_events_updated_at()
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

drop trigger if exists notification_delivery_events_touch_updated_at
    on public.notification_delivery_events;
create trigger notification_delivery_events_touch_updated_at
    before update on public.notification_delivery_events
    for each row
    execute function public.touch_notification_delivery_events_updated_at();

------------------------------------------------------------------------------
-- 4 — Enqueue after message INSERT (no network; no message body in payload)
------------------------------------------------------------------------------

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
    v_recipient_id uuid;
    v_payload      jsonb;
begin
    if new.sender_id is null then
        return new;
    end if;

    select c.buyer_id, c.seller_id, c.listing_id
      into v_buyer_id, v_seller_id, v_listing_id
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

drop trigger if exists messages_enqueue_message_notification on public.messages;
create trigger messages_enqueue_message_notification
    after insert on public.messages
    for each row
    execute function public.enqueue_message_notification_event();

revoke all on function public.enqueue_message_notification_event() from public;
revoke all on function public.enqueue_message_notification_event() from anon;
revoke all on function public.enqueue_message_notification_event() from authenticated;

------------------------------------------------------------------------------
-- 5 — Claim batch (Edge / service_role only; SKIP LOCKED)
------------------------------------------------------------------------------

create or replace function public.claim_notification_events_for_processing(
    p_limit integer
)
returns setof public.notification_delivery_events
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_limit integer := coalesce(p_limit, 10);
begin
    if v_limit < 1 or v_limit > 100 then
        v_limit := 10;
    end if;

    return query
    with claimed as (
        update public.notification_delivery_events e
           set status = 'processing',
               locked_at = now(),
               attempts = e.attempts + 1,
               updated_at = now()
          from (
              select ne.id
                from public.notification_delivery_events ne
               where ne.status = 'pending'
                 and ne.next_attempt_at <= now()
               order by ne.created_at asc
               for update skip locked
               limit v_limit
          ) sub
         where e.id = sub.id
        returning e.*
    )
    select * from claimed;
end;
$$;

revoke all on function public.claim_notification_events_for_processing(integer) from public;
revoke all on function public.claim_notification_events_for_processing(integer) from anon;
revoke all on function public.claim_notification_events_for_processing(integer) from authenticated;
grant execute on function public.claim_notification_events_for_processing(integer) to service_role;

------------------------------------------------------------------------------
-- 6 — RLS: enabled; no client policies (service_role bypasses RLS)
------------------------------------------------------------------------------

alter table public.notification_delivery_events enable row level security;
alter table public.notification_delivery_attempts enable row level security;

------------------------------------------------------------------------------
-- 7 — Explicit revoke: internal tables are not Data API / Flutter surfaces
------------------------------------------------------------------------------

revoke all on table public.notification_delivery_events from anon;
revoke all on table public.notification_delivery_events from authenticated;
revoke all on table public.notification_delivery_attempts from anon;
revoke all on table public.notification_delivery_attempts from authenticated;
