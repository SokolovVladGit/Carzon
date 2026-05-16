-- Carzon — VIN Phase 2A: internal DB foundation for async decode/report work.
--
-- * No external VIN APIs, Edge Functions, providers, or secrets.
-- * Public listings.vin_status remains format-only (Phase 1); not expanded here.
-- * Private tables + internal enqueue sync + owner status RPC (no vin_hash / full VIN).

------------------------------------------------------------------------------
-- 1 — Queue: future decode/report jobs (service_role / workers only)
------------------------------------------------------------------------------

create table if not exists public.vin_processing_jobs (
    id uuid primary key default gen_random_uuid(),
    listing_id uuid not null references public.listings(id) on delete cascade,
    owner_id uuid not null references auth.users(id) on delete cascade,
    vin_hash text not null,
    job_type text not null default 'decode',
    status text not null default 'pending',
    attempts integer not null default 0,
    max_attempts integer not null default 5,
    next_run_at timestamptz not null default now(),
    locked_at timestamptz,
    locked_by text,
    last_error text,
    idempotency_key text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint vin_processing_jobs_job_type_chk
        check (job_type in ('decode')),
    constraint vin_processing_jobs_status_chk
        check (status in ('pending', 'processing', 'succeeded', 'failed', 'cancelled')),
    constraint vin_processing_jobs_attempts_chk
        check (attempts >= 0),
    constraint vin_processing_jobs_max_attempts_chk
        check (max_attempts > 0),
    constraint vin_processing_jobs_idempotency_key_uni
        unique (idempotency_key)
);

create index if not exists vin_processing_jobs_status_next_run_at_idx
    on public.vin_processing_jobs (status, next_run_at);

create index if not exists vin_processing_jobs_listing_id_idx
    on public.vin_processing_jobs (listing_id);

create index if not exists vin_processing_jobs_owner_id_idx
    on public.vin_processing_jobs (owner_id);

create index if not exists vin_processing_jobs_vin_hash_idx
    on public.vin_processing_jobs (vin_hash);

comment on table public.vin_processing_jobs is
    'Internal VIN decode/report job queue; keyed by idempotency_key; no client access.';

------------------------------------------------------------------------------
-- 2 — Shared decode cache by vin_hash (no plaintext VIN; no raw payloads)
------------------------------------------------------------------------------

create table if not exists public.vin_decode_cache (
    vin_hash text primary key,
    schema_version integer not null default 1,
    decode_status text not null default 'not_requested',
    provider_id text,
    provider_version text,
    normalized_data jsonb not null default '{}'::jsonb,
    source_metadata jsonb not null default '{}'::jsonb,
    fetched_at timestamptz,
    ttl_until timestamptz,
    last_error text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint vin_decode_cache_decode_status_chk
        check (
            decode_status in (
                'not_requested',
                'pending',
                'decoded',
                'failed',
                'stale',
                'provider_unavailable',
                'rate_limited',
                'quota_exceeded'
            )
        ),
    constraint vin_decode_cache_normalized_object_chk
        check (jsonb_typeof(normalized_data) = 'object'),
    constraint vin_decode_cache_source_meta_object_chk
        check (jsonb_typeof(source_metadata) = 'object')
);

comment on table public.vin_decode_cache is
    'Shared normalized decode cache by vin_hash; Populated in later phases; no raw provider payloads here.';

------------------------------------------------------------------------------
-- 3 — Listing-scoped report/progress snapshot (private)
------------------------------------------------------------------------------

