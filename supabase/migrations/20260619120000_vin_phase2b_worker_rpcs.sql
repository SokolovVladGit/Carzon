-- Carzon — VIN Phase 2B: service-role worker RPCs for decode job claim/complete.
--
-- * Invoked by Edge `process-vin-decode-jobs` with service_role only.
-- * No anon/authenticated EXECUTE; no listings.vin_status changes.

------------------------------------------------------------------------------
-- 1 — Claim pending decode jobs (SKIP LOCKED)
------------------------------------------------------------------------------

create or replace function public.claim_vin_decode_jobs_for_processing(
    p_limit integer default 10,
    p_worker_id text default null
)
returns table (
    job_id uuid,
    listing_id uuid,
    owner_id uuid,
    vin_hash text,
    idempotency_key text,
    attempts integer,
    max_attempts integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_lim integer;
begin
    v_lim := greatest(1, least(coalesce(p_limit, 10), 50));

    return query
    with picked as (
        select j.id
          from public.vin_processing_jobs j
         where j.job_type = 'decode'
           and j.status = 'pending'
           and j.next_run_at <= now()
           and j.attempts < j.max_attempts
         order by j.next_run_at asc, j.created_at asc
         limit v_lim
           for update skip locked
    ),
    upd as (
        update public.vin_processing_jobs j
           set status = 'processing',
               locked_at = now(),
               locked_by = p_worker_id,
               attempts = j.attempts + 1,
               updated_at = now()
          from picked p
         where j.id = p.id
        returning
            j.id,
            j.listing_id,
            j.owner_id,
            j.vin_hash,
            j.idempotency_key,
            j.attempts,
            j.max_attempts
    )
    select
        u.id,
        u.listing_id,
        u.owner_id,
        u.vin_hash,
        u.idempotency_key,
        u.attempts,
        u.max_attempts
      from upd u;
end;
$$;

------------------------------------------------------------------------------
-- 2 — Complete job successfully (cache + snapshot + job)
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
        now(),
        now() + interval '30 days',
        null,
        now(),
        now()
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
            updated_at = now();

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
           last_processed_at = now(),
           last_error = null,
           updated_at = now()
     where s.listing_id = v_listing_id
       and s.vin_hash = p_vin_hash;

    get diagnostics v_snap_rows = row_count;
    if v_snap_rows = 0 then
        raise exception 'complete_vin_decode_job_success: snapshot row missing for listing'
            using errcode = 'P0002';
    end if;

    update public.vin_processing_jobs j
       set status = 'succeeded',
           locked_at = null,
           locked_by = null,
           last_error = null,
           updated_at = now()
     where j.id = p_job_id;
end;
$$;

------------------------------------------------------------------------------
-- 3 — Complete job with failure (retry with backoff or terminal failed)
------------------------------------------------------------------------------

create or replace function public.complete_vin_decode_job_failure(
    p_job_id uuid,
    p_error_message text,
    p_retryable boolean default true
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_job record;
    v_err text;
    v_delay interval;
    v_exp integer;
begin
    if p_job_id is null then
        raise exception 'complete_vin_decode_job_failure: job_id required'
            using errcode = '23502';
    end if;

    v_err := left(
        trim(
            regexp_replace(
                coalesce(p_error_message, ''),
                '[[:cntrl:]]',
                ' ',
                'g'
            )
        ),
        500
    );

    select
        j.id,
        j.listing_id,
        j.attempts,
        j.max_attempts
      into strict v_job
      from public.vin_processing_jobs j
     where j.id = p_job_id
       and j.status = 'processing'
     for update;

    v_exp := least(greatest(v_job.attempts, 1), 14);
    v_delay := least(
        interval '1 hour',
        (power(2::numeric, v_exp))::bigint * interval '1 second'
    );

    if p_retryable and v_job.attempts < v_job.max_attempts then
        update public.vin_processing_jobs j
           set status = 'pending',
               next_run_at = now() + v_delay,
               last_error = nullif(v_err, ''),
               locked_at = null,
               locked_by = null,
               updated_at = now()
         where j.id = p_job_id;
    else
        update public.vin_processing_jobs j
           set status = 'failed',
               last_error = nullif(v_err, ''),
               locked_at = null,
               locked_by = null,
               updated_at = now()
         where j.id = p_job_id;

        update public.listing_vin_report_snapshot s
           set processing_status = 'failed',
               decode_status = 'failed',
               last_error = nullif(v_err, ''),
               last_processed_at = now(),
               updated_at = now()
         where s.listing_id = v_job.listing_id;
    end if;
end;
$$;

------------------------------------------------------------------------------
-- 4 — Privileges: service_role only
------------------------------------------------------------------------------

revoke all on function public.claim_vin_decode_jobs_for_processing(integer, text)
    from public;
revoke all on function public.claim_vin_decode_jobs_for_processing(integer, text)
    from anon;
revoke all on function public.claim_vin_decode_jobs_for_processing(integer, text)
    from authenticated;
grant execute on function public.claim_vin_decode_jobs_for_processing(integer, text)
    to service_role;

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

revoke all on function public.complete_vin_decode_job_failure(uuid, text, boolean)
    from public;
revoke all on function public.complete_vin_decode_job_failure(uuid, text, boolean)
    from anon;
revoke all on function public.complete_vin_decode_job_failure(uuid, text, boolean)
    from authenticated;
grant execute on function public.complete_vin_decode_job_failure(uuid, text, boolean)
    to service_role;
