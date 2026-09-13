-- Carzon — Manual Smart Fill v2: terminal transmission after the normal
-- 3-decision budget. Mapping version stays m1.2. V1 untouched.
-- Does not alter catalog tables, listings, or ingest data.
--
-- Replaces public.resolve_vehicle_by_identity_v2 only. Helpers are
-- recreated identically so a later hosted apply can also heal the known
-- apply-path drift on the original V2 function body.

------------------------------------------------------------------------------
-- Helpers (internal; not granted to clients)
------------------------------------------------------------------------------

create or replace function public.carzon_open_data_mapping_version_v2()
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select 'm1.2'::text;
$$;

-- Seller-facing liters: 999 cm³ → 1.0, never 0.999.
create or replace function public.carzon_open_data_seller_liters(p_cm3 integer)
returns numeric
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case
    when p_cm3 is null or p_cm3 <= 0 then null
    else round(p_cm3::numeric / 1000.0, 1)
  end;
$$;

create or replace function public.carzon_open_data_v2_option_id(
    p_make_key text,
    p_model_key text,
    p_year integer,
    p_kind text,
    p_payload text
)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select md5(
    public.carzon_open_data_mapping_version_v2()
      || '|' || coalesce(p_make_key, '')
      || '|' || coalesce(p_model_key, '')
      || '|' || coalesce(p_year::text, '')
      || '|' || coalesce(p_kind, '')
      || '|' || coalesce(p_payload, '')
  );
$$;

------------------------------------------------------------------------------
-- V2 resolver
------------------------------------------------------------------------------

