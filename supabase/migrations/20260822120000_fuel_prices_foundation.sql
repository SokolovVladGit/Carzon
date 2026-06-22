-- Carzon — Fuel Prices v1: territory snapshot cache + fetch jobs + public RPC.
--
-- * Moldova: ANRE e-Carburanți national ceiling (anre_ecarburanti_plafon).
-- * PMR: Sheriff retail HTML board (sheriff_retail_html).
-- * anon/authenticated: no direct table access; get_fuel_prices_for_app() only.
-- * Worker RPCs: service_role only.
-- * Cron-only refresh; no client-triggered enqueue.

create extension if not exists pgcrypto with schema extensions;

------------------------------------------------------------------------------
-- 1 — Helpers
------------------------------------------------------------------------------

create or replace function public.carzon_fuel_price_territory_for_cache_key(p_cache_key text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case nullif(btrim(coalesce(p_cache_key, '')), '')
    when 'moldova:anre_plafon' then 'moldova'
    when 'pmr:sheriff_retail' then 'pmr'
    else null
  end;
$$;

create or replace function public.carzon_fuel_price_source_for_cache_key(p_cache_key text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case nullif(btrim(coalesce(p_cache_key, '')), '')
    when 'moldova:anre_plafon' then 'anre_ecarburanti_plafon'
    when 'pmr:sheriff_retail' then 'sheriff_retail_html'
    else null
  end;
$$;

create or replace function public.carzon_fuel_price_default_limitation_codes(p_territory text)
returns text[]
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case nullif(btrim(coalesce(p_territory, '')), '')
    when 'moldova' then array['national_ceiling', 'verify_at_station']::text[]
    when 'pmr' then array['sheriff_network', 'verify_at_station', 'no_source_effective_date']::text[]
    else '{}'::text[]
  end;
$$;

revoke all on function public.carzon_fuel_price_territory_for_cache_key(text) from public;
revoke all on function public.carzon_fuel_price_source_for_cache_key(text) from public;
revoke all on function public.carzon_fuel_price_default_limitation_codes(text) from public;

------------------------------------------------------------------------------
-- 2 — fuel_price_source_cache
------------------------------------------------------------------------------

create table if not exists public.fuel_price_source_cache (
    id uuid primary key default gen_random_uuid(),
    cache_key text not null,
    territory text not null,
    source_id text not null,
    status text not null default 'pending',
    normalized_summary jsonb not null default '{}'::jsonb,
    limitation_codes text[] not null default '{}'::text[],
    source_label text,
    effective_date date,
    fetched_at timestamptz,
    ttl_until timestamptz,
    failure_code text,
    source_metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint fuel_price_source_cache_cache_key_uniq unique (cache_key),
    constraint fuel_price_source_cache_territory_chk
        check (territory in ('moldova', 'pmr')),
    constraint fuel_price_source_cache_source_id_chk
        check (
            source_id in ('anre_ecarburanti_plafon', 'sheriff_retail_html')
        ),
    constraint fuel_price_source_cache_status_chk
        check (
            status in (
                'pending',
                'succeeded',
                'partial',
                'failed',
                'stale'
            )
        ),
    constraint fuel_price_source_cache_summary_obj_chk
        check (jsonb_typeof(normalized_summary) = 'object'),
    constraint fuel_price_source_cache_metadata_obj_chk
        check (jsonb_typeof(source_metadata) = 'object'),
    constraint fuel_price_source_cache_limitation_codes_on_success_chk
        check (
            status not in ('succeeded', 'partial')
            or coalesce(array_length(limitation_codes, 1), 0) >= 1
        )
);

create index if not exists fuel_price_source_cache_territory_source_idx
    on public.fuel_price_source_cache (territory, source_id);

create index if not exists fuel_price_source_cache_status_updated_idx
    on public.fuel_price_source_cache (status, updated_at);

create index if not exists fuel_price_source_cache_ttl_until_idx
    on public.fuel_price_source_cache (ttl_until)
    where ttl_until is not null;

alter table public.fuel_price_source_cache enable row level security;

revoke all on table public.fuel_price_source_cache from public;
revoke all on table public.fuel_price_source_cache from anon;
revoke all on table public.fuel_price_source_cache from authenticated;

------------------------------------------------------------------------------
-- 3 — fuel_price_fetch_jobs
------------------------------------------------------------------------------

create table if not exists public.fuel_price_fetch_jobs (
    id uuid primary key default gen_random_uuid(),
    cache_key text not null,
    territory text not null,
    source_id text not null,
    status text not null default 'queued',
    attempts integer not null default 0,
    max_attempts integer not null default 3,
    idempotency_key text not null,
    last_error_safe text,
    claimed_at timestamptz,
    completed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint fuel_price_fetch_jobs_idempotency_key_uniq unique (idempotency_key),
    constraint fuel_price_fetch_jobs_territory_chk
        check (territory in ('moldova', 'pmr')),
    constraint fuel_price_fetch_jobs_source_id_chk
        check (
            source_id in ('anre_ecarburanti_plafon', 'sheriff_retail_html')
        ),
    constraint fuel_price_fetch_jobs_status_chk
        check (
            status in ('queued', 'processing', 'succeeded', 'failed', 'dead')
        ),
    constraint fuel_price_fetch_jobs_attempts_chk
        check (attempts >= 0 and max_attempts >= 1 and attempts <= max_attempts + 1)
);

create index if not exists fuel_price_fetch_jobs_status_created_idx
    on public.fuel_price_fetch_jobs (status, created_at);

create index if not exists fuel_price_fetch_jobs_cache_key_idx
    on public.fuel_price_fetch_jobs (cache_key);

alter table public.fuel_price_fetch_jobs enable row level security;

revoke all on table public.fuel_price_fetch_jobs from public;
revoke all on table public.fuel_price_fetch_jobs from anon;
revoke all on table public.fuel_price_fetch_jobs from authenticated;

------------------------------------------------------------------------------
-- 4 — Seed cache rows
------------------------------------------------------------------------------

insert into public.fuel_price_source_cache (
    cache_key,
    territory,
    source_id,
    status,
    normalized_summary,
    limitation_codes,
    source_label,
    created_at,
    updated_at
)
values
    (
        'moldova:anre_plafon',
        'moldova',
        'anre_ecarburanti_plafon',
        'pending',
        '{}'::jsonb,
        '{}'::text[],
        'ANRE · e-Carburanți',
        now(),
        now()
    ),
    (
        'pmr:sheriff_retail',
        'pmr',
        'sheriff_retail_html',
        'pending',
        '{}'::jsonb,
        '{}'::text[],
        'Sheriff',
        now(),
        now()
    )
on conflict (cache_key) do nothing;

------------------------------------------------------------------------------
-- 5 — enqueue_fuel_price_fetch_if_needed (service_role)
------------------------------------------------------------------------------

create or replace function public.enqueue_fuel_price_fetch_if_needed(p_cache_key text)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_cache_key text;
    v_territory text;
    v_source_id text;
    v_cache record;
    v_active_job integer;
    v_should_enqueue boolean := false;
    v_idempotency_key text;
begin
    v_cache_key := nullif(btrim(coalesce(p_cache_key, '')), '');
    if v_cache_key is null then
        return 'invalid_cache_key';
    end if;

    v_territory := public.carzon_fuel_price_territory_for_cache_key(v_cache_key);
    v_source_id := public.carzon_fuel_price_source_for_cache_key(v_cache_key);

    if v_territory is null or v_source_id is null then
        return 'invalid_cache_key';
    end if;

    insert into public.fuel_price_source_cache (
        cache_key,
        territory,
        source_id,
        status,
        normalized_summary,
        limitation_codes,
        source_label,
        created_at,
        updated_at
    )
    values (
        v_cache_key,
        v_territory,
        v_source_id,
        'pending',
        '{}'::jsonb,
        '{}'::text[],
        case v_territory
            when 'moldova' then 'ANRE · e-Carburanți'
            when 'pmr' then 'Sheriff'
            else null
        end,
        now(),
        now()
    )
    on conflict (cache_key) do nothing;

    select c.status, c.ttl_until
      into v_cache
      from public.fuel_price_source_cache c
     where c.cache_key = v_cache_key
     for update;

    v_should_enqueue := (
        v_cache.status in ('pending', 'failed', 'stale')
        or (
            v_cache.ttl_until is not null
            and v_cache.ttl_until <= now()
            and v_cache.status in ('succeeded', 'partial', 'failed', 'stale')
        )
    );

    if v_should_enqueue
       and v_cache.ttl_until is not null
       and v_cache.ttl_until <= now()
       and v_cache.status in ('succeeded', 'partial')
    then
        update public.fuel_price_source_cache c
           set status = 'stale',
               updated_at = now()
         where c.cache_key = v_cache_key;
    end if;

    if not v_should_enqueue then
        return 'skipped';
    end if;

    v_idempotency_key := v_cache_key || '|fetch';

    select count(*)::integer
      into v_active_job
      from public.fuel_price_fetch_jobs j
     where j.idempotency_key = v_idempotency_key
       and j.status in ('queued', 'processing');

    if coalesce(v_active_job, 0) > 0 then
        return 'already_queued';
    end if;

    insert into public.fuel_price_fetch_jobs (
        cache_key,
        territory,
        source_id,
        status,
        attempts,
        max_attempts,
        idempotency_key,
        created_at,
        updated_at
    )
    values (
        v_cache_key,
        v_territory,
        v_source_id,
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

comment on function public.enqueue_fuel_price_fetch_if_needed(text) is
    'Idempotently enqueues a fuel-price fetch job when cache is missing, stale, or failed. service_role only.';

revoke all on function public.enqueue_fuel_price_fetch_if_needed(text) from public;
revoke all on function public.enqueue_fuel_price_fetch_if_needed(text) from anon;
revoke all on function public.enqueue_fuel_price_fetch_if_needed(text) from authenticated;
grant execute on function public.enqueue_fuel_price_fetch_if_needed(text) to service_role;

create or replace function public.enqueue_all_fuel_price_fetch_jobs()
returns text[]
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_key text;
    v_out text[] := '{}'::text[];
    v_result text;
begin
    foreach v_key in array array['moldova:anre_plafon', 'pmr:sheriff_retail']
    loop
        v_result := public.enqueue_fuel_price_fetch_if_needed(v_key);
        v_out := array_append(v_out, v_key || ':' || v_result);
    end loop;
    return v_out;
end;
$$;

comment on function public.enqueue_all_fuel_price_fetch_jobs() is
    'Enqueues refresh jobs for all fuel-price territories. service_role only.';

revoke all on function public.enqueue_all_fuel_price_fetch_jobs() from public;
revoke all on function public.enqueue_all_fuel_price_fetch_jobs() from anon;
revoke all on function public.enqueue_all_fuel_price_fetch_jobs() from authenticated;
grant execute on function public.enqueue_all_fuel_price_fetch_jobs() to service_role;

------------------------------------------------------------------------------
-- 6 — claim_fuel_price_fetch_jobs_for_processing
------------------------------------------------------------------------------

create or replace function public.claim_fuel_price_fetch_jobs_for_processing(
    p_limit integer default 10
)
returns table (
    job_id uuid,
    cache_key text,
    territory text,
    source_id text,
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
          from public.fuel_price_fetch_jobs j
         where j.status = 'queued'
           and j.attempts < j.max_attempts
         order by j.created_at asc
         limit v_lim
           for update skip locked
    ),
    upd as (
        update public.fuel_price_fetch_jobs j
           set status = 'processing',
               claimed_at = now(),
               attempts = j.attempts + 1,
               updated_at = now()
          from picked p
         where j.id = p.id
        returning
            j.id,
            j.cache_key,
            j.territory,
            j.source_id,
            j.attempts
    )
    select
        u.id,
        u.cache_key,
        u.territory,
        u.source_id,
        u.attempts
      from upd u;
end;
$$;

------------------------------------------------------------------------------
-- 7 — complete_fuel_price_fetch_job_success
------------------------------------------------------------------------------

create or replace function public.complete_fuel_price_fetch_job_success(
    p_job_id uuid,
    p_cache_key text,
    p_status text,
    p_normalized_summary jsonb,
    p_limitation_codes text[],
    p_source_label text default null,
    p_effective_date date default null,
    p_provider_version text default null,
    p_source_metadata jsonb default '{}'::jsonb,
    p_ttl_hours integer default 24
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
        raise exception 'complete_fuel_price_fetch_job_success: job_id and cache_key required'
            using errcode = '23502';
    end if;

    if p_status not in ('succeeded', 'partial') then
        raise exception 'complete_fuel_price_fetch_job_success: invalid status'
            using errcode = '23514';
    end if;

    if jsonb_typeof(p_normalized_summary) <> 'object'
        or jsonb_typeof(p_source_metadata) <> 'object'
    then
        raise exception 'complete_fuel_price_fetch_job_success: invalid jsonb shapes'
            using errcode = '23514';
    end if;

    select j.id, j.cache_key, j.source_id, j.territory
      into strict v_job
      from public.fuel_price_fetch_jobs j
     where j.id = p_job_id
       and j.status = 'processing'
       and j.cache_key = p_cache_key
     for update;

    v_codes := coalesce(p_limitation_codes, '{}'::text[]);
    if coalesce(array_length(v_codes, 1), 0) = 0 then
        v_codes := public.carzon_fuel_price_default_limitation_codes(v_job.territory);
    end if;

    v_ttl := make_interval(hours => greatest(coalesce(p_ttl_hours, 24), 1));

    update public.fuel_price_source_cache c
       set status = p_status,
           normalized_summary = p_normalized_summary,
           limitation_codes = v_codes,
           source_label = nullif(btrim(coalesce(p_source_label, '')), ''),
           effective_date = p_effective_date,
           source_metadata = p_source_metadata,
           failure_code = null,
           fetched_at = now(),
           ttl_until = now() + v_ttl,
           updated_at = now()
     where c.cache_key = p_cache_key
       and c.source_id = v_job.source_id;

    if not found then
        raise exception 'complete_fuel_price_fetch_job_success: cache row missing'
            using errcode = 'P0002';
    end if;

    update public.fuel_price_fetch_jobs j
       set status = 'succeeded',
           completed_at = now(),
           last_error_safe = null,
           updated_at = now()
     where j.id = p_job_id;
end;
$$;

------------------------------------------------------------------------------
-- 8 — complete_fuel_price_fetch_job_failure
------------------------------------------------------------------------------

create or replace function public.complete_fuel_price_fetch_job_failure(
    p_job_id uuid,
    p_error_message text,
    p_failure_code text default null,
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
    v_failure_code text;
begin
    if p_job_id is null then
        raise exception 'complete_fuel_price_fetch_job_failure: job_id required'
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
    v_failure_code := nullif(
        left(
            trim(
                regexp_replace(
                    coalesce(p_failure_code, ''),
                    '[^a-z0-9_]',
                    '',
                    'gi'
                )
            ),
            64
        ),
        ''
    );

    select j.id, j.cache_key, j.attempts, j.max_attempts
      into strict v_job
      from public.fuel_price_fetch_jobs j
     where j.id = p_job_id
       and j.status = 'processing'
     for update;

    if p_retryable and v_job.attempts < v_job.max_attempts then
        update public.fuel_price_fetch_jobs j
           set status = 'queued',
               last_error_safe = nullif(v_err, ''),
               claimed_at = null,
               updated_at = now()
         where j.id = p_job_id;
    else
        update public.fuel_price_fetch_jobs j
           set status = 'dead',
               last_error_safe = nullif(v_err, ''),
               completed_at = now(),
               updated_at = now()
         where j.id = p_job_id;

        update public.fuel_price_source_cache c
           set status = case
                   when c.status in ('succeeded', 'partial', 'stale')
                        and c.normalized_summary <> '{}'::jsonb
                       then 'stale'
                   else 'failed'
               end,
               failure_code = coalesce(v_failure_code, c.failure_code),
               updated_at = now()
         where c.cache_key = v_job.cache_key
           and (
               c.status in ('pending', 'stale', 'failed')
               or (
                   c.status in ('succeeded', 'partial')
                   and c.normalized_summary <> '{}'::jsonb
               )
           );
    end if;
end;
$$;

------------------------------------------------------------------------------
-- 9 — get_fuel_prices_for_app (public buyer RPC)
------------------------------------------------------------------------------

create or replace function public.get_fuel_prices_for_app()
returns table (snapshot jsonb)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_cache record;
    v_items jsonb;
    v_public_status text;
    v_is_stale boolean;
    v_currency text;
    v_effective_date text;
begin
    for v_cache in
        select c.*
          from public.fuel_price_source_cache c
         where c.territory in ('moldova', 'pmr')
         order by case c.territory when 'moldova' then 1 else 2 end
    loop
        v_items := coalesce(v_cache.normalized_summary->'items', '[]'::jsonb);
        if jsonb_typeof(v_items) <> 'array' then
            v_items := '[]'::jsonb;
        end if;

        v_is_stale := (
            v_cache.ttl_until is not null and v_cache.ttl_until <= now()
        ) or v_cache.status = 'stale';

        v_public_status := case
            when v_cache.status in ('succeeded', 'partial')
                 and jsonb_array_length(v_items) >= 1
                then v_cache.status
            when v_cache.status in ('succeeded', 'partial', 'stale', 'failed')
                 and jsonb_array_length(v_items) >= 1
                then case when v_is_stale then 'partial' else 'succeeded' end
            else 'unavailable'
        end;

        if v_public_status = 'unavailable' then
            snapshot := jsonb_strip_nulls(
                jsonb_build_object(
                    'territory', v_cache.territory,
                    'status', 'unavailable',
                    'is_stale', false,
                    'source_label', coalesce(
                        nullif(btrim(v_cache.source_label), ''),
                        case v_cache.territory
                            when 'moldova' then 'ANRE · e-Carburanți'
                            when 'pmr' then 'Sheriff'
                            else null
                        end
                    ),
                    'effective_date', null,
                    'fetched_at', case
                        when v_cache.fetched_at is null then null
                        else to_char(
                            v_cache.fetched_at at time zone 'utc',
                            'YYYY-MM-DD"T"HH24:MI:SS"Z"'
                        )
                    end,
                    'currency', case v_cache.territory
                        when 'moldova' then 'MDL'
                        when 'pmr' then 'PMR_RUB'
                        else null
                    end,
                    'unit', 'liter',
                    'items', '[]'::jsonb,
                    'limitation_codes', public.carzon_fuel_price_default_limitation_codes(
                        v_cache.territory
                    )
                )
            );
            return next;
            continue;
        end if;

        v_currency := case v_cache.territory
            when 'moldova' then 'MDL'
            when 'pmr' then 'PMR_RUB'
            else null
        end;

        v_effective_date := case
            when v_cache.effective_date is null then null
            else to_char(v_cache.effective_date, 'YYYY-MM-DD')
        end;

        snapshot := jsonb_strip_nulls(
            jsonb_build_object(
                'territory', v_cache.territory,
                'status', v_public_status,
                'is_stale', v_is_stale,
                'source_label', coalesce(
                    nullif(btrim(v_cache.source_label), ''),
                    case v_cache.territory
                        when 'moldova' then 'ANRE · e-Carburanți'
                        when 'pmr' then 'Sheriff'
                        else null
                    end
                ),
                'effective_date', v_effective_date,
                'fetched_at', case
                    when v_cache.fetched_at is null then null
                    else to_char(
                        v_cache.fetched_at at time zone 'utc',
                        'YYYY-MM-DD"T"HH24:MI:SS"Z"'
                    )
                end,
                'currency', v_currency,
                'unit', 'liter',
                'items', (
                    select coalesce(
                        jsonb_agg(
                            jsonb_strip_nulls(
                                jsonb_build_object(
                                    'fuel_code', nullif(
                                        btrim(elem->>'fuel_code'),
                                        ''
                                    ),
                                    'price', (elem->>'price')::numeric
                                )
                            )
                        ),
                        '[]'::jsonb
                    )
                    from jsonb_array_elements(v_items) elem
                    where nullif(btrim(elem->>'fuel_code'), '') is not null
                      and (elem->>'price') ~ '^[0-9]+(\.[0-9]+)?$'
                ),
                'limitation_codes', case
                    when coalesce(array_length(v_cache.limitation_codes, 1), 0) >= 1
                        then to_jsonb(v_cache.limitation_codes)
                    else to_jsonb(
                        public.carzon_fuel_price_default_limitation_codes(
                            v_cache.territory
                        )
                    )
                end
            )
        );

        return next;
    end loop;
end;
$$;

comment on function public.get_fuel_prices_for_app() is
    'Fuel Prices v1: public territory snapshots with allowlisted fields only.';

grant execute on function public.get_fuel_prices_for_app() to anon, authenticated;

revoke all on function public.claim_fuel_price_fetch_jobs_for_processing(integer) from public;
revoke all on function public.claim_fuel_price_fetch_jobs_for_processing(integer) from anon;
revoke all on function public.claim_fuel_price_fetch_jobs_for_processing(integer) from authenticated;
grant execute on function public.claim_fuel_price_fetch_jobs_for_processing(integer) to service_role;

revoke all on function public.complete_fuel_price_fetch_job_success(
    uuid, text, text, jsonb, text[], text, date, text, jsonb, integer
) from public;
revoke all on function public.complete_fuel_price_fetch_job_success(
    uuid, text, text, jsonb, text[], text, date, text, jsonb, integer
) from anon;
revoke all on function public.complete_fuel_price_fetch_job_success(
    uuid, text, text, jsonb, text[], text, date, text, jsonb, integer
) from authenticated;
grant execute on function public.complete_fuel_price_fetch_job_success(
    uuid, text, text, jsonb, text[], text, date, text, jsonb, integer
) to service_role;

revoke all on function public.complete_fuel_price_fetch_job_failure(
    uuid, text, text, boolean
) from public;
revoke all on function public.complete_fuel_price_fetch_job_failure(
    uuid, text, text, boolean
) from anon;
revoke all on function public.complete_fuel_price_fetch_job_failure(
    uuid, text, text, boolean
) from authenticated;
grant execute on function public.complete_fuel_price_fetch_job_failure(
    uuid, text, text, boolean
) to service_role;
