-- Carzon — Phase 2C-1/2C-2: service-role VIN retrieval + requeue for provider transitions.
--
-- * No public/listings changes; no vin_status expansion.
-- * Full VIN never returned to anon/authenticated; Edge uses service_role only.

------------------------------------------------------------------------------
-- 1 — Resolve normalized VIN for a claimed decode job (worker only)
------------------------------------------------------------------------------

create or replace function public.get_vin_for_decode_job(p_job_id uuid)
returns table (
    vin_normalized text
)
language sql
security definer
set search_path = public, pg_temp
as $$
    select i.vin_normalized
      from public.vin_processing_jobs j
      inner join public.listing_vehicle_identity i
              on i.listing_id = j.listing_id
             and i.vin_hash = j.vin_hash
     where j.id = p_job_id
       and j.job_type = 'decode'
       and j.status = 'processing';
$$;

------------------------------------------------------------------------------
-- 2 — Requeue decode for an existing listing identity (e.g. fake → real provider)
------------------------------------------------------------------------------

create or replace function public.requeue_vin_decode_job_for_listing(
    p_listing_id uuid,
    p_reason text default 'provider_decode',
    p_job_version text default 'v2'
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_owner_id uuid;
    v_vin_hash text;
    v_idempotency text;
begin
    if p_listing_id is null then
        raise exception 'requeue_vin_decode_job_for_listing: listing_id required'
            using errcode = '23502';
    end if;

    if p_job_version is null or btrim(p_job_version) = '' then
        raise exception 'requeue_vin_decode_job_for_listing: job_version required'
            using errcode = '23502';
    end if;

    select i.owner_id, i.vin_hash
      into strict v_owner_id, v_vin_hash
      from public.listing_vehicle_identity i
     where i.listing_id = p_listing_id;

    v_idempotency := p_listing_id::text || ':decode:' || v_vin_hash || ':' || p_job_version;

    update public.vin_processing_jobs
       set status = 'cancelled',
           updated_at = now(),
           locked_at = null,
           locked_by = null
     where listing_id = p_listing_id
       and job_type = 'decode'
       and idempotency_key is distinct from v_idempotency
       and status in ('pending', 'processing');

    insert into public.listing_vin_report_snapshot (
        listing_id,
        owner_id,
        vin_hash,
        schema_version,
        processing_status,
        decode_status,
        verification_status,
        mismatch_status,
        field_comparisons,
        summary,
        last_requested_at,
        created_at,
        updated_at
    )
    values (
        p_listing_id,
        v_owner_id,
        v_vin_hash,
        1,
        'pending',
        'pending',
        'not_attempted',
        'not_checked',
        '[]'::jsonb,
        '{}'::jsonb,
        now(),
        now(),
        now()
    )
    on conflict (listing_id) do update
        set owner_id = excluded.owner_id,
            vin_hash = excluded.vin_hash,
            schema_version = excluded.schema_version,
            processing_status = 'pending',
            decode_status = 'pending',
            verification_status = 'not_attempted',
            mismatch_status = 'not_checked',
            decoded_make = null,
            decoded_model = null,
            decoded_year = null,
            decoded_body_type = null,
            decoded_fuel_type = null,
            field_comparisons = '[]'::jsonb,
            summary = '{}'::jsonb,
            last_requested_at = now(),
            last_processed_at = null,
            last_error = null,
            updated_at = now();

    insert into public.vin_processing_jobs (
        listing_id,
        owner_id,
        vin_hash,
        job_type,
        status,
        attempts,
        max_attempts,
        next_run_at,
        idempotency_key,
        created_at,
        updated_at
    )
    values (
        p_listing_id,
        v_owner_id,
        v_vin_hash,
        'decode',
        'pending',
        0,
        5,
        now(),
        v_idempotency,
        now(),
        now()
    )
    on conflict (idempotency_key) do update
        set listing_id = excluded.listing_id,
            owner_id = excluded.owner_id,
            vin_hash = excluded.vin_hash,
            updated_at = now(),
            next_run_at = case
                when public.vin_processing_jobs.status = 'processing'
                    then public.vin_processing_jobs.next_run_at
                else now()
            end,
            status = case
                when public.vin_processing_jobs.status = 'processing'
                    then public.vin_processing_jobs.status
                else 'pending'
            end,
            attempts = case
                when public.vin_processing_jobs.status = 'processing'
                    then public.vin_processing_jobs.attempts
                else 0
            end,
            last_error = case
                when public.vin_processing_jobs.status = 'processing'
                    then public.vin_processing_jobs.last_error
                else null
            end,
            locked_at = case
                when public.vin_processing_jobs.status = 'processing'
                    then public.vin_processing_jobs.locked_at
                else null
            end,
            locked_by = case
                when public.vin_processing_jobs.status = 'processing'
                    then public.vin_processing_jobs.locked_by
                else null
            end;
end;
$$;

------------------------------------------------------------------------------
-- 3 — Privileges: service_role only
------------------------------------------------------------------------------

revoke all on function public.get_vin_for_decode_job(uuid) from public;
revoke all on function public.get_vin_for_decode_job(uuid) from anon;
revoke all on function public.get_vin_for_decode_job(uuid) from authenticated;
grant execute on function public.get_vin_for_decode_job(uuid) to service_role;

revoke all on function public.requeue_vin_decode_job_for_listing(uuid, text, text)
    from public;
revoke all on function public.requeue_vin_decode_job_for_listing(uuid, text, text)
    from anon;
revoke all on function public.requeue_vin_decode_job_for_listing(uuid, text, text)
    from authenticated;
grant execute on function public.requeue_vin_decode_job_for_listing(uuid, text, text)
    to service_role;
