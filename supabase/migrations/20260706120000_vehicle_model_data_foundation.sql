-- Carzon — Model Passport Phase 1: global vehicle model source cache + fetch jobs + RPCs.
--
-- * Separate from VIN decode, listing_vin_source_results, and recall/history.
-- * No plaintext VIN, vin_hash, or listing_vehicle_identity reads in buyer RPC.
-- * anon/authenticated: no direct table access; buyer RPC only.
-- * Worker RPCs: service_role only.
-- * Phase 1: schema + fake worker path only; no real EPA HTTP in Edge yet.

------------------------------------------------------------------------------
-- Extensions (sha256 cache_key; idempotent if already enabled)
------------------------------------------------------------------------------

create extension if not exists pgcrypto with schema extensions;

------------------------------------------------------------------------------
-- 1 — Normalization helpers (deterministic; no fuzzy match)
------------------------------------------------------------------------------

create or replace function public.carzon_model_data_fold_whitespace(p_raw text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select nullif(
    regexp_replace(btrim(coalesce(p_raw, '')), '\s+', ' ', 'g'),
    ''
  );
$$;

create or replace function public.carzon_model_data_normalize_make_key(p_raw text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select nullif(
    replace(
      replace(
        replace(
          lower(regexp_replace(btrim(coalesce(p_raw, '')), '\s+', '', 'g')),
          '-', ''
        ),
        '–', ''
      ),
      '&', ''
    ),
    ''
  );
$$;

create or replace function public.carzon_model_data_normalize_model_key(p_raw text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select nullif(
    regexp_replace(
      regexp_replace(
        lower(btrim(coalesce(p_raw, ''))),
        '\s+', ' ', 'g'
      ),
      '[.,;:]+$',
      '',
      'g'
    ),
    ''
  );
$$;

create or replace function public.carzon_model_data_apply_make_alias_key(p_make_key text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case p_make_key
    when 'vw' then 'volkswagen'
    when 'v w' then 'volkswagen'
    when 'volkswag' then 'volkswagen'
    when 'mb' then 'mercedesbenz'
    when 'mercedes' then 'mercedesbenz'
    when 'mercedesbenz' then 'mercedesbenz'
    when 'bmw' then 'bmw'
    when 'chevy' then 'chevrolet'
    else p_make_key
  end;
$$;

create or replace function public.carzon_model_data_canonical_make_label(p_make_key text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case public.carzon_model_data_apply_make_alias_key(p_make_key)
    when 'volkswagen' then 'Volkswagen'
    when 'mercedesbenz' then 'Mercedes-Benz'
    when 'bmw' then 'BMW'
    when 'chevrolet' then 'Chevrolet'
    when 'toyota' then 'Toyota'
    else initcap(public.carzon_model_data_fold_whitespace(
      replace(replace(p_make_key, 'benz', 'Benz'), 'vw', 'VW')
    ))
  end;
$$;

create or replace function public.carzon_model_data_resolve_identity(
    p_make text,
    p_model text,
    p_year integer
)
returns table (
    lookup_make text,
    lookup_model text,
    lookup_year integer,
    make_key text,
    model_key text,
    cache_key text,
    valid boolean
)
language plpgsql
immutable
security invoker
set search_path = public, extensions, pg_temp
as $$
declare
    v_make_raw text;
    v_model_raw text;
    v_make_key text;
    v_model_key text;
    v_alias_key text;
    v_year integer;
begin
    v_make_raw := public.carzon_model_data_fold_whitespace(p_make);
    v_model_raw := public.carzon_model_data_fold_whitespace(p_model);
    v_make_key := public.carzon_model_data_normalize_make_key(v_make_raw);
    v_model_key := public.carzon_model_data_normalize_model_key(v_model_raw);
    v_year := p_year;

    if v_make_key is null or v_model_key is null then
        return query
        select null::text, null::text, null::integer, null::text, null::text, null::text, false;
        return;
    end if;

    if v_year is null or v_year < 1900 or v_year > 2100 then
        return query
        select null::text, null::text, null::integer, null::text, null::text, null::text, false;
        return;
    end if;

    v_alias_key := public.carzon_model_data_apply_make_alias_key(v_make_key);

    return query
    select
        public.carzon_model_data_canonical_make_label(v_alias_key),
        v_model_raw,
        v_year,
        v_alias_key,
        v_model_key,
        public.carzon_sha256_hex_utf8(
            'epa_fueleconomy' || '|' || v_alias_key || '|' || v_model_key || '|' || v_year::text
        ),
        true;
end;
$$;

create or replace function public.carzon_model_data_default_limitation_codes()
returns text[]
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select array[
    'us_market_data_only',
    'may_differ_by_trim_engine_market',
    'model_level_not_exact_vehicle',
    'not_vehicle_history',
    'not_recall_data'
  ]::text[];
$$;

create or replace function public.carzon_model_data_build_cache_key(
    p_source_id text,
    p_make_key text,
    p_model_key text,
    p_year integer
)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, extensions, pg_temp
as $$
  select public.carzon_sha256_hex_utf8(
    coalesce(p_source_id, '') || '|'
    || coalesce(p_make_key, '') || '|'
    || coalesce(p_model_key, '') || '|'
    || coalesce(p_year::text, '')
  );
$$;

revoke all on function public.carzon_model_data_fold_whitespace(text) from public;
revoke all on function public.carzon_model_data_normalize_make_key(text) from public;
revoke all on function public.carzon_model_data_normalize_model_key(text) from public;
revoke all on function public.carzon_model_data_apply_make_alias_key(text) from public;
revoke all on function public.carzon_model_data_canonical_make_label(text) from public;
revoke all on function public.carzon_model_data_resolve_identity(text, text, integer) from public;
revoke all on function public.carzon_model_data_default_limitation_codes() from public;
revoke all on function public.carzon_model_data_build_cache_key(text, text, text, integer) from public;

------------------------------------------------------------------------------
-- 2 — vehicle_model_source_cache
------------------------------------------------------------------------------

create table if not exists public.vehicle_model_source_cache (
    id uuid primary key default gen_random_uuid(),
    cache_key text not null,
    source_id text not null,
    lookup_make text not null,
    lookup_model text not null,
    lookup_year integer not null,
    status text not null default 'pending',
    confidence text not null default 'unknown',
    normalized_summary jsonb not null default '{}'::jsonb,
    limitation_codes text[] not null default '{}'::text[],
    match_quality text,
    source_label text,
    provider_version text,
    fetched_at timestamptz,
    ttl_until timestamptz,
    source_metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint vehicle_model_source_cache_cache_key_uniq unique (cache_key),
    constraint vehicle_model_source_cache_source_id_chk
        check (
            source_id ~ '^[a-z][a-z0-9_]{0,63}$'
            and length(source_id) >= 1
        ),
    constraint vehicle_model_source_cache_status_chk
        check (
            status in (
                'pending',
                'succeeded',
                'no_data',
                'partial',
                'failed',
                'stale'
            )
        ),
    constraint vehicle_model_source_cache_confidence_chk
        check (
            confidence in ('official', 'open_data', 'commercial', 'unknown')
        ),
    constraint vehicle_model_source_cache_match_quality_chk
        check (
            match_quality is null
            or match_quality in (
                'exact_make_model_year',
                'make_model_year_multiple_options',
                'make_model_year_fuzzy_rejected',
                'no_match'
            )
        ),
    constraint vehicle_model_source_cache_year_chk
        check (lookup_year >= 1900 and lookup_year <= 2100),
    constraint vehicle_model_source_cache_summary_obj_chk
        check (jsonb_typeof(normalized_summary) = 'object'),
    constraint vehicle_model_source_cache_metadata_obj_chk
        check (jsonb_typeof(source_metadata) = 'object'),
    constraint vehicle_model_source_cache_limitation_codes_on_success_chk
        check (
            status not in ('succeeded', 'partial')
            or coalesce(array_length(limitation_codes, 1), 0) >= 1
        )
);

create index if not exists vehicle_model_source_cache_lookup_idx
    on public.vehicle_model_source_cache (lookup_make, lookup_model, lookup_year, source_id);

create index if not exists vehicle_model_source_cache_status_updated_idx
    on public.vehicle_model_source_cache (status, updated_at);

create index if not exists vehicle_model_source_cache_ttl_until_idx
    on public.vehicle_model_source_cache (ttl_until)
    where ttl_until is not null;

alter table public.vehicle_model_source_cache enable row level security;

revoke all on table public.vehicle_model_source_cache from public;
revoke all on table public.vehicle_model_source_cache from anon;
revoke all on table public.vehicle_model_source_cache from authenticated;

------------------------------------------------------------------------------
-- 3 — vehicle_model_fetch_jobs
------------------------------------------------------------------------------

create table if not exists public.vehicle_model_fetch_jobs (
    id uuid primary key default gen_random_uuid(),
    cache_key text not null,
    source_id text not null,
    lookup_make text not null,
    lookup_model text not null,
    lookup_year integer not null,
    status text not null default 'queued',
    attempts integer not null default 0,
    max_attempts integer not null default 3,
    idempotency_key text not null,
    last_error_safe text,
    claimed_at timestamptz,
    completed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint vehicle_model_fetch_jobs_idempotency_key_uniq unique (idempotency_key),
    constraint vehicle_model_fetch_jobs_source_id_chk
        check (
            source_id ~ '^[a-z][a-z0-9_]{0,63}$'
            and length(source_id) >= 1
        ),
    constraint vehicle_model_fetch_jobs_status_chk
        check (
            status in ('queued', 'processing', 'succeeded', 'failed', 'dead')
        ),
    constraint vehicle_model_fetch_jobs_year_chk
        check (lookup_year >= 1900 and lookup_year <= 2100),
    constraint vehicle_model_fetch_jobs_attempts_chk
        check (attempts >= 0 and max_attempts >= 1 and attempts <= max_attempts + 1)
);

create index if not exists vehicle_model_fetch_jobs_status_created_idx
    on public.vehicle_model_fetch_jobs (status, created_at);

create index if not exists vehicle_model_fetch_jobs_cache_key_idx
    on public.vehicle_model_fetch_jobs (cache_key);

create index if not exists vehicle_model_fetch_jobs_source_id_idx
    on public.vehicle_model_fetch_jobs (source_id);

alter table public.vehicle_model_fetch_jobs enable row level security;

revoke all on table public.vehicle_model_fetch_jobs from public;
revoke all on table public.vehicle_model_fetch_jobs from anon;
revoke all on table public.vehicle_model_fetch_jobs from authenticated;

------------------------------------------------------------------------------
-- 4 — enqueue_vehicle_model_fetch_if_needed (internal + service_role)
------------------------------------------------------------------------------

create or replace function public.enqueue_vehicle_model_fetch_if_needed(
    p_make text,
    p_model text,
    p_year integer,
    p_source_id text default 'epa_fueleconomy'
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_identity record;
    v_cache_key text;
    v_source_id text;
    v_cache record;
    v_active_job integer;
    v_should_enqueue boolean := false;
    v_idempotency_key text;
begin
    v_source_id := nullif(btrim(coalesce(p_source_id, '')), '');
    if v_source_id is null or v_source_id <> 'epa_fueleconomy' then
        return 'invalid_source_id';
    end if;

    select *
      into v_identity
      from public.carzon_model_data_resolve_identity(p_make, p_model, p_year) r
     limit 1;

    if not coalesce(v_identity.valid, false) then
        return 'invalid_input';
    end if;

    v_cache_key := public.carzon_model_data_build_cache_key(
        v_source_id,
        v_identity.make_key,
        v_identity.model_key,
        v_identity.lookup_year
    );

    insert into public.vehicle_model_source_cache (
        cache_key,
        source_id,
        lookup_make,
        lookup_model,
        lookup_year,
        status,
        confidence,
        normalized_summary,
        limitation_codes,
        created_at,
        updated_at
    )
    values (
        v_cache_key,
        v_source_id,
        v_identity.lookup_make,
        v_identity.lookup_model,
        v_identity.lookup_year,
        'pending',
        'unknown',
        '{}'::jsonb,
        '{}'::text[],
        now(),
        now()
    )
    on conflict (cache_key) do nothing;

    select c.status, c.ttl_until
      into v_cache
      from public.vehicle_model_source_cache c
     where c.cache_key = v_cache_key
     for update;

    v_should_enqueue := (
        v_cache.status in ('pending', 'failed', 'stale', 'no_data')
        or (
            v_cache.ttl_until is not null
            and v_cache.ttl_until <= now()
            and v_cache.status in ('succeeded', 'partial', 'no_data', 'failed', 'stale')
        )
    );

    if v_should_enqueue
       and v_cache.ttl_until is not null
       and v_cache.ttl_until <= now()
       and v_cache.status in ('succeeded', 'partial')
    then
        update public.vehicle_model_source_cache c
           set status = 'stale',
               updated_at = now()
         where c.cache_key = v_cache_key;
    end if;

    if not v_should_enqueue then
        return 'skipped';
    end if;

    v_idempotency_key := v_cache_key || '|' || v_source_id || '|fetch';

    select count(*)::integer
      into v_active_job
      from public.vehicle_model_fetch_jobs j
     where j.idempotency_key = v_idempotency_key
       and j.status in ('queued', 'processing');

    if coalesce(v_active_job, 0) > 0 then
        return 'already_queued';
    end if;

    insert into public.vehicle_model_fetch_jobs (
        cache_key,
        source_id,
        lookup_make,
        lookup_model,
        lookup_year,
        status,
        attempts,
        max_attempts,
        idempotency_key,
        created_at,
        updated_at
    )
    values (
        v_cache_key,
        v_source_id,
        v_identity.lookup_make,
        v_identity.lookup_model,
        v_identity.lookup_year,
        'queued',
        0,
        3,
        v_idempotency_key,
        now(),
        now()
    )
    on conflict (idempotency_key) do nothing;

    return 'enqueued';
end;
$$;

comment on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text) is
    'Idempotently upserts cache row and enqueues model-data fetch job for epa_fueleconomy only. '
    'Not for direct client use; invoked by buyer RPC and worker paths.';

revoke all on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text)
    from public;
revoke all on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text)
    from anon;
revoke all on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text)
    from authenticated;
grant execute on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text)
    to service_role;

------------------------------------------------------------------------------
-- 5 — claim_vehicle_model_fetch_jobs_for_processing
------------------------------------------------------------------------------

create or replace function public.claim_vehicle_model_fetch_jobs_for_processing(
    p_limit integer default 10
)
returns table (
    job_id uuid,
    cache_key text,
    source_id text,
    lookup_make text,
    lookup_model text,
    lookup_year integer,
    attempts integer
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
          from public.vehicle_model_fetch_jobs j
         where j.status = 'queued'
           and j.attempts < j.max_attempts
         order by j.created_at asc
         limit v_lim
           for update skip locked
    ),
    upd as (
        update public.vehicle_model_fetch_jobs j
           set status = 'processing',
               claimed_at = now(),
               attempts = j.attempts + 1,
               updated_at = now()
          from picked p
         where j.id = p.id
        returning
            j.id,
            j.cache_key,
            j.source_id,
            j.lookup_make,
            j.lookup_model,
            j.lookup_year,
            j.attempts
    )
    select
        u.id,
        u.cache_key,
        u.source_id,
        u.lookup_make,
        u.lookup_model,
        u.lookup_year,
        u.attempts
      from upd u;
end;
$$;

------------------------------------------------------------------------------
-- 6 — complete_vehicle_model_fetch_job_success
------------------------------------------------------------------------------

create or replace function public.complete_vehicle_model_fetch_job_success(
    p_job_id uuid,
    p_cache_key text,
    p_status text,
    p_confidence text,
    p_normalized_summary jsonb,
    p_limitation_codes text[],
    p_match_quality text default null,
    p_source_label text default null,
    p_provider_version text default null,
    p_source_metadata jsonb default '{}'::jsonb,
    p_ttl_days integer default 90
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_job record;
    v_codes text[];
    v_ttl interval;
begin
    if p_job_id is null or p_cache_key is null then
        raise exception 'complete_vehicle_model_fetch_job_success: job_id and cache_key required'
            using errcode = '23502';
    end if;

    if p_status not in ('succeeded', 'partial', 'no_data') then
        raise exception 'complete_vehicle_model_fetch_job_success: invalid status'
            using errcode = '23514';
    end if;

    if jsonb_typeof(p_normalized_summary) <> 'object'
        or jsonb_typeof(p_source_metadata) <> 'object'
    then
        raise exception 'complete_vehicle_model_fetch_job_success: invalid jsonb shapes'
            using errcode = '23514';
    end if;

    select j.id, j.cache_key, j.source_id
      into strict v_job
      from public.vehicle_model_fetch_jobs j
     where j.id = p_job_id
       and j.status = 'processing'
       and j.cache_key = p_cache_key
     for update;

    v_codes := coalesce(p_limitation_codes, '{}'::text[]);
    if p_status in ('succeeded', 'partial')
       and coalesce(array_length(v_codes, 1), 0) = 0
    then
        v_codes := public.carzon_model_data_default_limitation_codes();
    end if;

    v_ttl := make_interval(days => greatest(coalesce(p_ttl_days, 90), 1));

    update public.vehicle_model_source_cache c
       set status = p_status,
           confidence = coalesce(nullif(btrim(p_confidence), ''), c.confidence),
           normalized_summary = p_normalized_summary,
           limitation_codes = v_codes,
           match_quality = p_match_quality,
           source_label = nullif(btrim(coalesce(p_source_label, '')), ''),
           provider_version = nullif(btrim(coalesce(p_provider_version, '')), ''),
           source_metadata = p_source_metadata,
           fetched_at = now(),
           ttl_until = case
               when p_status = 'no_data' then now() + make_interval(days => 7)
               else now() + v_ttl
           end,
           updated_at = now()
     where c.cache_key = p_cache_key
       and c.source_id = v_job.source_id;

    if not found then
        raise exception 'complete_vehicle_model_fetch_job_success: cache row missing'
            using errcode = 'P0002';
    end if;

    update public.vehicle_model_fetch_jobs j
       set status = 'succeeded',
           completed_at = now(),
           last_error_safe = null,
           updated_at = now()
     where j.id = p_job_id;
end;
$$;

------------------------------------------------------------------------------
-- 7 — complete_vehicle_model_fetch_job_failure
------------------------------------------------------------------------------

create or replace function public.complete_vehicle_model_fetch_job_failure(
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
begin
    if p_job_id is null then
        raise exception 'complete_vehicle_model_fetch_job_failure: job_id required'
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

    select j.id, j.cache_key, j.attempts, j.max_attempts
      into strict v_job
      from public.vehicle_model_fetch_jobs j
     where j.id = p_job_id
       and j.status = 'processing'
     for update;

    if p_retryable and v_job.attempts < v_job.max_attempts then
        update public.vehicle_model_fetch_jobs j
           set status = 'queued',
               last_error_safe = nullif(v_err, ''),
               claimed_at = null,
               updated_at = now()
         where j.id = p_job_id;
    else
        update public.vehicle_model_fetch_jobs j
           set status = 'dead',
               last_error_safe = nullif(v_err, ''),
               completed_at = now(),
               updated_at = now()
         where j.id = p_job_id;

        update public.vehicle_model_source_cache c
           set status = 'failed',
               updated_at = now()
         where c.cache_key = v_job.cache_key
           and c.status in ('pending', 'stale');
    end if;
end;
$$;

------------------------------------------------------------------------------
-- 8 — get_listing_model_data_for_buyer
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
stable
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
        c.normalized_summary,
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
     where c.source_id = 'epa_fueleconomy'
       and c.status in ('succeeded', 'partial')
       and (c.ttl_until is null or c.ttl_until > now())
       and c.normalized_summary <> '{}'::jsonb
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
    'never reads listing_vehicle_identity or VIN tables. Does not return source_metadata, '
    'cache_key, or job identifiers. Enqueues background fetch idempotently on miss/stale.';

revoke all on function public.get_listing_model_data_for_buyer(uuid) from public;
grant execute on function public.get_listing_model_data_for_buyer(uuid)
    to anon, authenticated;

------------------------------------------------------------------------------
-- 9 — Worker RPC privileges
------------------------------------------------------------------------------

revoke all on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)
    from public;
revoke all on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)
    from anon;
revoke all on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)
    from authenticated;
grant execute on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)
    to service_role;

revoke all on function public.complete_vehicle_model_fetch_job_success(
    uuid, text, text, text, jsonb, text[], text, text, text, jsonb, integer
) from public;
revoke all on function public.complete_vehicle_model_fetch_job_success(
    uuid, text, text, text, jsonb, text[], text, text, text, jsonb, integer
) from anon;
revoke all on function public.complete_vehicle_model_fetch_job_success(
    uuid, text, text, text, jsonb, text[], text, text, text, jsonb, integer
) from authenticated;
grant execute on function public.complete_vehicle_model_fetch_job_success(
    uuid, text, text, text, jsonb, text[], text, text, text, jsonb, integer
) to service_role;

revoke all on function public.complete_vehicle_model_fetch_job_failure(uuid, text, boolean)
    from public;
revoke all on function public.complete_vehicle_model_fetch_job_failure(uuid, text, boolean)
    from anon;
revoke all on function public.complete_vehicle_model_fetch_job_failure(uuid, text, boolean)
    from authenticated;
grant execute on function public.complete_vehicle_model_fetch_job_failure(uuid, text, boolean)
    to service_role;
