-- Carzon — Model Passport: optional listing_id on fetch jobs + VIN decode hints for EPA candidates.
--
-- * Worker may read buyer-safe VIN public_summary fields for the listing that enqueued the job.
-- * Never exposes plaintext VIN, hashed identifiers, listing_vehicle_identity, or source_metadata to clients.
-- * Cache remains keyed by seller make/model/year identity.

alter table public.vehicle_model_fetch_jobs
    add column if not exists listing_id uuid references public.listings (id) on delete set null;

create index if not exists vehicle_model_fetch_jobs_listing_id_idx
    on public.vehicle_model_fetch_jobs (listing_id)
    where listing_id is not null;

------------------------------------------------------------------------------
-- VIN hints for worker (service_role only)
------------------------------------------------------------------------------

create or replace function public.get_listing_vin_model_fetch_hints(p_listing_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_summary jsonb;
    v_year integer;
begin
    if p_listing_id is null then
        return null;
    end if;

    select r.normalized_summary
      into v_summary
      from public.listing_vin_source_results r
      join public.listings li on li.id = r.listing_id
     where r.listing_id = p_listing_id
       and li.status = 'active'
       and r.visibility = 'public_summary'
       and r.status = 'succeeded'
       and (r.ttl_until is null or r.ttl_until > now())
     order by r.updated_at desc
     limit 1;

    if v_summary is null or v_summary = '{}'::jsonb then
        return null;
    end if;

    begin
        v_year := nullif(btrim(v_summary->>'year'), '')::integer;
    exception
        when others then
            v_year := null;
    end;

    return jsonb_strip_nulls(
        jsonb_build_object(
            'make', nullif(btrim(v_summary->>'make'), ''),
            'model', nullif(btrim(v_summary->>'model'), ''),
            'year', v_year,
            'body_type', nullif(btrim(v_summary->>'body_type'), ''),
            'series', nullif(btrim(v_summary->>'series'), ''),
            'trim', nullif(btrim(v_summary->>'trim'), ''),
            'drive_type', nullif(btrim(v_summary->>'drive_type'), '')
        )
    );
end;
$$;

comment on function public.get_listing_vin_model_fetch_hints(uuid) is
    'Service-role only: allowlisted VIN decode fields for EPA model candidate generation. '
    'Never returns plaintext VIN, hashed identifiers, or source_metadata.';

revoke all on function public.get_listing_vin_model_fetch_hints(uuid) from public;
revoke all on function public.get_listing_vin_model_fetch_hints(uuid) from anon;
revoke all on function public.get_listing_vin_model_fetch_hints(uuid) from authenticated;
grant execute on function public.get_listing_vin_model_fetch_hints(uuid) to service_role;

------------------------------------------------------------------------------
-- enqueue_vehicle_model_fetch_if_needed (+ optional listing_id)
------------------------------------------------------------------------------

drop function if exists public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text);

create or replace function public.enqueue_vehicle_model_fetch_if_needed(
    p_make text,
    p_model text,
    p_year integer,
    p_source_id text default 'epa_fueleconomy',
    p_listing_id uuid default null
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
        listing_id,
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
        p_listing_id,
        'queued',
        0,
        3,
        v_idempotency_key,
        now(),
        now()
    )
    on conflict (idempotency_key) do update
        set listing_id = coalesce(
                public.vehicle_model_fetch_jobs.listing_id,
                excluded.listing_id
            ),
            updated_at = now();

    return 'enqueued';
end;
$$;

comment on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text, uuid) is
    'Idempotently upserts cache row and enqueues model-data fetch job for epa_fueleconomy only. '
    'Optional listing_id enables worker VIN decode hints for EPA candidate generation.';

revoke all on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text, uuid)
    from public;
revoke all on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text, uuid)
    from anon;
revoke all on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text, uuid)
    from authenticated;
grant execute on function public.enqueue_vehicle_model_fetch_if_needed(text, text, integer, text, uuid)
    to service_role;

------------------------------------------------------------------------------
-- claim_vehicle_model_fetch_jobs_for_processing (+ listing_id)
------------------------------------------------------------------------------

drop function if exists public.claim_vehicle_model_fetch_jobs_for_processing(integer);

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
    attempts integer,
    listing_id uuid
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
            j.attempts,
            j.listing_id
    )
    select
        u.id,
        u.cache_key,
        u.source_id,
        u.lookup_make,
        u.lookup_model,
        u.lookup_year,
        u.attempts,
        u.listing_id
      from upd u;
end;
$$;

comment on function public.claim_vehicle_model_fetch_jobs_for_processing(integer) is
    'Worker-only: atomically claims queued model fetch jobs. Returns listing_id when set on the job.';

revoke all on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)
    from public;
revoke all on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)
    from anon;
revoke all on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)
    from authenticated;
grant execute on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)
    to service_role;

------------------------------------------------------------------------------
-- get_listing_model_data_for_buyer: pass listing_id into enqueue
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
        'epa_fueleconomy',
        p_listing_id
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

notify pgrst, 'reload schema';