create or replace function public.resolve_vehicle_by_identity_v2(
    p_make text,
    p_model text,
    p_year integer,
    p_refinement jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_keys record;
    v_nameplate text[];
    v_refinement jsonb;
    v_answers jsonb;
    v_skipped jsonb;
    v_answer jsonb;
    v_kind text;
    v_option_id text;
    v_payload text;
    v_cands jsonb := '[]'::jsonb;
    v_selected jsonb := '[]'::jsonb;
    v_options jsonb;
    v_matched jsonb;
    v_next jsonb := null;
    v_status text := 'ok';
    v_confidence text := 'none';
    v_n integer := 0;
    v_body_cons text;
    v_fuel_cons text;
    v_trans_cons text;
    v_displ_cons numeric;
    v_power_cons integer;
    v_body_n integer;
    v_fuel_n integer;
    v_engine_n integer;
    v_trans_n integer;
    v_all_electric boolean;
    v_mixed_electric boolean;
    v_answered text[] := '{}';
    v_skipped_kinds text[] := '{}';
    v_decisions integer := 0;
    v_seen text[] := '{}';
    v_valid_kinds text[] := array['body', 'fuel', 'engine', 'transmission'];
begin
    v_refinement := case
        when p_refinement is null or jsonb_typeof(p_refinement) <> 'object'
            then '{}'::jsonb
        else p_refinement
    end;
    v_answers := coalesce(v_refinement->'answers', '[]'::jsonb);
    v_skipped := coalesce(v_refinement->'skippedKinds', '[]'::jsonb);

    if jsonb_typeof(v_answers) <> 'array' or jsonb_typeof(v_skipped) <> 'array' then
        return public.carzon_open_data_v2_payload(
            'invalidRefinement', null, null, p_year, '[]'::jsonb,
            null, null, null, null, null, 0, null, '[]'::jsonb, '[]'::jsonb, 'none'
        );
    end if;

    if p_year is null or p_year < 1900 or p_year > 2100 then
        return public.carzon_open_data_v2_payload(
            'noData', null, null, p_year, v_answers, v_skipped,
            null, null, null, null, null, 0, null, v_answers, v_skipped, 'none'
        );
    end if;

    select * into v_keys
      from public.carzon_open_data_resolve_identity_keys(p_make, p_model);
    if v_keys.make_key is null then
        return public.carzon_open_data_v2_payload(
            'noData', null, null, p_year, v_answers, v_skipped,
            null, null, null, null, null, 0, null, v_answers, v_skipped, 'none'
        );
    end if;

    select n.body_types
      into v_nameplate
      from public.vehicle_nameplate_identity n
     where n.make_key = v_keys.make_key
       and n.model_key = v_keys.model_key;
    v_nameplate := coalesce(v_nameplate, '{}');

    -- Validate answers / skips before touching candidates.
    for v_answer in
        select value from jsonb_array_elements(v_answers)
    loop
        if jsonb_typeof(v_answer) <> 'object' then
            v_status := 'invalidRefinement';
            exit;
        end if;
        v_kind := lower(btrim(coalesce(v_answer->>'kind', '')));
        v_option_id := btrim(coalesce(v_answer->>'optionId', ''));
        if v_kind <> all(v_valid_kinds) or v_option_id = '' then
            v_status := 'invalidRefinement';
            exit;
        end if;
        if v_kind = any(v_seen) then
            v_status := 'invalidRefinement';
            exit;
        end if;
        v_seen := v_seen || v_kind;
        v_answered := v_answered || v_kind;
        v_decisions := v_decisions + 1;
    end loop;

    if v_status <> 'invalidRefinement' then
        for v_payload in
            select lower(btrim(coalesce(value #>> '{}', '')))
              from jsonb_array_elements(v_skipped)
        loop
            if v_payload <> all(v_valid_kinds) then
                v_status := 'invalidRefinement';
                exit;
            end if;
            if v_payload = any(v_seen) then
                v_status := 'invalidRefinement';
                exit;
            end if;
            v_seen := v_seen || v_payload;
            v_skipped_kinds := v_skipped_kinds || v_payload;
            v_decisions := v_decisions + 1;
        end loop;
    end if;

    if v_status = 'invalidRefinement' or v_decisions > 4 then
        return public.carzon_open_data_v2_payload(
            'invalidRefinement', v_keys.make_key, v_keys.model_key, p_year,
            v_answers, v_skipped,
            null, null, null, null, null, 0, null, v_answers, v_skipped, 'none'
        );
    end if;

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'body', c.body_type_rdw,
                'fuel', c.fuel_type,
                'cm3', c.engine_displacement_cm3,
                'kw', c.power_kw,
                'trans', c.transmission_type
            )
        ),
        '[]'::jsonb
    )
      into v_cands
      from public.vehicle_open_data_configuration c
     where c.make_key = v_keys.make_key
       and c.model_key = v_keys.model_key
       and c.year_min - 1 <= p_year
       and c.year_max + 1 >= p_year;

    -- Replay answers in order against the current subset.
    for v_answer in
        select value from jsonb_array_elements(v_answers)
    loop
        v_kind := lower(btrim(v_answer->>'kind'));
        v_option_id := btrim(v_answer->>'optionId');
        v_options := public.carzon_open_data_v2_options(
            v_cands, v_kind, v_keys.make_key, v_keys.model_key, p_year
        );
        select value
          into v_matched
          from jsonb_array_elements(coalesce(v_options, '[]'::jsonb)) e
         where e->>'id' = v_option_id
         limit 1;
        if v_matched is null then
            return public.carzon_open_data_v2_payload(
                'invalidRefinement', v_keys.make_key, v_keys.model_key, p_year,
                v_answers, v_skipped,
                null, null, null, null, null, 0, null, v_answers, v_skipped, 'none'
            );
        end if;
        v_cands := public.carzon_open_data_v2_filter(
            v_cands, v_kind, v_matched
        );
        v_selected := v_selected || jsonb_build_array(
            v_matched || jsonb_build_object('kind', v_kind)
        );
    end loop;

    v_n := coalesce(jsonb_array_length(v_cands), 0);
    if v_n = 0 then
        return public.carzon_open_data_v2_payload(
            'noData', v_keys.make_key, v_keys.model_key, p_year,
            v_answers, v_skipped,
            null, null, null, null, null, 0, null, v_answers, v_skipped, 'none'
        );
    end if;

    -- Strict consensus on the current subset, then overlay selected option values.
    select
        case
            when count(*) filter (where nullif(e->>'body', '') is null) = 0
             and count(distinct e->>'body') = 1
                then min(e->>'body')
        end,
        case
            when count(*) filter (where nullif(e->>'fuel', '') is null) = 0
             and count(distinct e->>'fuel') = 1
                then min(e->>'fuel')
        end,
        case
            when count(*) filter (
                    where public.carzon_open_data_seller_liters((e->>'cm3')::integer) is null
                 ) = 0
             and count(distinct public.carzon_open_data_seller_liters((e->>'cm3')::integer)) = 1
                then min(public.carzon_open_data_seller_liters((e->>'cm3')::integer))
        end,
        case
            when count(*) filter (
                    where public.carzon_open_data_kw_to_hp((e->>'kw')::integer) is null
                 ) = 0
             and count(distinct public.carzon_open_data_kw_to_hp((e->>'kw')::integer)) = 1
                then min(public.carzon_open_data_kw_to_hp((e->>'kw')::integer))
        end,
        case
            when count(*) filter (where nullif(e->>'trans', '') is null) = 0
             and count(distinct e->>'trans') = 1
                then min(e->>'trans')
        end
      into v_body_cons, v_fuel_cons, v_displ_cons, v_power_cons, v_trans_cons
      from jsonb_array_elements(v_cands) e;

    -- Nameplate fallback only when every row lacks body evidence.
    if v_body_cons is null
       and not exists (
            select 1
              from jsonb_array_elements(v_cands) e
             where nullif(e->>'body', '') is not null
       )
       and coalesce(array_length(v_nameplate, 1), 0) = 1
    then
        v_body_cons := v_nameplate[1];
    end if;

    for v_matched in
        select value from jsonb_array_elements(v_selected)
    loop
        v_kind := v_matched->>'kind';
        if v_kind = 'body' then
            v_body_cons := coalesce(v_matched->>'bodyType', v_body_cons);
        elsif v_kind = 'fuel' then
            v_fuel_cons := coalesce(v_matched->>'fuelType', v_fuel_cons);
        elsif v_kind = 'engine' then
            v_fuel_cons := coalesce(v_matched->>'fuelType', v_fuel_cons);
            v_displ_cons := coalesce(
                (v_matched->>'engineDisplacementLiters')::numeric,
                v_displ_cons
            );
            v_power_cons := coalesce(
                (v_matched->>'enginePowerHp')::integer,
                v_power_cons
            );
        elsif v_kind = 'transmission' then
            v_trans_cons := coalesce(v_matched->>'transmissionType', v_trans_cons);
        end if;
    end loop;

    select
        count(distinct e->>'body')
            filter (where nullif(e->>'body', '') is not null
                and e->>'body' in (
                    'sedan', 'hatchback', 'wagon', 'suv', 'coupe',
                    'convertible', 'minivan', 'pickup', 'van'
                )),
        count(distinct e->>'fuel')
            filter (where nullif(e->>'fuel', '') is not null
                and e->>'fuel' in (
                    'petrol', 'diesel', 'hybrid', 'plug_in_hybrid',
                    'electric', 'lpg', 'cng'
                )),
        count(*) filter (
            where e->>'fuel' = 'electric'
        ) > 0
        and count(*) filter (
            where nullif(e->>'fuel', '') is not null
              and e->>'fuel' <> 'electric'
        ) = 0,
        count(*) filter (where e->>'fuel' = 'electric') > 0
        and count(*) filter (
            where nullif(e->>'fuel', '') is not null
              and e->>'fuel' <> 'electric'
        ) > 0
      into v_body_n, v_fuel_n, v_all_electric, v_mixed_electric
      from jsonb_array_elements(v_cands) e;

    select count(*)
      into v_engine_n
      from jsonb_array_elements(
          public.carzon_open_data_v2_options(
              v_cands, 'engine', v_keys.make_key, v_keys.model_key, p_year
          )
      );

    select count(distinct e->>'trans')
      into v_trans_n
      from jsonb_array_elements(v_cands) e
     where e->>'trans' in (
         'manual', 'automatic', 'cvt', 'dual_clutch', 'robotic'
     );

    if v_decisions < 3 then
        if 'body' <> all(v_answered) and 'body' <> all(v_skipped_kinds)
           and v_body_n between 2 and 5
        then
            v_next := jsonb_build_object(
                'kind', 'body',
                'allowUnknown', true,
                'options', public.carzon_open_data_v2_options(
                    v_cands, 'body', v_keys.make_key, v_keys.model_key, p_year
                )
            );
        elsif not v_all_electric
           and v_mixed_electric
           and 'fuel' <> all(v_answered) and 'fuel' <> all(v_skipped_kinds)
           and v_fuel_n between 2 and 5
        then
            v_next := jsonb_build_object(
                'kind', 'fuel',
                'allowUnknown', true,
                'options', public.carzon_open_data_v2_options(
                    v_cands, 'fuel', v_keys.make_key, v_keys.model_key, p_year
                )
            );
        elsif not v_all_electric
           and 'engine' <> all(v_answered) and 'engine' <> all(v_skipped_kinds)
           and v_engine_n between 2 and 8
        then
            v_next := jsonb_build_object(
                'kind', 'engine',
                'allowUnknown', true,
                'options', public.carzon_open_data_v2_options(
                    v_cands, 'engine', v_keys.make_key, v_keys.model_key, p_year
                )
            );
        elsif not v_all_electric
           and 'engine' <> all(v_answered) and 'engine' <> all(v_skipped_kinds)
           and v_engine_n > 8
           and 'fuel' <> all(v_answered) and 'fuel' <> all(v_skipped_kinds)
           and v_fuel_n between 2 and 5
        then
            v_next := jsonb_build_object(
                'kind', 'fuel',
                'allowUnknown', true,
                'options', public.carzon_open_data_v2_options(
                    v_cands, 'fuel', v_keys.make_key, v_keys.model_key, p_year
                )
            );
        elsif not v_all_electric
           and 'transmission' <> all(v_answered)
           and 'transmission' <> all(v_skipped_kinds)
           and v_trans_n between 2 and 5
        then
            v_next := jsonb_build_object(
                'kind', 'transmission',
                'allowUnknown', true,
                'options', public.carzon_open_data_v2_options(
                    v_cands, 'transmission', v_keys.make_key, v_keys.model_key, p_year
                )
            );
        end if;
    elsif v_decisions = 3
       and not v_all_electric
       and 'transmission' <> all(v_answered)
       and 'transmission' <> all(v_skipped_kinds)
       and v_trans_n between 2 and 5
    then
        -- One extra terminal transmission question only. Never a 4th
        -- body / fuel / engine prompt.
        v_next := jsonb_build_object(
            'kind', 'transmission',
            'allowUnknown', true,
            'options', public.carzon_open_data_v2_options(
                v_cands, 'transmission', v_keys.make_key, v_keys.model_key, p_year
            )
        );
    end if;

    if v_body_cons is not null
       or v_fuel_cons is not null
       or v_displ_cons is not null
       or v_power_cons is not null
       or v_trans_cons is not null
    then
        if v_next is null then
            v_confidence := 'high';
        else
            v_confidence := 'partial';
        end if;
    elsif v_next is not null then
        v_confidence := 'partial';
    else
        v_confidence := 'low';
    end if;

    return public.carzon_open_data_v2_payload(
        v_status,
        v_keys.make_key,
        v_keys.model_key,
        p_year,
        v_answers,
        v_skipped,
        v_body_cons,
        v_fuel_cons,
        v_displ_cons,
        v_power_cons,
        v_trans_cons,
        v_n,
        v_next,
        v_answers,
        v_skipped,
        v_confidence
    );
end;
$$;

create or replace function public.carzon_open_data_v2_options(
    p_cands jsonb,
    p_kind text,
    p_make_key text,
    p_model_key text,
    p_year integer
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
    v_out jsonb;
begin
    if p_kind = 'body' then
        select coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id', public.carzon_open_data_v2_option_id(
                        p_make_key, p_model_key, p_year, 'body', x.val
                    ),
                    'candidateCount', x.n,
                    'bodyType', x.val
                )
                order by x.n desc, x.val
            ),
            '[]'::jsonb
        )
          into v_out
          from (
            select e->>'body' as val, count(*)::integer as n
              from jsonb_array_elements(coalesce(p_cands, '[]'::jsonb)) e
             where e->>'body' in (
                 'sedan', 'hatchback', 'wagon', 'suv', 'coupe',
                 'convertible', 'minivan', 'pickup', 'van'
             )
             group by 1
          ) x;
        return v_out;
    end if;

    if p_kind = 'fuel' then
        select coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id', public.carzon_open_data_v2_option_id(
                        p_make_key, p_model_key, p_year, 'fuel', x.val
                    ),
                    'candidateCount', x.n,
                    'fuelType', x.val
                )
                order by x.n desc, x.val
            ),
            '[]'::jsonb
        )
          into v_out
          from (
            select e->>'fuel' as val, count(*)::integer as n
              from jsonb_array_elements(coalesce(p_cands, '[]'::jsonb)) e
             where e->>'fuel' in (
                 'petrol', 'diesel', 'hybrid', 'plug_in_hybrid',
                 'electric', 'lpg', 'cng'
             )
             group by 1
          ) x;
        return v_out;
    end if;

    if p_kind = 'engine' then
        select coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id', public.carzon_open_data_v2_option_id(
                        p_make_key, p_model_key, p_year, 'engine',
                        x.fuel || '|' || x.liters::text || '|' || x.hp::text
                    ),
                    'candidateCount', x.n,
                    'fuelType', x.fuel,
                    'engineDisplacementLiters', x.liters,
                    'enginePowerHp', x.hp
                )
                order by x.n desc, x.fuel, x.liters, x.hp
            ),
            '[]'::jsonb
        )
          into v_out
          from (
            select
                e->>'fuel' as fuel,
                public.carzon_open_data_seller_liters((e->>'cm3')::integer) as liters,
                public.carzon_open_data_kw_to_hp((e->>'kw')::integer) as hp,
                count(*)::integer as n
              from jsonb_array_elements(coalesce(p_cands, '[]'::jsonb)) e
             where e->>'fuel' in (
                 'petrol', 'diesel', 'hybrid', 'plug_in_hybrid', 'lpg', 'cng'
             )
               and public.carzon_open_data_seller_liters((e->>'cm3')::integer) is not null
               and public.carzon_open_data_kw_to_hp((e->>'kw')::integer) is not null
             group by 1, 2, 3
          ) x;
        return v_out;
    end if;

    if p_kind = 'transmission' then
        select coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id', public.carzon_open_data_v2_option_id(
                        p_make_key, p_model_key, p_year, 'transmission', x.val
                    ),
                    'candidateCount', x.n,
                    'transmissionType', x.val
                )
                order by x.n desc, x.val
            ),
            '[]'::jsonb
        )
          into v_out
          from (
            select e->>'trans' as val, count(*)::integer as n
              from jsonb_array_elements(coalesce(p_cands, '[]'::jsonb)) e
             where e->>'trans' in (
                 'manual', 'automatic', 'cvt', 'dual_clutch', 'robotic'
             )
             group by 1
          ) x;
        return v_out;
    end if;

    return '[]'::jsonb;
