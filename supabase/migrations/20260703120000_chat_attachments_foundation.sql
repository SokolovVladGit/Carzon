-- Carzon — private chat image attachments (schema + Storage + RPC foundation).
--
-- Scope: backend only. One image per message (jpeg/png). Image-only messages allowed.
-- Does NOT reuse public listing-images / seller-avatars buckets.
--
-- Upload path convention (Storage + RPC validated):
--   conversations/<conversation_id>/<uploader_uid>/<filename>
-- Segment 3 MUST equal auth.uid() so INSERT/DELETE policies can enforce uploader scope
-- without brittle message_id-in-path parsing before the message row exists.
--
-- Client flow (future):
--   1) Upload bytes to chat-attachments bucket at the path above.
--   2) Call send_message_with_attachment(...) to create message + attachment metadata.

-- ---------------------------------------------------------------------------
-- 1 — Relax messages.body for image-only attachment messages
-- ---------------------------------------------------------------------------

alter table public.messages
    alter column body drop not null;

alter table public.messages
    drop constraint if exists messages_body_nonempty_chk;

alter table public.messages
    add constraint messages_body_length_chk
        check (
            body is null
            or (
                char_length(trim(both from body)) > 0
                and char_length(body) <= 4000
            )
        );

comment on column public.messages.body is
    'Optional caption text. NULL for image-only attachment messages (see message_attachments).';

-- ---------------------------------------------------------------------------
-- 2 — message_attachments
-- ---------------------------------------------------------------------------

create table if not exists public.message_attachments (
    id               uuid primary key default gen_random_uuid(),
    message_id       uuid        not null references public.messages (id) on delete cascade,
    conversation_id  uuid        not null references public.conversations (id) on delete cascade,
    storage_bucket   text        not null,
    storage_path     text        not null,
    mime_type        text        not null,
    size_bytes       bigint,
    width            integer,
    height           integer,
    created_at       timestamptz not null default now(),

    constraint message_attachments_message_id_uniq unique (message_id),
    constraint message_attachments_storage_bucket_chk
        check (storage_bucket = 'chat-attachments'),
    constraint message_attachments_mime_type_chk
        check (mime_type in ('image/jpeg', 'image/png')),
    constraint message_attachments_size_bytes_chk
        check (size_bytes is null or size_bytes > 0),
    constraint message_attachments_storage_path_shape_chk
        check (
            storage_path ~ '^conversations/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[^/]+$'
            and position('..' in storage_path) = 0
        )
);

create index if not exists message_attachments_conversation_id_idx
    on public.message_attachments (conversation_id);

comment on table public.message_attachments is
    'Private chat image attachment metadata. One row per message (MVP). Writes via RPC only.';

-- conversation_id must match parent message (CHECK cannot reference other tables).
create or replace function public.validate_message_attachment_conversation()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
    if not exists (
        select 1
          from public.messages m
         where m.id = new.message_id
           and m.conversation_id = new.conversation_id
    ) then
        raise exception 'attachment conversation_id must match message conversation'
            using errcode = '22023';
    end if;
    return new;
end;
$$;

drop trigger if exists message_attachments_validate_conversation
    on public.message_attachments;
create trigger message_attachments_validate_conversation
    before insert or update of message_id, conversation_id
    on public.message_attachments
    for each row
    execute function public.validate_message_attachment_conversation();

-- ---------------------------------------------------------------------------
-- 3 — RLS: message_attachments (participant SELECT only; no client writes)
-- ---------------------------------------------------------------------------

alter table public.message_attachments enable row level security;

drop policy if exists "message_attachments_participant_select"
    on public.message_attachments;
create policy "message_attachments_participant_select"
    on public.message_attachments
    for select
    to authenticated
    using (
        exists (
            select 1
              from public.conversations c
             where c.id = message_attachments.conversation_id
               and (
                   c.buyer_id = auth.uid()
                   or c.seller_id = auth.uid()
               )
        )
    );

