-- Carzon — VIN Phase 2H: owner-safe read RPC for listing_vin_source_results.
--
-- * Returns sanitized projection only (no source_metadata json, no VIN, no vin_hash).
-- * Rows with visibility = internal are excluded.
-- * Same ownership semantics as get_my_listing_vin_report_status.

------------------------------------------------------------------------------
-- 1 — get_my_listing_vin_source_results (authenticated, owner-only)
------------------------------------------------------------------------------

create or replace function public.get_my_listing_vin_source_results(p_listing_id uuid)
returns table (
    source_id text,
    region text,
    access_mode text,
    status text,
    visibility text,
    confidence text,
    normalized_summary jsonb,
    limitation_codes text[],
    requires_user_consent boolean,
    consent_required_reason text,
    source_label text,
    provider_version text,
    fetched_at timestamptz,
    ttl_until timestamptz,
    updated_at timestamptz
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
        r.source_id,
        r.region,
        r.access_mode,
        r.status,
        r.visibility,
        r.confidence,
        r.normalized_summary,
        r.limitation_codes,
        r.requires_user_consent,
        r.consent_required_reason,
        case r.source_id
            when 'nhtsa_vpic' then 'NHTSA vPIC'
            else null::text
        end as source_label,
        case
            when r.source_id = 'nhtsa_vpic' then
                nullif(btrim(r.source_metadata->>'provider_version'), '')
            else null::text
        end as provider_version,
        r.fetched_at,
        r.ttl_until,
        r.updated_at
      from public.listing_vin_source_results r
     where r.listing_id = p_listing_id
       and r.visibility in ('owner', 'public_summary');
end;
$$;

comment on function public.get_my_listing_vin_source_results(uuid) is
    'Owner-only: returns sanitized source-result rows for a listing; excludes '
    'internal visibility and never returns raw source_metadata, VIN, or vin_hash.';

revoke all on function public.get_my_listing_vin_source_results(uuid) from public;
revoke all on function public.get_my_listing_vin_source_results(uuid) from anon;
grant execute on function public.get_my_listing_vin_source_results(uuid)
    to authenticated;
