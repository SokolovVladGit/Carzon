-- Carzon — Recall / Safety Campaigns Phase 1: global model-level cache + fetch jobs + RPCs.
--
-- * Separate from Model Passport (vehicle_model_*), VIN decode, listing_vin_source_results.
-- * Model-level only: listings.make / model / year — never VIN or listing_vehicle_identity.
-- * anon/authenticated: buyer RPC only; no direct table access.
-- * Worker RPCs: service_role only.
-- * Phase 1: schema + worker RPCs only; NHTSA HTTP provider is Phase 2 Edge Function.

------------------------------------------------------------------------------
-- 1 — Identity helpers (deterministic; reuses generic Model Passport normalizers)
------------------------------------------------------------------------------

create or replace function public.carzon_recall_data_build_cache_key(
    p_source_id text,
    p_make_key text,
    p_model_key text,
    p_model_year integer
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
    || coalesce(p_model_year::text, '')
  );
$$;

create or replace function public.carzon_recall_data_resolve_identity(
    p_make text,
    p_model text,
    p_year integer,
    p_source_id text default 'nhtsa_recalls'
)
returns table (
    source_id text,
    lookup_make text,
    lookup_model text,
    model_year integer,
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
    v_source_id text;
begin
    v_source_id := nullif(btrim(coalesce(p_source_id, '')), '');
    if v_source_id is null or v_source_id <> 'nhtsa_recalls' then
        return query
        select null::text, null::text, null::text, null::integer,
               null::text, null::text, null::text, false;
        return;
    end if;

    v_make_raw := public.carzon_model_data_fold_whitespace(p_make);
    v_model_raw := public.carzon_model_data_fold_whitespace(p_model);
    v_make_key := public.carzon_model_data_normalize_make_key(v_make_raw);
    v_model_key := public.carzon_model_data_normalize_model_key(v_model_raw);
    v_year := p_year;

    if v_make_key is null or v_model_key is null then
        return query
        select v_source_id, null::text, null::text, null::integer,
               null::text, null::text, null::text, false;
        return;
    end if;

    if v_year is null or v_year < 1900 or v_year > 2100 then
        return query
        select v_source_id, null::text, null::text, null::integer,
               null::text, null::text, null::text, false;
        return;
    end if;

    v_alias_key := public.carzon_model_data_apply_make_alias_key(v_make_key);

    return query
    select
        v_source_id,
        public.carzon_model_data_canonical_make_label(v_alias_key),
        v_model_raw,
        v_year,
        v_alias_key,
        v_model_key,
        public.carzon_recall_data_build_cache_key(
            v_source_id,
            v_alias_key,
            v_model_key,
            v_year
        ),
        true;
end;
$$;

create or replace function public.carzon_recall_data_default_limitation_codes()
returns text[]
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select array[
    'us_market_data_only',
    'model_level_not_exact_vehicle',
    'not_vin_verified_recall_status',
    'may_differ_by_trim_engine_market',
    'verify_with_official_dealer_or_nhtsa'
  ]::text[];
$$;

revoke all on function public.carzon_recall_data_build_cache_key(text, text, text, integer)
    from public;
revoke all on function public.carzon_recall_data_resolve_identity(text, text, integer, text)
    from public;
revoke all on function public.carzon_recall_data_default_limitation_codes() from public;

------------------------------------------------------------------------------
-- 2 — vehicle_recall_source_cache
------------------------------------------------------------------------------

create table if not exists public.vehicle_recall_source_cache (
    id uuid primary key default gen_random_uuid(),
    source_id text not null,
    cache_key text not null,
    lookup_make text not null,
    lookup_model text not null,
    make_key text not null,
    model_key text not null,
    model_year integer not null,
    status text not null default 'pending',
    normalized_summary jsonb not null default '{}'::jsonb,
    limitation_codes text[] not null default '{}'::text[],
    match_quality text,
    source_label text not null default 'NHTSA',
    source_updated_at timestamptz,
    fetched_at timestamptz,
    ttl_until timestamptz,
    source_metadata jsonb not null default '{}'::jsonb,
    error_code text,
    error_message text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint vehicle_recall_source_cache_cache_key_uniq unique (cache_key),
    constraint vehicle_recall_source_cache_source_id_chk
        check (
            source_id ~ '^[a-z][a-z0-9_]{0,63}$'
            and length(source_id) >= 1
        ),
    constraint vehicle_recall_source_cache_status_chk
        check (
            status in (
                'pending',
                'succeeded',
                'partial',
                'no_data',
                'failed',
                'stale'
            )
        ),
    constraint vehicle_recall_source_cache_match_quality_chk
        check (
            match_quality is null
            or match_quality in (
                'exact_make_model_year',
                'make_model_year_multiple_campaigns',
                'make_model_year_fuzzy_rejected',
                'no_match'
            )
        ),
    constraint vehicle_recall_source_cache_year_chk
        check (model_year >= 1900 and model_year <= 2100),
    constraint vehicle_recall_source_cache_make_key_chk
        check (length(btrim(make_key)) >= 1),
    constraint vehicle_recall_source_cache_model_key_chk
        check (length(btrim(model_key)) >= 1),
    constraint vehicle_recall_source_cache_summary_obj_chk
        check (jsonb_typeof(normalized_summary) = 'object'),
    constraint vehicle_recall_source_cache_metadata_obj_chk
        check (jsonb_typeof(source_metadata) = 'object'),
    constraint vehicle_recall_source_cache_limitation_codes_on_success_chk
        check (
            status not in ('succeeded', 'partial')
            or coalesce(array_length(limitation_codes, 1), 0) >= 1
        )
);

create index if not exists vehicle_recall_source_cache_lookup_idx
    on public.vehicle_recall_source_cache (lookup_make, lookup_model, model_year, source_id);

create index if not exists vehicle_recall_source_cache_status_updated_idx
    on public.vehicle_recall_source_cache (status, updated_at);

create index if not exists vehicle_recall_source_cache_ttl_until_idx
    on public.vehicle_recall_source_cache (ttl_until)
    where ttl_until is not null;

alter table public.vehicle_recall_source_cache enable row level security;

revoke all on table public.vehicle_recall_source_cache from public;
revoke all on table public.vehicle_recall_source_cache from anon;
revoke all on table public.vehicle_recall_source_cache from authenticated;

------------------------------------------------------------------------------
-- 3 — vehicle_recall_fetch_jobs
------------------------------------------------------------------------------

create table if not exists public.vehicle_recall_fetch_jobs (
    id uuid primary key default gen_random_uuid(),
    source_id text not null,
    cache_key text not null,
    lookup_make text not null,
    lookup_model text not null,
    make_key text not null,
    model_key text not null,
    model_year integer not null,
    status text not null default 'queued',
    attempts integer not null default 0,
    max_attempts integer not null default 5,
    priority integer not null default 100,
    run_after timestamptz not null default now(),
    claimed_at timestamptz,
    claimed_by text,
    last_error_code text,
    last_error_message text,
    idempotency_key text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint vehicle_recall_fetch_jobs_idempotency_key_uniq unique (idempotency_key),
    constraint vehicle_recall_fetch_jobs_source_id_chk
        check (
            source_id ~ '^[a-z][a-z0-9_]{0,63}$'
            and length(source_id) >= 1
        ),
    constraint vehicle_recall_fetch_jobs_status_chk
        check (
            status in ('queued', 'processing', 'succeeded', 'failed', 'dead')
        ),
    constraint vehicle_recall_fetch_jobs_year_chk
        check (model_year >= 1900 and model_year <= 2100),
    constraint vehicle_recall_fetch_jobs_attempts_chk
        check (attempts >= 0 and max_attempts >= 1 and attempts <= max_attempts + 1)
);

create index if not exists vehicle_recall_fetch_jobs_status_run_after_idx
    on public.vehicle_recall_fetch_jobs (status, run_after, priority, created_at);

create index if not exists vehicle_recall_fetch_jobs_cache_key_idx
    on public.vehicle_recall_fetch_jobs (cache_key);

create index if not exists vehicle_recall_fetch_jobs_source_id_idx
    on public.vehicle_recall_fetch_jobs (source_id);

alter table public.vehicle_recall_fetch_jobs enable row level security;

revoke all on table public.vehicle_recall_fetch_jobs from public;
revoke all on table public.vehicle_recall_fetch_jobs from anon;
revoke all on table public.vehicle_recall_fetch_jobs from authenticated;

------------------------------------------------------------------------------
-- 4 — enqueue_vehicle_recall_fetch_if_needed (internal + service_role)
------------------------------------------------------------------------------

create or replace function public.enqueue_vehicle_recall_fetch_if_needed(
    p_make text,
    p_model text,
    p_year integer,
    p_source_id text default 'nhtsa_recalls'
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
    if v_source_id is null or v_source_id <> 'nhtsa_recalls' then
        return 'invalid_source_id';
    end if;

    select *
      into v_identity
      from public.carzon_recall_data_resolve_identity(
          p_make,
          p_model,
          p_year,
          v_source_id
      ) r
     limit 1;

    if not coalesce(v_identity.valid, false) then
        return 'invalid_input';
    end if;

    v_cache_key := v_identity.cache_key;

    insert into public.vehicle_recall_source_cache (
        source_id,
        cache_key,
        lookup_make,
        lookup_model,
        make_key,
        model_key,
        model_year,
        status,
        normalized_summary,
        limitation_codes,
        source_label,
        created_at,
        updated_at
    )
    values (
        v_source_id,
        v_cache_key,
        v_identity.lookup_make,
        v_identity.lookup_model,
        v_identity.make_key,
        v_identity.model_key,
        v_identity.model_year,
        'pending',
        '{}'::jsonb,
        '{}'::text[],
        'NHTSA',
        now(),
        now()
    )
    on conflict (cache_key) do nothing;

    select c.status, c.ttl_until
      into v_cache
      from public.vehicle_recall_source_cache c
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
        update public.vehicle_recall_source_cache c
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
      from public.vehicle_recall_fetch_jobs j
     where j.idempotency_key = v_idempotency_key
       and j.status in ('queued', 'processing');

    if coalesce(v_active_job, 0) > 0 then
        return 'already_queued';
    end if;

    insert into public.vehicle_recall_fetch_jobs (
        source_id,
        cache_key,
        lookup_make,
        lookup_model,
        make_key,
        model_key,
        model_year,
        status,
        attempts,
        max_attempts,
        priority,
        run_after,
        idempotency_key,
        created_at,
        updated_at
    )
    values (
        v_source_id,
        v_cache_key,
        v_identity.lookup_make,
        v_identity.lookup_model,
        v_identity.make_key,
        v_identity.model_key,
        v_identity.model_year,
        'queued',
        0,
        5,
        100,
        now(),
        v_idempotency_key,
        now(),
        now()
    )
    on conflict (idempotency_key) do nothing;

    return 'enqueued';
end;
$$;

comment on function public.enqueue_vehicle_recall_fetch_if_needed(text, text, integer, text) is
    'Idempotently upserts recall cache row and enqueues fetch job for nhtsa_recalls only. '
    'Model-level make/model/year only; not for direct client use.';

revoke all on function public.enqueue_vehicle_recall_fetch_if_needed(text, text, integer, text)
    from public;
revoke all on function public.enqueue_vehicle_recall_fetch_if_needed(text, text, integer, text)
    from anon;
revoke all on function public.enqueue_vehicle_recall_fetch_if_needed(text, text, integer, text)
    from authenticated;
grant execute on function public.enqueue_vehicle_recall_fetch_if_needed(text, text, integer, text)
    to service_role;

------------------------------------------------------------------------------
-- 5 — claim_vehicle_recall_fetch_jobs_for_processing
------------------------------------------------------------------------------

create or replace function public.claim_vehicle_recall_fetch_jobs_for_processing(
    p_limit integer default 10,
    p_worker_id text default 'edge'
)
returns table (
    job_id uuid,
    cache_key text,
    source_id text,
    lookup_make text,
    lookup_model text,
    make_key text,
    model_key text,
    model_year integer,
    attempts integer
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_lim integer;
    v_worker text;
begin
    v_lim := greatest(1, least(coalesce(p_limit, 10), 50));
    v_worker := left(nullif(btrim(coalesce(p_worker_id, '')), ''), 64);
    if v_worker is null then
        v_worker := 'edge';
    end if;

    return query
    with picked as (
        select j.id
          from public.vehicle_recall_fetch_jobs j
         where j.status = 'queued'
           and j.run_after <= now()
           and j.attempts < j.max_attempts
         order by j.priority asc, j.run_after asc, j.created_at asc
         limit v_lim
           for update skip locked
    ),
    upd as (
        update public.vehicle_recall_fetch_jobs j
           set status = 'processing',
               claimed_at = now(),
               claimed_by = v_worker,
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
            j.make_key,
            j.model_key,
            j.model_year,
            j.attempts
    )
    select
        u.id,
        u.cache_key,
        u.source_id,
        u.lookup_make,
        u.lookup_model,
        u.make_key,
        u.model_key,
        u.model_year,
        u.attempts
      from upd u;
end;
$$;

------------------------------------------------------------------------------
-- 6 — complete_vehicle_recall_fetch_job_success
------------------------------------------------------------------------------

create or replace function public.complete_vehicle_recall_fetch_job_success(
    p_job_id uuid,
    p_cache_key text,
    p_status text,
    p_normalized_summary jsonb,
    p_limitation_codes text[],
    p_match_quality text default null,
    p_source_label text default null,
    p_source_updated_at timestamptz default null,
    p_source_metadata jsonb default '{}'::jsonb,
    p_ttl_days integer default 30
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
        raise exception 'complete_vehicle_recall_fetch_job_success: job_id and cache_key required'
            using errcode = '23502';
    end if;

    if p_status not in ('succeeded', 'partial', 'no_data') then
        raise exception 'complete_vehicle_recall_fetch_job_success: invalid status'
            using errcode = '23514';
    end if;

    if jsonb_typeof(p_normalized_summary) <> 'object'
        or jsonb_typeof(p_source_metadata) <> 'object'
    then
        raise exception 'complete_vehicle_recall_fetch_job_success: invalid jsonb shapes'
            using errcode = '23514';
    end if;

    select j.id, j.cache_key, j.source_id
      into strict v_job
      from public.vehicle_recall_fetch_jobs j
     where j.id = p_job_id
       and j.status = 'processing'
       and j.cache_key = p_cache_key
     for update;

    v_codes := coalesce(p_limitation_codes, '{}'::text[]);
    if p_status in ('succeeded', 'partial')
       and coalesce(array_length(v_codes, 1), 0) = 0
    then
        v_codes := public.carzon_recall_data_default_limitation_codes();
    end if;

    v_ttl := make_interval(days => greatest(coalesce(p_ttl_days, 30), 1));

    update public.vehicle_recall_source_cache c
       set status = p_status,
           normalized_summary = p_normalized_summary,
           limitation_codes = v_codes,
           match_quality = p_match_quality,
           source_label = coalesce(
               nullif(btrim(coalesce(p_source_label, '')), ''),
               'NHTSA'
           ),
           source_updated_at = p_source_updated_at,
           source_metadata = p_source_metadata,
           fetched_at = now(),
           error_code = null,
           error_message = null,
           ttl_until = case
               when p_status = 'no_data' then now() + make_interval(days => 7)
               else now() + v_ttl
           end,
           updated_at = now()
     where c.cache_key = p_cache_key
       and c.source_id = v_job.source_id;

    if not found then
        raise exception 'complete_vehicle_recall_fetch_job_success: cache row missing'
            using errcode = 'P0002';
    end if;

    update public.vehicle_recall_fetch_jobs j
       set status = 'succeeded',
           last_error_code = null,
           last_error_message = null,
           updated_at = now()
     where j.id = p_job_id;
end;
$$;

------------------------------------------------------------------------------
-- 7 — complete_vehicle_recall_fetch_job_failure
------------------------------------------------------------------------------

create or replace function public.complete_vehicle_recall_fetch_job_failure(
    p_job_id uuid,
    p_error_code text,
    p_error_message text,
    p_retryable boolean default true,
    p_retry_delay_seconds integer default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_job record;
    v_code text;
    v_msg text;
    v_delay integer;
begin
    if p_job_id is null then
        raise exception 'complete_vehicle_recall_fetch_job_failure: job_id required'
            using errcode = '23502';
    end if;

    v_code := left(
        trim(
            regexp_replace(
                coalesce(p_error_code, ''),
                '[[:cntrl:]]',
                ' ',
                'g'
            )
        ),
        64
    );

    v_msg := left(
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
      from public.vehicle_recall_fetch_jobs j
     where j.id = p_job_id
       and j.status = 'processing'
     for update;

    if p_retryable and v_job.attempts < v_job.max_attempts then
        v_delay := coalesce(
            p_retry_delay_seconds,
            least(3600, greatest(60, 60 * power(2, greatest(v_job.attempts - 1, 0))::integer))
        );

        update public.vehicle_recall_fetch_jobs j
           set status = 'queued',
               run_after = now() + make_interval(secs => v_delay),
               claimed_at = null,
               claimed_by = null,
               last_error_code = nullif(v_code, ''),
               last_error_message = nullif(v_msg, ''),
               updated_at = now()
         where j.id = p_job_id;
    else
        update public.vehicle_recall_fetch_jobs j
           set status = 'dead',
               last_error_code = nullif(v_code, ''),
               last_error_message = nullif(v_msg, ''),
               updated_at = now()
         where j.id = p_job_id;

        update public.vehicle_recall_source_cache c
           set status = 'failed',
               error_code = nullif(v_code, ''),
               error_message = nullif(v_msg, ''),
               updated_at = now()
         where c.cache_key = v_job.cache_key
           and c.status in ('pending', 'stale');
    end if;
end;
$$;

------------------------------------------------------------------------------
-- 8 — get_listing_recalls_for_buyer
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
        );
end;
$$;

comment on function public.get_listing_recalls_for_buyer(uuid) is
    'Buyer-safe model-level recall campaigns for active listings. Reads listing make/model/year only; '
    'never reads listing_vehicle_identity or VIN tables. Returns allowlisted campaign summaries only; '
    'does not return source_metadata, cache_key, job identifiers, or raw provider payloads. '
    'Model-level campaigns for make/model/year — not VIN-verified open recall status for this exact vehicle. '
    'Enqueues background fetch idempotently on miss/stale.';

revoke all on function public.get_listing_recalls_for_buyer(uuid) from public;
grant execute on function public.get_listing_recalls_for_buyer(uuid)
    to anon, authenticated;

------------------------------------------------------------------------------
-- 9 — Worker RPC privileges
------------------------------------------------------------------------------

revoke all on function public.claim_vehicle_recall_fetch_jobs_for_processing(integer, text)
    from public;
revoke all on function public.claim_vehicle_recall_fetch_jobs_for_processing(integer, text)
    from anon;
revoke all on function public.claim_vehicle_recall_fetch_jobs_for_processing(integer, text)
    from authenticated;
grant execute on function public.claim_vehicle_recall_fetch_jobs_for_processing(integer, text)
    to service_role;

revoke all on function public.complete_vehicle_recall_fetch_job_success(
    uuid, text, text, jsonb, text[], text, text, timestamptz, jsonb, integer
) from public;
revoke all on function public.complete_vehicle_recall_fetch_job_success(
    uuid, text, text, jsonb, text[], text, text, timestamptz, jsonb, integer
) from anon;
revoke all on function public.complete_vehicle_recall_fetch_job_success(
    uuid, text, text, jsonb, text[], text, text, timestamptz, jsonb, integer
) from authenticated;
grant execute on function public.complete_vehicle_recall_fetch_job_success(
    uuid, text, text, jsonb, text[], text, text, timestamptz, jsonb, integer
) to service_role;

revoke all on function public.complete_vehicle_recall_fetch_job_failure(
    uuid, text, text, boolean, integer
) from public;
revoke all on function public.complete_vehicle_recall_fetch_job_failure(
    uuid, text, text, boolean, integer
) from anon;
revoke all on function public.complete_vehicle_recall_fetch_job_failure(
    uuid, text, text, boolean, integer
) from authenticated;
grant execute on function public.complete_vehicle_recall_fetch_job_failure(
    uuid, text, text, boolean, integer
) to service_role;

notify pgrst, 'reload schema';
