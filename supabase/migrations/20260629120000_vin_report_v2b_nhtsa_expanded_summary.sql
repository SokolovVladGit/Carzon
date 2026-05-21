-- Carzon — VIN Report v2 Phase B: expanded NHTSA normalized_summary for buyer/owner RPCs.
--
-- * Extends complete_vin_decode_job_success NHTSA branch with additional catalog fields
--   in listing_vin_source_results.normalized_summary (snake_case keys).
-- * Does not store raw NHTSA payloads, full VIN, vin_hash, provider URLs, or error codes in summary.
-- * No new table grants; service_role-only RPC unchanged.

------------------------------------------------------------------------------
-- 1 — complete_vin_decode_job_success (NHTSA visibility → public_summary)
------------------------------------------------------------------------------

create or replace function public.complete_vin_decode_job_success(
    p_job_id uuid,
    p_vin_hash text,
    p_provider_id text default 'carzon_fake_vin_decoder',
    p_provider_version text default 'phase2b-test',
    p_normalized_data jsonb default '{}'::jsonb,
    p_source_metadata jsonb default '{}'::jsonb,
    p_decoded_make text default null,
    p_decoded_model text default null,
    p_decoded_year integer default null,
    p_decoded_body_type text default null,
    p_decoded_fuel_type text default null,
    p_field_comparisons jsonb default '[]'::jsonb,
    p_summary jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_listing_id uuid;
    v_snap_rows integer;
    v_fetched timestamptz := now();
    v_ttl timestamptz := now() + interval '30 days';
    v_has_useful boolean;
    v_src_status text;
    v_summary jsonb;
    v_engine text;
    v_transmission text;
    v_meta jsonb;
    v_limits text[] := array[
        'basic_decode_only',
        'not_md_pmr_official_verification',
        'not_accident_history',
        'not_ownership_check',
        'not_insurance_check',
        'not_mileage_check',
        'not_registration_check'
    ]::text[];
begin
    if p_job_id is null or p_vin_hash is null then
        raise exception 'complete_vin_decode_job_success: job_id and vin_hash required'
            using errcode = '23502';
    end if;

    if jsonb_typeof(p_normalized_data) <> 'object'
        or jsonb_typeof(p_source_metadata) <> 'object'
        or jsonb_typeof(p_field_comparisons) <> 'array'
        or jsonb_typeof(p_summary) <> 'object'
    then
        raise exception 'complete_vin_decode_job_success: invalid jsonb shapes'
            using errcode = '23514';
    end if;

    if p_decoded_year is not null
        and (p_decoded_year < 1900 or p_decoded_year > 2100)
    then
        raise exception 'complete_vin_decode_job_success: decoded_year out of range'
            using errcode = '23514';
    end if;

    select j.listing_id
      into strict v_listing_id
      from public.vin_processing_jobs j
     where j.id = p_job_id
       and j.status = 'processing'
       and j.vin_hash = p_vin_hash
     for update;

    insert into public.vin_decode_cache (
        vin_hash,
        schema_version,
        decode_status,
        provider_id,
        provider_version,
        normalized_data,
        source_metadata,
        fetched_at,
        ttl_until,
        last_error,
        created_at,
        updated_at
    )
    values (
        p_vin_hash,
        1,
        'decoded',
        p_provider_id,
        p_provider_version,
        p_normalized_data,
        p_source_metadata,
        v_fetched,
        v_ttl,
        null,
        v_fetched,
        v_fetched
    )
    on conflict (vin_hash) do update
        set schema_version = excluded.schema_version,
            decode_status = 'decoded',
            provider_id = excluded.provider_id,
            provider_version = excluded.provider_version,
            normalized_data = excluded.normalized_data,
            source_metadata = excluded.source_metadata,
            fetched_at = excluded.fetched_at,
            ttl_until = excluded.ttl_until,
            last_error = null,
            updated_at = v_fetched;

    update public.listing_vin_report_snapshot s
       set processing_status = 'succeeded',
           decode_status = 'decoded',
           verification_status = 'not_attempted',
           mismatch_status = 'not_checked',
           decoded_make = p_decoded_make,
           decoded_model = p_decoded_model,
           decoded_year = p_decoded_year,
           decoded_body_type = p_decoded_body_type,
           decoded_fuel_type = p_decoded_fuel_type,
           field_comparisons = p_field_comparisons,
           summary = p_summary,
           last_processed_at = v_fetched,
           last_error = null,
           updated_at = v_fetched
     where s.listing_id = v_listing_id
       and s.vin_hash = p_vin_hash;

    get diagnostics v_snap_rows = row_count;
    if v_snap_rows = 0 then
        raise exception 'complete_vin_decode_job_success: snapshot row missing for listing'
            using errcode = 'P0002';
    end if;

    if p_provider_id = 'nhtsa_vpic' then
        v_engine := nullif(btrim(p_normalized_data->>'engine'), '');
        v_transmission := nullif(btrim(p_normalized_data->>'transmission'), '');

        v_has_useful := (
            (p_decoded_make is not null and btrim(p_decoded_make) <> '')
            or (p_decoded_model is not null and btrim(p_decoded_model) <> '')
            or p_decoded_year is not null
            or (p_decoded_body_type is not null and btrim(p_decoded_body_type) <> '')
            or (p_decoded_fuel_type is not null and btrim(p_decoded_fuel_type) <> '')
            or v_engine is not null
            or v_transmission is not null
            or nullif(btrim(p_normalized_data->>'manufacturer'), '') is not null
            or nullif(btrim(p_normalized_data->>'vehicleType'), '') is not null
            or nullif(btrim(p_normalized_data->>'trim'), '') is not null
            or nullif(btrim(p_normalized_data->>'driveType'), '') is not null
            or nullif(btrim(p_normalized_data->>'plantCountry'), '') is not null
        );

        v_src_status := case when v_has_useful then 'succeeded' else 'partial' end;

        v_summary := jsonb_strip_nulls(
            jsonb_build_object(
                'make', nullif(btrim(p_decoded_make), ''),
                'model', nullif(btrim(p_decoded_model), ''),
                'year', p_decoded_year,
                'body_type', nullif(btrim(p_decoded_body_type), ''),
                'fuel_type', nullif(btrim(p_decoded_fuel_type), ''),
                'engine', v_engine,
                'transmission', v_transmission,
                'trim', nullif(btrim(p_normalized_data->>'trim'), ''),
                'series', nullif(btrim(p_normalized_data->>'series'), ''),
                'vehicle_type', nullif(btrim(p_normalized_data->>'vehicleType'), ''),
                'drive_type', nullif(btrim(p_normalized_data->>'driveType'), ''),
                'doors', nullif(btrim(p_normalized_data->>'doors'), ''),
                'displacement', nullif(btrim(p_normalized_data->>'displacement'), ''),
                'cylinders', nullif(btrim(p_normalized_data->>'cylinders'), ''),
                'manufacturer', nullif(btrim(p_normalized_data->>'manufacturer'), ''),
                'plant_country', nullif(btrim(p_normalized_data->>'plantCountry'), ''),
                'plant_city', nullif(btrim(p_normalized_data->>'plantCity'), ''),
                'plant_company', nullif(btrim(p_normalized_data->>'plantCompany'), ''),
                'gross_vehicle_weight_rating', nullif(
                    btrim(p_normalized_data->>'grossVehicleWeightRating'),
                    ''
                ),
                'catalog_decode_caution',
                case
                    when p_normalized_data->'warnings' @> '["nhtsa_catalog_decode_caution"]'::jsonb
                        then true
                    else null
                end
            )
        );

        v_meta := jsonb_strip_nulls(
            jsonb_build_object(
                'provider_id', p_provider_id,
                'provider_version', p_provider_version,
                'source_label', 'NHTSA vPIC',
                'latency_ms', p_source_metadata->'latencyMs',
                'warning_codes', p_normalized_data->'warnings'
            )
        );

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
        values (
            v_listing_id,
            'nhtsa_vpic',
            'international',
            'carzon_partner_api',
            v_src_status,
            'public_summary',
            'basic_decode',
            v_summary,
            v_meta,
            v_limits,
            false,
            null,
            v_fetched,
            v_ttl,
            v_fetched,
            v_fetched
        )
        on conflict (listing_id, source_id) do update
            set region = excluded.region,
                access_mode = excluded.access_mode,
                status = excluded.status,
                visibility = excluded.visibility,
                confidence = excluded.confidence,
                normalized_summary = excluded.normalized_summary,
                source_metadata = excluded.source_metadata,
                limitation_codes = excluded.limitation_codes,
                requires_user_consent = excluded.requires_user_consent,
                consent_required_reason = excluded.consent_required_reason,
                fetched_at = excluded.fetched_at,
                ttl_until = excluded.ttl_until,
                updated_at = v_fetched;
    end if;

    update public.vin_processing_jobs j
       set status = 'succeeded',
           locked_at = null,
           locked_by = null,
           last_error = null,
           updated_at = v_fetched
     where j.id = p_job_id;
end;
$$;

comment on function public.complete_vin_decode_job_success(
    uuid,
    text,
    text,
    text,
    jsonb,
    jsonb,
    text,
    text,
    integer,
    text,
    text,
    jsonb,
    jsonb
) is
    'Worker-only: updates decode cache, listing snapshot, and for NHTSA vPIC upserts '
    'listing_vin_source_results with expanded basic_decode normalized_summary (public_summary). '
    'Does not store VIN, vin_hash, raw provider bodies, or decode error codes in summary.';

------------------------------------------------------------------------------
-- 2 — Privileges unchanged (service_role only; re-assert after replace)
------------------------------------------------------------------------------

revoke all on function public.complete_vin_decode_job_success(
    uuid,
    text,
    text,
    text,
    jsonb,
    jsonb,
    text,
    text,
    integer,
    text,
    text,
    jsonb,
    jsonb
) from public;
revoke all on function public.complete_vin_decode_job_success(
    uuid,
    text,
    text,
    text,
    jsonb,
    jsonb,
    text,
    text,
    integer,
    text,
    text,
    jsonb,
    jsonb
) from anon;
revoke all on function public.complete_vin_decode_job_success(
    uuid,
    text,
    text,
    text,
    jsonb,
    jsonb,
    text,
    text,
    integer,
    text,
    text,
    jsonb,
    jsonb
) from authenticated;
grant execute on function public.complete_vin_decode_job_success(
    uuid,
    text,
    text,
    text,
    jsonb,
    jsonb,
    text,
    text,
    integer,
    text,
    text,
    jsonb,
    jsonb
) to service_role;
