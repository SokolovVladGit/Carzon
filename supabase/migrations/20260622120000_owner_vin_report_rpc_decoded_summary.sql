-- Carzon — extend owner-only `get_my_listing_vin_report_status` with sanitized
-- decoded summary columns from `listing_vin_report_snapshot`.
-- Does not return full VIN, private identity hash column, owner_id, raw payloads, or job IDs.

drop function if exists public.get_my_listing_vin_report_status(uuid);

create function public.get_my_listing_vin_report_status(p_listing_id uuid)
returns table (
    listing_id uuid,
    vin_status text,
    processing_status text,
    decode_status text,
    verification_status text,
    mismatch_status text,
    last_requested_at timestamptz,
    last_processed_at timestamptz,
    last_error text,
    decoded_make text,
    decoded_model text,
    decoded_year integer,
    decoded_body_type text,
    decoded_fuel_type text,
    report_updated_at timestamptz
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

    if not exists (
        select 1
          from public.listings li
         where li.id = p_listing_id
           and li.seller_id = auth.uid()
    ) then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    return query
    select
        l.id,
        l.vin_status,
        s.processing_status,
        s.decode_status,
        s.verification_status,
        s.mismatch_status,
        s.last_requested_at,
        s.last_processed_at,
        null::text as last_error,
        s.decoded_make,
        s.decoded_model,
        s.decoded_year,
        s.decoded_body_type,
        s.decoded_fuel_type,
        s.updated_at
      from public.listings l
      left join public.listing_vin_report_snapshot s
             on s.listing_id = l.id
     where l.id = p_listing_id;
end;
$$;

revoke all on function public.get_my_listing_vin_report_status(uuid) from public;
revoke all on function public.get_my_listing_vin_report_status(uuid) from anon;
grant execute on function public.get_my_listing_vin_report_status(uuid)
    to authenticated;
