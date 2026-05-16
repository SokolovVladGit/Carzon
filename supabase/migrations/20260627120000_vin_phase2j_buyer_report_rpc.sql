-- Carzon — VIN Phase 2J: buyer-facing report scaffold — public-safe source results RPC.
--
-- * Returns only listing_vin_source_results rows with visibility = public_summary.
-- * Requires listing to exist and status = active (public discovery convention).
-- * Sanitized projection only (no source_metadata json column in output, no VIN, no vin_hash).
-- * Does not promote owner-only rows; NHTSA rows remain owner until explicitly public_summary.

------------------------------------------------------------------------------
-- 1 — get_listing_vin_report_for_buyer (anon + authenticated)
------------------------------------------------------------------------------

create or replace function public.get_listing_vin_report_for_buyer(p_listing_id uuid)
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
       and r.visibility = 'public_summary'
       and exists (
            select 1
              from public.listings li
             where li.id = p_listing_id
               and li.status = 'active'
        );
end;
$$;

comment on function public.get_listing_vin_report_for_buyer(uuid) is
    'Buyer-safe: returns sanitized source-result rows visible as public_summary '
    'for an active listing only; never returns raw source_metadata, VIN, or vin_hash.';

revoke all on function public.get_listing_vin_report_for_buyer(uuid) from public;
grant execute on function public.get_listing_vin_report_for_buyer(uuid)
    to anon, authenticated;
