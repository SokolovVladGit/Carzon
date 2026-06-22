-- Carzon — Fuel Prices v1: fix terminal job re-enqueue after TTL expiry.
--
-- Foundation migration used ON CONFLICT (idempotency_key) DO NOTHING, so a
-- succeeded/dead job blocked all future refreshes. This recreates
-- enqueue_fuel_price_fetch_if_needed to requeue terminal rows truthfully.

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
    v_existing_status text;
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

    select j.status
      into v_existing_status
      from public.fuel_price_fetch_jobs j
     where j.idempotency_key = v_idempotency_key;

    if v_existing_status in ('queued', 'processing') then
        return 'already_queued';
    end if;

    if v_existing_status is null then
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
        );

        return 'enqueued';
    end if;

    update public.fuel_price_fetch_jobs j
       set status = 'queued',
           attempts = 0,
           claimed_at = null,
           completed_at = null,
           last_error_safe = null,
           updated_at = now()
     where j.idempotency_key = v_idempotency_key
       and j.status in ('succeeded', 'failed', 'dead');

    if found then
        return 'requeued';
    end if;

    return 'skipped';
end;
$$;

comment on function public.enqueue_fuel_price_fetch_if_needed(text) is
    'Idempotently enqueues or requeues a fuel-price fetch job when cache is missing, stale, or failed. '
    'Terminal jobs (succeeded/failed/dead) reset to queued when refresh is needed. service_role only.';

revoke all on function public.enqueue_fuel_price_fetch_if_needed(text) from public;
revoke all on function public.enqueue_fuel_price_fetch_if_needed(text) from anon;
revoke all on function public.enqueue_fuel_price_fetch_if_needed(text) from authenticated;
grant execute on function public.enqueue_fuel_price_fetch_if_needed(text) to service_role;
