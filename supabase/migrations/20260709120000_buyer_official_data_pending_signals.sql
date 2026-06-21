-- Carzon — buyer-safe pending signals for VIN / Model Passport / Recall.
--
-- Problem: buyer RPCs returned empty while async workers were still preparing data,
-- so listing details looked like "no data" instead of "pending".
--
-- Fix: when cache/snapshot is pending/processing and no displayable buyer row exists yet,
-- return a safe status row (empty normalized_summary, no VIN/hash/private fields).

------------------------------------------------------------------------------
-- 1 — VIN buyer report: pending signal from listing_vin_report_snapshot
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
        )

    union all

    select
        'nhtsa_vpic'::text as source_id,
        null::text as region,
        null::text as access_mode,
        s.processing_status as status,
        'public_summary'::text as visibility,
        null::text as confidence,
        '{}'::jsonb as normalized_summary,
        '{}'::text[] as limitation_codes,
        false as requires_user_consent,
        null::text as consent_required_reason,
        'NHTSA vPIC'::text as source_label,
        null::text as provider_version,
        null::timestamptz as fetched_at,
        null::timestamptz as ttl_until,
        s.updated_at
      from public.listing_vin_report_snapshot s
      join public.listings li on li.id = s.listing_id
     where s.listing_id = p_listing_id
       and li.status = 'active'
       and li.vin_status = 'format_valid'
       and s.processing_status in ('pending', 'processing')
       and not exists (
            select 1
              from public.listing_vin_source_results r2
             where r2.listing_id = p_listing_id
               and r2.visibility = 'public_summary'
               and r2.normalized_summary <> '{}'::jsonb
        );
end;
$$;

comment on function public.get_listing_vin_report_for_buyer(uuid) is
    'Buyer-safe: returns sanitized public_summary source rows for an active listing, '
    'plus a pending status row while listing_vin_report_snapshot is pending/processing '
    'and no displayable public_summary exists yet. Never returns VIN, vin_hash, or source_metadata.';

revoke all on function public.get_listing_vin_report_for_buyer(uuid) from public;
grant execute on function public.get_listing_vin_report_for_buyer(uuid)
    to anon, authenticated;

------------------------------------------------------------------------------
-- 2 — Model Passport buyer RPC: pending signal from vehicle_model_source_cache
------------------------------------------------------------------------------

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
        )

    union all

    select
        c.source_id,
        c.status,
        c.confidence,
        '{}'::jsonb as normalized_summary,
        public.carzon_model_data_default_limitation_codes() as limitation_codes,
        c.match_quality,
        coalesce(
            nullif(btrim(c.source_label), ''),
            'EPA · FuelEconomy.gov'
        ) as source_label,
        nullif(btrim(c.provider_version), '') as provider_version,
        c.fetched_at,
        c.ttl_until,
        c.updated_at
      from public.vehicle_model_source_cache c
     where c.source_id = 'epa_fueleconomy'
       and c.status in ('pending', 'processing')
       and exists (
            select 1
              from public.carzon_model_data_resolve_identity(
                  v_listing.make,
                  v_listing.model,
                  v_listing.year
              ) r
             where r.valid
               and r.cache_key = c.cache_key
        )
       and not exists (
            select 1
              from public.vehicle_model_source_cache c2
             where c2.source_id = 'epa_fueleconomy'
               and c2.cache_key = c.cache_key
               and c2.status in ('succeeded', 'partial')
               and (c2.ttl_until is null or c2.ttl_until > now())
               and c2.normalized_summary <> '{}'::jsonb
        );
end;
$$;

comment on function public.get_listing_model_data_for_buyer(uuid) is
    'Buyer-safe Model Passport rows for active listings. Returns succeeded/partial cache rows '
    'with allowlisted normalized_summary, or a pending status row while cache is pending/processing. '
    'Never returns source_metadata, cache_key, job identifiers, or VIN fields.';

revoke all on function public.get_listing_model_data_for_buyer(uuid) from public;
grant execute on function public.get_listing_model_data_for_buyer(uuid)
    to anon, authenticated;

------------------------------------------------------------------------------
-- 3 — Recall buyer RPC: pending signal from vehicle_recall_source_cache
------------------------------------------------------------------------------