create table if not exists public.listing_vin_report_snapshot (
    listing_id uuid primary key references public.listings(id) on delete cascade,
    owner_id uuid not null references auth.users(id) on delete cascade,
    vin_hash text not null,
    schema_version integer not null default 1,
    processing_status text not null default 'pending',
    decode_status text not null default 'not_requested',
    verification_status text not null default 'not_attempted',
    mismatch_status text not null default 'not_checked',
    decoded_make text,
    decoded_model text,
    decoded_year integer,
    decoded_body_type text,
    decoded_fuel_type text,
    field_comparisons jsonb not null default '[]'::jsonb,
    summary jsonb not null default '{}'::jsonb,
    last_requested_at timestamptz,
    last_processed_at timestamptz,
    last_error text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint listing_vin_report_snapshot_processing_chk
        check (
            processing_status in (
                'pending',
                'processing',
                'succeeded',
                'failed',
                'cancelled',
                'stale'
            )
        ),
    constraint listing_vin_report_snapshot_decode_chk
        check (
            decode_status in (
                'not_requested',
                'pending',
                'decoded',
                'failed',
                'stale',
                'provider_unavailable',
                'rate_limited',
                'quota_exceeded'
            )
        ),
    constraint listing_vin_report_snapshot_verification_chk
        check (
            verification_status in (
                'not_attempted',
                'pending',
                'verified',
                'failed',
                'partial',
                'provider_unavailable'
            )
        ),
    constraint listing_vin_report_snapshot_mismatch_chk
        check (
            mismatch_status in ('not_checked', 'match', 'mismatch', 'partial', 'unknown')
        ),
    constraint listing_vin_report_snapshot_field_comp_arr_chk
        check (jsonb_typeof(field_comparisons) = 'array'),
    constraint listing_vin_report_snapshot_summary_obj_chk
        check (jsonb_typeof(summary) = 'object'),
    constraint listing_vin_report_snapshot_year_chk
        check (decoded_year is null or decoded_year between 1900 and 2100)
);

comment on table public.listing_vin_report_snapshot is
    'Listing-scoped normalized report snapshot; private; no full VIN or raw payloads.';

------------------------------------------------------------------------------
-- 4 — updated_at (reuse listings helper — sets NEW.updated_at only)
------------------------------------------------------------------------------

drop trigger if exists vin_processing_jobs_set_updated_at on public.vin_processing_jobs;

create trigger vin_processing_jobs_set_updated_at
    before update on public.vin_processing_jobs
    for each row
    execute function public.set_listings_updated_at();

drop trigger if exists vin_decode_cache_set_updated_at on public.vin_decode_cache;

create trigger vin_decode_cache_set_updated_at
    before update on public.vin_decode_cache
    for each row
    execute function public.set_listings_updated_at();

drop trigger if exists listing_vin_report_snapshot_set_updated_at
    on public.listing_vin_report_snapshot;

create trigger listing_vin_report_snapshot_set_updated_at
    before update on public.listing_vin_report_snapshot
    for each row
    execute function public.set_listings_updated_at();

------------------------------------------------------------------------------
-- 5 — Internal enqueue/sync helper + triggers on listing_vehicle_identity
------------------------------------------------------------------------------

