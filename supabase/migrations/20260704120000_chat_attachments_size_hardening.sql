-- Carzon — chat attachment size/MIME hardening (10 MiB MVP cap).
--
-- Max attachment size: 10485760 bytes (10 * 1024 * 1024).
-- Allowed MIME: image/jpeg, image/png.

-- ---------------------------------------------------------------------------
-- 1 — Storage bucket limits
-- ---------------------------------------------------------------------------

update storage.buckets
   set file_size_limit = 10485760,
       allowed_mime_types = array['image/jpeg', 'image/png']::text[]
 where id = 'chat-attachments';

-- ---------------------------------------------------------------------------
-- 2 — message_attachments.size_bytes NOT NULL + upper bound
-- ---------------------------------------------------------------------------

alter table public.message_attachments
    drop constraint if exists message_attachments_size_bytes_chk;

alter table public.message_attachments
    alter column size_bytes set not null;

alter table public.message_attachments
    add constraint message_attachments_size_bytes_chk
        check (size_bytes > 0 and size_bytes <= 10485760);

comment on column public.message_attachments.size_bytes is
    'Attachment byte size (required). Max 10485760 (10 MiB).';

-- ---------------------------------------------------------------------------
-- 3 — send_message_with_attachment: require size + enforce 10 MiB cap
-- ---------------------------------------------------------------------------

drop function if exists public.send_message_with_attachment(
    uuid, text, text, text, bigint, integer, integer
);

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
    uuid, text, text, bigint, text, integer, integer
) from public;
revoke all on function public.send_message_with_attachment(
    uuid, text, text, bigint, text, integer, integer
) from anon;
grant execute on function public.send_message_with_attachment(
    uuid, text, text, bigint, text, integer, integer
) to authenticated;
