-- Carzon — listing-independent support conversations (minimal MVP).
--
-- Adds conversation_kind ('listing' | 'support'). Support threads have
-- listing_id NULL and seller_id = the server-resolved support account.
-- Listing threads are unchanged.

-- ---------------------------------------------------------------------------
-- SCHEMA
-- ---------------------------------------------------------------------------

alter table public.conversations
    add column if not exists conversation_kind text not null default 'listing';

alter table public.conversations
    alter column listing_id drop not null;

alter table public.conversations
    drop constraint if exists conversations_listing_buyer_uniq;

alter table public.conversations
    drop constraint if exists conversations_kind_valid_chk;

alter table public.conversations
    add constraint conversations_kind_valid_chk
        check (conversation_kind in ('listing', 'support'));

alter table public.conversations
    drop constraint if exists conversations_kind_shape_chk;

alter table public.conversations
    add constraint conversations_kind_shape_chk
        check (
            (conversation_kind = 'listing' and listing_id is not null)
            or (conversation_kind = 'support' and listing_id is null)
        );

create unique index if not exists conversations_listing_buyer_uniq
    on public.conversations (listing_id, buyer_id)
    where conversation_kind = 'listing' and listing_id is not null;

create unique index if not exists conversations_support_buyer_uniq
    on public.conversations (buyer_id)
    where conversation_kind = 'support';

comment on column public.conversations.conversation_kind is
    'listing = buyer–seller thread per listing; support = user ↔ Carzon support.';

-- ---------------------------------------------------------------------------
-- RPC: get_or_create_support_conversation() -> uuid
-- ---------------------------------------------------------------------------

create or replace function public.get_or_create_support_conversation()
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid          uuid := auth.uid();
    v_support_id   uuid;
    v_conv_id      uuid;
    v_support_email constant text := 'admin@carzon.com';
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    select u.id
      into v_support_id
      from auth.users u
     where lower(u.email) = lower(v_support_email)
     limit 1;

    if v_support_id is null then
        raise exception 'support account is not configured'
            using errcode = '22023';
    end if;

    if v_uid = v_support_id then
        raise exception 'cannot open a support conversation as the support account'
            using errcode = '42501';
    end if;

    select c.id
      into v_conv_id
      from public.conversations c
     where c.conversation_kind = 'support'
       and c.buyer_id = v_uid
       and c.seller_id = v_support_id;

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
            'support',
            null,
            v_uid,
            v_support_id
        )
        returning id into v_conv_id;

        return v_conv_id;
    exception
        when unique_violation then
            select c.id
              into v_conv_id
              from public.conversations c
             where c.conversation_kind = 'support'
               and c.buyer_id = v_uid
               and c.seller_id = v_support_id;
            if v_conv_id is null then
                raise;
            end if;
            return v_conv_id;
    end;
end;
$$;

revoke all on function public.get_or_create_support_conversation() from public;
revoke all on function public.get_or_create_support_conversation() from anon;
grant execute on function public.get_or_create_support_conversation() to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: list_inbox_conversations() — include support rows (LEFT JOIN listings)
-- ---------------------------------------------------------------------------

drop function if exists public.list_inbox_conversations();

create function public.list_inbox_conversations()
returns table (
    id uuid,
    listing_id uuid,
    buyer_id uuid,
    seller_id uuid,
    conversation_kind text,
    created_at timestamptz,
    updated_at timestamptz,
    last_message_at timestamptz,
    last_message_preview text,
    listings jsonb,
    has_unread boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    return query
    select
        c.id,
        c.listing_id,
        c.buyer_id,
        c.seller_id,
        c.conversation_kind,
        c.created_at,
        c.updated_at,
        c.last_message_at,
        c.last_message_preview,
        case
            when c.listing_id is not null then
                jsonb_strip_nulls(
                    jsonb_build_object(
                        'id', l.id,
                        'title', l.title,
                        'make', l.make,
                        'model', l.model,
                        'city', l.city,
                        'cover_image_url', l.cover_image_url,
                        'price_eur', l.price_eur,
                        'price_currency', l.price_currency
                    )
                )
            else null
        end as listings,
        exists (
            select 1
              from public.messages m
             where m.conversation_id = c.id
               and m.sender_id is distinct from auth.uid()
               and m.created_at > coalesce(
                       ucs.last_read_at,
                       '-infinity'::timestamptz
                   )
        ) as has_unread
      from public.conversations c
      left join public.listings l
             on l.id = c.listing_id
      left join public.user_conversation_state ucs
             on ucs.conversation_id = c.id
            and ucs.user_id = auth.uid()
     where c.buyer_id = auth.uid()
        or c.seller_id = auth.uid()
     order by c.updated_at desc;
end;
$$;

revoke all on function public.list_inbox_conversations() from public;
revoke all on function public.list_inbox_conversations() from anon;
grant execute on function public.list_inbox_conversations() to authenticated;