create or replace function public.carzon_enqueue_vin_decode_from_identity(
    p_listing_id uuid,
    p_owner_id uuid,
    p_vin_hash text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_idempotency text;
begin
    if p_listing_id is null or p_owner_id is null or p_vin_hash is null then
        raise exception 'carzon_enqueue_vin_decode_from_identity: listing_id, owner_id, vin_hash required'
            using errcode = '23502';
    end if;

    v_idempotency := p_listing_id::text || ':decode:' || p_vin_hash || ':v1';

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
        p_owner_id,
        p_vin_hash,
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
        p_owner_id,
        p_vin_hash,
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

create or replace function public.carzon_after_listing_vehicle_identity_vin_hash_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if tg_op = 'insert'
        or (tg_op = 'update' and new.vin_hash is distinct from old.vin_hash)
    then
        perform public.carzon_enqueue_vin_decode_from_identity(
            new.listing_id,
            new.owner_id,
            new.vin_hash
        );
    end if;

    return new;
end;
$$;

create or replace function public.carzon_after_listing_vehicle_identity_deleted()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    update public.vin_processing_jobs
       set status = 'cancelled',
           updated_at = now(),
           locked_at = null,
           locked_by = null
     where listing_id = old.listing_id
       and job_type = 'decode'
       and status in ('pending', 'processing');

    delete from public.listing_vin_report_snapshot
     where listing_id = old.listing_id;

    return old;
end;
$$;

drop trigger if exists listing_vehicle_identity_enqueue_vin_processing
    on public.listing_vehicle_identity;

create trigger listing_vehicle_identity_enqueue_vin_processing
    after insert or update of vin_hash on public.listing_vehicle_identity
    for each row
    execute function public.carzon_after_listing_vehicle_identity_vin_hash_change();

drop trigger if exists listing_vehicle_identity_cleanup_vin_processing
    on public.listing_vehicle_identity;

create trigger listing_vehicle_identity_cleanup_vin_processing
    after delete on public.listing_vehicle_identity
    for each row
    execute function public.carzon_after_listing_vehicle_identity_deleted();

------------------------------------------------------------------------------
-- 6 — Backfill snapshots + jobs for existing identities (one-time)
------------------------------------------------------------------------------

do $$
declare
    r record;
begin
    for r in
        select listing_id, owner_id, vin_hash
          from public.listing_vehicle_identity
    loop
        perform public.carzon_enqueue_vin_decode_from_identity(
            r.listing_id,
            r.owner_id,
            r.vin_hash
        );
    end loop;
end $$;

------------------------------------------------------------------------------
-- 7 — RLS + revoke client access on new tables
------------------------------------------------------------------------------

alter table public.vin_processing_jobs enable row level security;
alter table public.vin_decode_cache enable row level security;
alter table public.listing_vin_report_snapshot enable row level security;

revoke all on table public.vin_processing_jobs from public;
revoke all on table public.vin_processing_jobs from anon;
revoke all on table public.vin_processing_jobs from authenticated;

revoke all on table public.vin_decode_cache from public;
revoke all on table public.vin_decode_cache from anon;
revoke all on table public.vin_decode_cache from authenticated;

revoke all on table public.listing_vin_report_snapshot from public;
revoke all on table public.listing_vin_report_snapshot from anon;
revoke all on table public.listing_vin_report_snapshot from authenticated;

------------------------------------------------------------------------------
-- 8 — Owner-safe RPC (future UI); no vin_hash / full VIN / decoded fields
------------------------------------------------------------------------------

create or replace function public.get_my_listing_vin_report_status(p_listing_id uuid)
returns table (
    listing_id uuid,
    vin_status text,
    processing_status text,
    decode_status text,
    verification_status text,
    mismatch_status text,
    last_requested_at timestamptz,
    last_processed_at timestamptz,
    last_error text
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
        null::text as last_error
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

------------------------------------------------------------------------------
-- 9 — Revoke EXECUTE on internal helpers (trigger / backfill only)
------------------------------------------------------------------------------

revoke all on function public.carzon_enqueue_vin_decode_from_identity(uuid, uuid, text)
    from public;
revoke all on function public.carzon_enqueue_vin_decode_from_identity(uuid, uuid, text)
    from anon;
revoke all on function public.carzon_enqueue_vin_decode_from_identity(uuid, uuid, text)
    from authenticated;

revoke all on function public.carzon_after_listing_vehicle_identity_vin_hash_change()
    from public;
revoke all on function public.carzon_after_listing_vehicle_identity_vin_hash_change()
    from anon;
revoke all on function public.carzon_after_listing_vehicle_identity_vin_hash_change()
    from authenticated;

revoke all on function public.carzon_after_listing_vehicle_identity_deleted()
    from public;
revoke all on function public.carzon_after_listing_vehicle_identity_deleted()
    from anon;
revoke all on function public.carzon_after_listing_vehicle_identity_deleted()
    from authenticated;
