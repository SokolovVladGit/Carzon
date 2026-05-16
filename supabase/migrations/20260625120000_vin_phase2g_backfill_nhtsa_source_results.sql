-- Carzon — VIN Phase 2G: one-time backfill of listing_vin_source_results for historical NHTSA decodes.
--
-- * Runs only internal SELECT/INSERT; no external HTTP, no re-decode, no new RPCs or grants.
-- * Builds rows from listing_vin_report_snapshot + vin_decode_cache (provider_id = nhtsa_vpic).
-- * Never inserts full VIN, vin_hash, verbatim provider bodies, URLs, or credentials into source results.
-- * ON CONFLICT DO NOTHING: never overwrites an existing nhtsa_vpic row (e.g. from Phase 2F).

------------------------------------------------------------------------------
-- 1 — Backfill nhtsa_vpic source rows from snapshot + cache
------------------------------------------------------------------------------

insert into public.listing_vin_source_results (
    listing_id,
    source_id,
    region,
    access_mode,
    status,
    visibility,
    confidence,
    normalized_summary,
    source_metadata,
    limitation_codes,
    requires_user_consent,
    consent_required_reason,
    fetched_at,
    ttl_until,
    created_at,
    updated_at
)
select
    s.listing_id,
    'nhtsa_vpic',
    'international',
    'carzon_partner_api',
    'succeeded',
    'owner',
    'basic_decode',
    jsonb_strip_nulls(
        jsonb_build_object(
            'make', nullif(btrim(s.decoded_make), ''),
            'model', nullif(btrim(s.decoded_model), ''),
            'year', s.decoded_year,
            'body_type', nullif(
                btrim(
                    coalesce(
                        s.decoded_body_type,
                        c.normalized_data->>'bodyType'
                    )
                ),
                ''
            ),
            'fuel_type', nullif(
                btrim(
                    coalesce(
                        s.decoded_fuel_type,
                        c.normalized_data->>'fuelType'
                    )
                ),
                ''
            ),
            'engine', nullif(btrim(c.normalized_data->>'engine'), ''),
            'transmission', nullif(btrim(c.normalized_data->>'transmission'), '')
        )
    ),
    jsonb_strip_nulls(
        jsonb_build_object(
            'provider_id', 'nhtsa_vpic',
            'provider_version', coalesce(
                nullif(btrim(c.provider_version), ''),
                'decode-vin-values-v1'
            ),
            'source_label', 'NHTSA vPIC',
            'backfilled', true,
            'backfilled_at', now(),
            'warning_codes', c.normalized_data->'warnings'
        )
    ),
    array[
        'basic_decode_only',
        'not_md_pmr_official_verification',
        'not_accident_history',
        'not_ownership_check',
        'not_insurance_check',
        'not_mileage_check',
        'not_registration_check'
    ]::text[],
    false,
    null,
    coalesce(c.fetched_at, s.last_processed_at, s.updated_at, now()),
    c.ttl_until,
    now(),
    now()
  from public.listing_vin_report_snapshot s
 inner join public.vin_decode_cache c
         on c.vin_hash = s.vin_hash
 where s.processing_status = 'succeeded'
   and s.decode_status = 'decoded'
   and c.decode_status = 'decoded'
   and c.provider_id = 'nhtsa_vpic'
   and (
        (s.decoded_make is not null and btrim(s.decoded_make) <> '')
     or (s.decoded_model is not null and btrim(s.decoded_model) <> '')
     or s.decoded_year is not null
     or (s.decoded_body_type is not null and btrim(s.decoded_body_type) <> '')
     or (s.decoded_fuel_type is not null and btrim(s.decoded_fuel_type) <> '')
     or (nullif(btrim(c.normalized_data->>'bodyType'), '') is not null)
     or (nullif(btrim(c.normalized_data->>'fuelType'), '') is not null)
     or (nullif(btrim(c.normalized_data->>'engine'), '') is not null)
     or (nullif(btrim(c.normalized_data->>'transmission'), '') is not null)
   )
on conflict (listing_id, source_id) do nothing;