create or replace function public.get_listing_recalls_for_buyer(p_listing_id uuid)
returns table (
    source_id text,
    status text,
    normalized_summary jsonb,
    limitation_codes text[],
    match_quality text,
    source_label text,
    fetched_at timestamptz,
    source_updated_at timestamptz,
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
begin
    select li.make, li.model, li.year
      into v_listing
      from public.listings li
     where li.id = p_listing_id
       and li.status = 'active';

    if not found then
        return;
    end if;

    perform public.enqueue_vehicle_recall_fetch_if_needed(
        v_listing.make,
        v_listing.model,
        v_listing.year,
        'nhtsa_recalls'
    );

    return query
    select
        c.source_id,
        c.status,
        buyer_summary.normalized_summary,
        case
            when coalesce(array_length(c.limitation_codes, 1), 0) >= 1
                then c.limitation_codes
            else public.carzon_recall_data_default_limitation_codes()
        end as limitation_codes,
        c.match_quality,
        coalesce(nullif(btrim(c.source_label), ''), 'NHTSA') as source_label,
        c.fetched_at,
        c.source_updated_at,
        c.ttl_until,
        c.updated_at
      from public.vehicle_recall_source_cache c
      cross join lateral (
          select jsonb_strip_nulls(
              jsonb_build_object(
                  'campaigns',
                  coalesce(
                      (
                          select jsonb_agg(campaign_row.campaign_obj order by campaign_row.ord)
                            from (
                                select
                                    elem.ordinality as ord,
                                    jsonb_strip_nulls(
                                        jsonb_build_object(
                                            'campaign_number',
                                            nullif(btrim(elem.campaign->>'campaign_number'), ''),
                                            'manufacturer',
                                            nullif(btrim(elem.campaign->>'manufacturer'), ''),
                                            'component',
                                            nullif(btrim(elem.campaign->>'component'), ''),
                                            'summary',
                                            nullif(btrim(elem.campaign->>'summary'), ''),
                                            'consequence',
                                            nullif(btrim(elem.campaign->>'consequence'), ''),
                                            'remedy',
                                            nullif(btrim(elem.campaign->>'remedy'), ''),
                                            'notes',
                                            nullif(btrim(elem.campaign->>'notes'), ''),
                                            'report_received_date',
                                            nullif(btrim(elem.campaign->>'report_received_date'), ''),
                                            'nhtsa_action_number',
                                            nullif(btrim(elem.campaign->>'nhtsa_action_number'), ''),
                                            'park_it',
                                            elem.campaign->'park_it',
                                            'park_outside',
                                            elem.campaign->'park_outside',
                                            'over_the_air_update',
                                            elem.campaign->'over_the_air_update',
                                            'model_year',
                                            elem.campaign->'model_year',
                                            'make',
                                            nullif(btrim(elem.campaign->>'make'), ''),
                                            'model',
                                            nullif(btrim(elem.campaign->>'model'), '')
                                        )
                                    ) as campaign_obj
                                  from jsonb_array_elements(
                                      coalesce(c.normalized_summary->'campaigns', '[]'::jsonb)
                                  ) with ordinality as elem(campaign, ordinality)
                            ) campaign_row
                           where campaign_row.campaign_obj <> '{}'::jsonb
                      ),
                      '[]'::jsonb
                  ),
                  'campaign_count',
                  coalesce(
                      nullif(c.normalized_summary->>'campaign_count', '')::integer,
                      jsonb_array_length(coalesce(c.normalized_summary->'campaigns', '[]'::jsonb))
                  ),
                  'market',
                  coalesce(
                      nullif(btrim(c.normalized_summary->>'market'), ''),
                      'US'
                  ),
                  'match_quality',
                  nullif(btrim(coalesce(c.match_quality, c.normalized_summary->>'match_quality')), '')
              )
          ) as normalized_summary
      ) buyer_summary
     where c.source_id = 'nhtsa_recalls'
       and c.status in ('succeeded', 'partial')
       and (c.ttl_until is null or c.ttl_until > now())
       and jsonb_array_length(
           coalesce(buyer_summary.normalized_summary->'campaigns', '[]'::jsonb)
       ) >= 1
       and exists (
            select 1
              from public.carzon_recall_data_resolve_identity(
                  v_listing.make,
                  v_listing.model,
                  v_listing.year,
                  'nhtsa_recalls'
              ) r
             where r.valid
               and r.cache_key = c.cache_key
        )

    union all

    select
        c.source_id,
        c.status,
        '{}'::jsonb as normalized_summary,
        public.carzon_recall_data_default_limitation_codes() as limitation_codes,
        c.match_quality,
        coalesce(nullif(btrim(c.source_label), ''), 'NHTSA') as source_label,
        c.fetched_at,
        c.source_updated_at,
        c.ttl_until,
        c.updated_at
      from public.vehicle_recall_source_cache c
     where c.source_id = 'nhtsa_recalls'
       and c.status in ('pending', 'processing')
       and exists (
            select 1
              from public.carzon_recall_data_resolve_identity(
                  v_listing.make,
                  v_listing.model,
                  v_listing.year,
                  'nhtsa_recalls'
              ) r
             where r.valid
               and r.cache_key = c.cache_key
        )
       and not exists (
            select 1
              from public.vehicle_recall_source_cache c2
             where c2.source_id = 'nhtsa_recalls'
               and c2.cache_key = c.cache_key
               and c2.status in ('succeeded', 'partial')
               and (c2.ttl_until is null or c2.ttl_until > now())
               and jsonb_array_length(
                   coalesce(c2.normalized_summary->'campaigns', '[]'::jsonb)
               ) >= 1
        );
end;
$$;

comment on function public.get_listing_recalls_for_buyer(uuid) is
    'Buyer-safe model-level recall campaigns for active listings. Returns succeeded/partial '
    'cache rows with allowlisted campaigns, or a pending status row while cache is pending/processing. '
    'Never returns source_metadata, cache_key, job identifiers, or VIN fields.';

revoke all on function public.get_listing_recalls_for_buyer(uuid) from public;
grant execute on function public.get_listing_recalls_for_buyer(uuid)
    to anon, authenticated;

notify pgrst, 'reload schema';