end;
$$;

create or replace function public.carzon_open_data_v2_filter(
    p_cands jsonb,
    p_kind text,
    p_option jsonb
)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select coalesce(jsonb_agg(e), '[]'::jsonb)
    from jsonb_array_elements(coalesce(p_cands, '[]'::jsonb)) e
   where case p_kind
        when 'body' then e->>'body' = p_option->>'bodyType'
        when 'fuel' then e->>'fuel' = p_option->>'fuelType'
        when 'engine' then
            e->>'fuel' = p_option->>'fuelType'
            and public.carzon_open_data_seller_liters((e->>'cm3')::integer)
                = (p_option->>'engineDisplacementLiters')::numeric
            and public.carzon_open_data_kw_to_hp((e->>'kw')::integer)
                = (p_option->>'enginePowerHp')::integer
        when 'transmission' then e->>'trans' = p_option->>'transmissionType'
        else false
     end;
$$;

create or replace function public.carzon_open_data_v2_payload(
    p_status text,
    p_make_key text,
    p_model_key text,
    p_year integer,
    p_answers_in jsonb,
    p_skipped_in jsonb,
    p_body text,
    p_fuel text,
    p_liters numeric,
    p_hp integer,
    p_trans text,
    p_count integer,
    p_next jsonb,
    p_answers_out jsonb,
    p_skipped_out jsonb,
    p_confidence text
)
returns jsonb
language sql
immutable
security invoker
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
      'status', p_status,
      'mappingVersion', public.carzon_open_data_mapping_version_v2(),
      'identity', jsonb_build_object(
          'makeKey', p_make_key,
          'modelKey', p_model_key,
          'year', p_year,
          'yearTolerance', 1,
          'yearEvidence', 'registration_window'
      ),
      'consensusSpecs', jsonb_build_object(
          'bodyType', p_body,
          'fuelType', p_fuel,
          'engineDisplacementLiters', p_liters,
          'enginePowerHp', p_hp,
          'transmissionType', p_trans,
          'drivetrain', null
      ),
      'candidateCount', coalesce(p_count, 0),
      'nextRefinement', p_next,
      'refinementState', jsonb_build_object(
          'answers', coalesce(p_answers_out, '[]'::jsonb),
          'skippedKinds', coalesce(p_skipped_out, '[]'::jsonb),
          'decisionsUsed',
              coalesce(jsonb_array_length(p_answers_out), 0)
              + coalesce(jsonb_array_length(p_skipped_out), 0),
          'maxDecisions', 3
      ),
      'confidence', p_confidence
  );