revoke insert, update, delete on public.message_attachments from anon;
revoke insert, update, delete on public.message_attachments from authenticated;
revoke insert, update, delete on public.message_attachments from public;

grant select on table public.message_attachments to authenticated;

-- ---------------------------------------------------------------------------
-- 4 — Private Storage bucket chat-attachments
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('chat-attachments', 'chat-attachments', false)
on conflict (id) do update
    set public = excluded.public;

-- Participant read: conversation_id is path segment 2.
drop policy if exists "chat_attachments_participant_select" on storage.objects;
create policy "chat_attachments_participant_select"
    on storage.objects
    for select
    to authenticated
    using (
        bucket_id = 'chat-attachments'
        and split_part(name, '/', 1) = 'conversations'
        and split_part(name, '/', 2) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        and exists (
            select 1
              from public.conversations c
             where c.id = split_part(name, '/', 2)::uuid
               and (
                   c.buyer_id = auth.uid()
                   or c.seller_id = auth.uid()
               )
        )
    );

-- Upload: participant + uploader folder (segment 3 = auth.uid()).
drop policy if exists "chat_attachments_uploader_insert" on storage.objects;
create policy "chat_attachments_uploader_insert"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'chat-attachments'
        and split_part(name, '/', 1) = 'conversations'
        and split_part(name, '/', 2) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        and split_part(name, '/', 3) = auth.uid()::text
        and split_part(name, '/', 4) <> ''
        and position('..' in name) = 0
        and exists (
            select 1
              from public.conversations c
             where c.id = split_part(name, '/', 2)::uuid
               and (
                   c.buyer_id = auth.uid()
                   or c.seller_id = auth.uid()
               )
        )
    );

-- Best-effort orphan cleanup by uploader before send_message_with_attachment commits.
drop policy if exists "chat_attachments_uploader_delete" on storage.objects;
create policy "chat_attachments_uploader_delete"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'chat-attachments'
        and split_part(name, '/', 1) = 'conversations'
        and split_part(name, '/', 2) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        and split_part(name, '/', 3) = auth.uid()::text
        and position('..' in name) = 0
        and exists (
            select 1
              from public.conversations c
             where c.id = split_part(name, '/', 2)::uuid
               and (
                   c.buyer_id = auth.uid()
                   or c.seller_id = auth.uid()
               )
        )
    );

-- Intentionally no UPDATE policy (replace = delete + insert).

-- ---------------------------------------------------------------------------
-- 5 — Conversation preview trigger (image-only => [photo])
-- ---------------------------------------------------------------------------

create or replace function public.touch_conversation_from_message()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_preview text;
    v_body    text := nullif(trim(both from coalesce(new.body, '')), '');
begin
    if v_body is not null then
        v_preview := left(v_body, 200);
    else
        v_preview := '[photo]';
    end if;

    update public.conversations
       set updated_at = now(),
           last_message_at = new.created_at,
           last_message_preview = v_preview
     where id = new.conversation_id;
    return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6 — RPC: send_message_with_attachment
-- ---------------------------------------------------------------------------

create or replace function public.send_message_with_attachment(
    p_conversation_id uuid,
    p_storage_path    text,
    p_mime_type       text,
    p_body            text default null,
    p_size_bytes      bigint default null,
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
    v_conv_prefix  text;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
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

    if p_size_bytes is not null and p_size_bytes <= 0 then
        raise exception 'attachment size must be positive'
            using errcode = '22023';
    end if;

    if v_body is not null and char_length(v_body) > 4000 then
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

revoke all on function public.send_message_with_attachment(
    uuid, text, text, text, bigint, integer, integer
) from public;
revoke all on function public.send_message_with_attachment(
    uuid, text, text, text, bigint, integer, integer
) from anon;
grant execute on function public.send_message_with_attachment(
    uuid, text, text, text, bigint, integer, integer
) to authenticated;

-- Existing text-only RPC unchanged (body still required).
-- send_message(uuid, text) remains granted via prior migrations.
