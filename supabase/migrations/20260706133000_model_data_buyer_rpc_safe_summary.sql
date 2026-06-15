-- Model Passport hardening: buyer RPC projects allowlisted normalized_summary keys only.
--
-- Defense-in-depth before real EPA rollout. Top-level return signature unchanged;
-- vehicle_model_source_cache may still store the full normalized_summary for workers.

create or replace function public.get_listing_model_data_for_buyer(p_listing_id uuid)
returns table (
    source_id text,
    status text,
    confidence text,
    normalized_summary jsonb,
    limitation_codes text[],
    match_quality text,
    source_label text,
    provider_version text,
    fetched_at timestamptz,
    ttl_until timestamptz,
    updated_at timestamptz
)
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
    v_listing record;
    v_enqueue text;
begin
    select li.make, li.model, li.year
      into v_listing
      from public.listings li
     where li.id = p_listing_id
       and li.status = 'active';

    if not found then
        return;
    end if;

    v_enqueue := public.enqueue_vehicle_model_fetch_if_needed(
        v_listing.make,
        v_listing.model,
        v_listing.year,
        'epa_fueleconomy'
    );
    perform v_enqueue;

    return query
    select
        c.source_id,
        c.status,
        c.confidence,
        buyer_summary.normalized_summary,
        case
            when coalesce(array_length(c.limitation_codes, 1), 0) >= 1
                then c.limitation_codes
            else public.carzon_model_data_default_limitation_codes()
        end as limitation_codes,
        c.match_quality,
        coalesce(
            nullif(btrim(c.source_label), ''),
            case c.source_id
                when 'epa_fueleconomy' then 'EPA · FuelEconomy.gov'
                else null::text
            end
        ) as source_label,
        nullif(btrim(c.provider_version), '') as provider_version,
        c.fetched_at,
        c.ttl_until,
        c.updated_at
      from public.vehicle_model_source_cache c
      cross join lateral (
          select jsonb_strip_nulls(
              jsonb_build_object(
                  'fuel_type',
                  nullif(btrim(c.normalized_summary->>'fuel_type'), ''),
                  'city_l_per_100km',
                  c.normalized_summary->'city_l_per_100km',
                  'highway_l_per_100km',
                  c.normalized_summary->'highway_l_per_100km',
                  'combined_l_per_100km',
                  c.normalized_summary->'combined_l_per_100km',
                  'co2_g_per_km',
                  c.normalized_summary->'co2_g_per_km',
                  'vehicle_class',
                  nullif(btrim(c.normalized_summary->>'vehicle_class'), ''),
                  'market',
                  nullif(btrim(c.normalized_summary->>'market'), ''),
                  'match_quality',
                  nullif(btrim(c.normalized_summary->>'match_quality'), '')
              )
          ) as normalized_summary
      ) buyer_summary
     where c.source_id = 'epa_fueleconomy'
       and c.status in ('succeeded', 'partial')
       and (c.ttl_until is null or c.ttl_until > now())
       and buyer_summary.normalized_summary <> '{}'::jsonb
       and exists (
            select 1
              from public.carzon_model_data_resolve_identity(
                  v_listing.make,
                  v_listing.model,
                  v_listing.year
              ) r
             where r.valid
               and r.cache_key = c.cache_key
        );
end;
$$;

comment on function public.get_listing_model_data_for_buyer(uuid) is
    'Buyer-safe Model Passport rows for active listings. Reads listing make/model/year only; '
    'never reads listing_vehicle_identity or VIN tables. Projects allowlisted normalized_summary '
    'keys only (fuel economy, CO₂, vehicle_class, market). Does not return source_metadata, '
    'cache_key, job identifiers, MPG, transmission, drive, engine, or provider_vehicle_id. '
    'Enqueues background fetch idempotently on miss/stale.';

revoke all on function public.get_listing_model_data_for_buyer(uuid) from public;
grant execute on function public.get_listing_model_data_for_buyer(uuid)
    to anon, authenticated;

notify pgrst, 'reload schema';