$$;

comment on function public.resolve_vehicle_by_identity_v2(text, text, integer, jsonb) is
    'Read-only Manual Smart Fill v2 progressive MMY resolver. '
    'Does not replace resolve_vehicle_by_identity. Drivetrain always null.';

revoke all on function public.carzon_open_data_mapping_version_v2() from public;
revoke all on function public.carzon_open_data_seller_liters(integer) from public;
revoke all on function public.carzon_open_data_v2_option_id(text, text, integer, text, text)
    from public;
revoke all on function public.carzon_open_data_v2_options(jsonb, text, text, text, integer)
    from public;
revoke all on function public.carzon_open_data_v2_filter(jsonb, text, jsonb) from public;
revoke all on function public.carzon_open_data_v2_payload(
    text, text, text, integer, jsonb, jsonb, text, text, numeric, integer, text,
    integer, jsonb, jsonb, jsonb, text
) from public;
revoke all on function public.resolve_vehicle_by_identity_v2(text, text, integer, jsonb)
    from public;

revoke all on function public.carzon_open_data_mapping_version_v2()
    from anon, authenticated;
revoke all on function public.carzon_open_data_seller_liters(integer)
    from anon, authenticated;
revoke all on function public.carzon_open_data_v2_option_id(text, text, integer, text, text)
    from anon, authenticated;
revoke all on function public.carzon_open_data_v2_options(jsonb, text, text, text, integer)
    from anon, authenticated;
revoke all on function public.carzon_open_data_v2_filter(jsonb, text, jsonb)
    from anon, authenticated;
revoke all on function public.carzon_open_data_v2_payload(
    text, text, text, integer, jsonb, jsonb, text, text, numeric, integer, text,
    integer, jsonb, jsonb, jsonb, text
) from anon, authenticated;
revoke all on function public.resolve_vehicle_by_identity_v2(text, text, integer, jsonb)
    from anon;

grant execute on function public.resolve_vehicle_by_identity_v2(text, text, integer, jsonb)
    to authenticated;
