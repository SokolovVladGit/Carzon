-- Carzon — inbox RPC: participant conversations + per-row unread flag.
--
-- [has_unread] matches the semantics of get_unread_conversation_count (inbound
-- messages after coalesce(last_read_at, '-infinity')) for the invoking user.
--
-- SECURITY: SECURITY DEFINER runs as owner; access is bounded by auth.uid() and
-- an explicit buyer/seller participant predicate. Listing JSON is built from an
-- allowlist of non-sensitive card fields only (no seller_id, status, contact).

create or replace function public.list_inbox_conversations()
returns table (
    id uuid,
    listing_id uuid,
    buyer_id uuid,
    seller_id uuid,
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
        c.created_at,
        c.updated_at,
        c.last_message_at,
        c.last_message_preview,
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
        ) as listings,
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
      join public.listings l
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
