-- Carzon — Manual Smart Fill v1.1: TGK transmission enrichment.
--
-- Official mapping: EU IVI Data Dictionary 1.11 (2025-04-02) GearboxTypeCode,
-- monitored by RDW. Source: Open Data RDW TGK Versnelling Uitvoering 7rjk-eycs (CC0).
--
-- Does not mutate public.listings.
-- Does not open drivetrain. Keeps vehicle_open_data_configuration_m1_drive_null_chk.
-- Axle inference is out of scope.
-- Does not edit the applied M1 migration body.

------------------------------------------------------------------------------
-- 1. Mapping version (resolver reports m1.1; existing rows stay until TGK merge)
------------------------------------------------------------------------------

create or replace function public.carzon_open_data_mapping_version()
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select 'm1.1'::text;
$$;

------------------------------------------------------------------------------
-- 2. Schema: open transmission taxonomy, keep drivetrain null-only
------------------------------------------------------------------------------

alter table public.vehicle_open_data_configuration
    drop constraint if exists vehicle_open_data_configuration_m1_trans_null_chk;

alter table public.vehicle_open_data_configuration
    drop constraint if exists vehicle_open_data_configuration_transmission_chk;

alter table public.vehicle_open_data_configuration
    add constraint vehicle_open_data_configuration_transmission_chk
        check (
            transmission_type is null
            or transmission_type in (
                'manual',
                'automatic',
                'cvt',
                'robotic',
                'dual_clutch',
                'other'
            )
        );

comment on column public.vehicle_open_data_configuration.transmission_type is
    'Optional TGK GearboxTypeCode mapped to listing taxonomy. '
    'M/A/C/D/G/O only. F/H/S/W stay null. Drivetrain remains unused.';

alter table public.vehicle_open_data_import_batch
    drop constraint if exists vehicle_open_data_import_batch_source_chk;

alter table public.vehicle_open_data_import_batch
    add constraint vehicle_open_data_import_batch_source_chk
        check (source in ('eea', 'rdw', 'vehiclesdb', 'curated', 'rdw_tgk_versnelling'));

create index if not exists vehicle_open_data_configuration_tan_vv_norm_idx
    on public.vehicle_open_data_configuration (
        tan_base,
        (lower(btrim(variant_code))),
        (lower(btrim(version_code)))
    )
    where tan_base is not null;

------------------------------------------------------------------------------
-- 3. Official GearboxTypeCode → CARZON taxonomy
------------------------------------------------------------------------------

create or replace function public.carzon_open_data_map_tgk_gearbox(p_code text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case upper(btrim(coalesce(p_code, '')))
    when 'M' then 'manual'
    when 'A' then 'automatic'
    when 'C' then 'cvt'
    when 'D' then 'dual_clutch'
    when 'G' then 'robotic'
    when 'O' then 'other'
    else null
  end;
$$;

comment on function public.carzon_open_data_map_tgk_gearbox(text) is
    'IVI GearboxTypeCode → listing transmission_type. '
    'F/H/S/W and unknown codes return null.';

------------------------------------------------------------------------------
-- 4. Chunked TGK merge (service_role). Updates existing configs only.
------------------------------------------------------------------------------

create or replace function public.carzon_open_data_upsert_tgk_transmissions(
    p_batch_id uuid,
    p_rows jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
set statement_timeout = '60s'
as $$
declare
    v_n integer := 0;
begin
    if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
        raise exception 'p_rows must be a JSON array' using errcode = '22023';
    end if;

    with src as (
        select
            public.carzon_open_data_normalize_tan_base(
                coalesce(r->>'tan_base', r->>'tan')
            ) as tan_base,
            lower(btrim(coalesce(r->>'variant_code', r->>'variant', ''))) as variant_code,
            lower(btrim(coalesce(r->>'version_code', r->>'version', ''))) as version_code,
            nullif(btrim(coalesce(r->>'transmission_type', '')), '') as transmission_type,
            left(btrim(coalesce(r->>'raw', '')), 32) as raw
          from jsonb_array_elements(p_rows) r
    ),
    clean as (
        select
            tan_base,
            variant_code,
            version_code,
            case
                when transmission_type in (
                    'manual', 'automatic', 'cvt', 'robotic', 'dual_clutch', 'other'
                ) then transmission_type
                else null
            end as transmission_type,
            raw
          from src
         where tan_base is not null
           and variant_code <> ''
           and version_code <> ''
    )
    update public.vehicle_open_data_configuration c
       set transmission_type = clean.transmission_type,
           field_lineage = coalesce(c.field_lineage, '{}'::jsonb)
               || jsonb_build_object(
                    'transmission',
                    jsonb_build_object(
                        'source', 'rdw_tgk_versnelling',
                        'evidence', 'JOINED',
                        'raw', clean.raw
                    )
               ),
           mapping_version = 'm1.1',
           import_batch_id = p_batch_id,
           updated_at = now()
      from clean
     where c.tan_base = clean.tan_base
       and lower(btrim(c.variant_code)) = clean.variant_code
       and lower(btrim(c.version_code)) = clean.version_code
       and c.drivetrain is null;

    get diagnostics v_n = row_count;
    return v_n;
end;
$$;

comment on function public.carzon_open_data_upsert_tgk_transmissions(uuid, jsonb) is
    'Service-role TGK transmission merge. Matches tan_base+variant+version. '
    'Does not insert configurations or write drivetrain.';

------------------------------------------------------------------------------
-- 5. Resolver: transmission consensus + clarification. Drivetrain stays null.
------------------------------------------------------------------------------

create or replace function public.resolve_vehicle_by_identity(
    p_make text,
    p_model text,
    p_year integer,
    p_answer jsonb default null
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
    v_mmy_rdw_distinct integer := 0;
    v_attr text;
    v_value text;
    v_candidate_count integer := 0;
    v_body_cons text;
    v_fuel_cons text;
    v_trans_cons text;
    v_displ_cons integer;
    v_power_cons integer;
    v_body_opts jsonb;
    v_fuel_opts jsonb;
    v_trans_opts jsonb;
    v_clarification jsonb := null;
    v_confidence text;
    v_status text := 'ok';
begin
    if p_year is null or p_year < 1900 or p_year > 2100 then
        return jsonb_build_object(
            'status', 'noData',
            'mappingVersion', public.carzon_open_data_mapping_version(),
            'identity', jsonb_build_object(
                'makeKey', null,
                'modelKey', null,
                'year', p_year,
                'yearTolerance', 1,
                'yearEvidence', 'registration_window'
            ),
            'consensusSpecs', jsonb_build_object(
                'bodyType', null,
                'fuelType', null,
                'engineDisplacementLiters', null,
                'enginePowerHp', null,
                'transmissionType', null,
                'drivetrain', null
            ),
            'candidateCount', 0,
            'confidence', 'none'
        );
    end if;

    select * into v_keys
      from public.carzon_open_data_resolve_identity_keys(p_make, p_model);
    if v_keys.make_key is null then
        return jsonb_build_object(
            'status', 'noData',
            'mappingVersion', public.carzon_open_data_mapping_version(),
            'identity', jsonb_build_object(
                'makeKey', null,
                'modelKey', null,
                'year', p_year,
                'yearTolerance', 1,
                'yearEvidence', 'registration_window'
            ),
            'consensusSpecs', jsonb_build_object(
                'bodyType', null,
                'fuelType', null,
                'engineDisplacementLiters', null,
                'enginePowerHp', null,
                'transmissionType', null,
                'drivetrain', null
            ),
            'candidateCount', 0,
            'confidence', 'none'
        );
    end if;

    select n.body_types
      into v_nameplate
      from public.vehicle_nameplate_identity n
     where n.make_key = v_keys.make_key
       and n.model_key = v_keys.model_key;

    v_nameplate := coalesce(v_nameplate, '{}');

    select count(distinct c.body_type_rdw)
      into v_mmy_rdw_distinct
      from public.vehicle_open_data_configuration c
     where c.make_key = v_keys.make_key
       and c.model_key = v_keys.model_key
       and c.year_min - 1 <= p_year
       and c.year_max + 1 >= p_year
       and c.body_type_rdw is not null;

    v_attr := lower(btrim(coalesce(p_answer->>'attribute', '')));
    v_value := lower(btrim(coalesce(p_answer->>'value', '')));
    if v_attr not in ('body', 'fuel', 'transmission') or v_value = '' then
        v_attr := null;
        v_value := null;
    end if;

    with base as (
        select
            c.*,
            case
                when coalesce(array_length(v_nameplate, 1), 0) = 1
                    then v_nameplate[1]
                when v_mmy_rdw_distinct >= 2
                    then c.body_type_rdw
                else null
            end as resolved_body
          from public.vehicle_open_data_configuration c
         where c.make_key = v_keys.make_key
           and c.model_key = v_keys.model_key
           and c.year_min - 1 <= p_year
           and c.year_max + 1 >= p_year
    ),
    filtered as (
        select *
          from base
         where v_attr is null
            or (v_attr = 'fuel' and fuel_type = v_value)
            or (v_attr = 'transmission' and transmission_type = v_value)
            or (v_attr = 'body' and resolved_body = v_value)
            or (
                v_attr = 'body'
                and resolved_body is null
                and v_value = any(v_nameplate)
            )
    ),
    counted as (
        select
            count(*)::integer as n,
            case
                when count(*) = 0 then null
                when count(*) filter (where resolved_body is null) = 0
                 and count(distinct resolved_body) = 1
                    then min(resolved_body)
                else null
            end as body_cons,
            case
                when count(*) = 0 then null
                when count(*) filter (where fuel_type is null) = 0
                 and count(distinct fuel_type) = 1
                    then min(fuel_type)
                else null
            end as fuel_cons,
            case
                when count(*) = 0 then null
                when count(*) filter (where transmission_type is null) = 0
                 and count(distinct transmission_type) = 1
                    then min(transmission_type)
                else null
            end as trans_cons,
            case
                when count(*) = 0 then null
                when count(*) filter (where engine_displacement_cm3 is null) = 0
                 and count(distinct engine_displacement_cm3) = 1
                    then min(engine_displacement_cm3)
                else null
            end as displ_cons,
            case
                when count(*) = 0 then null
                when count(*) filter (where power_kw is null) = 0
                 and count(distinct power_kw) = 1
                    then min(power_kw)
                else null
            end as power_cons
          from filtered
    ),
    body_opt as (
        select jsonb_agg(
                   jsonb_build_object(
                       'value', x.value,
                       'candidateCount', x.n
                   )
                   order by x.n desc, x.value
               ) as opts
          from (
            select resolved_body as value, count(*)::integer as n
              from filtered
             where resolved_body is not null
             group by resolved_body
          ) x
    ),
    nameplate_opt as (
        select jsonb_agg(
                   jsonb_build_object(
                       'value', b,
                       'candidateCount', null
                   )
                   order by b
               ) as opts
          from unnest(v_nameplate) as b
    ),
    fuel_opt as (
        select jsonb_agg(
                   jsonb_build_object(
                       'value', x.value,
                       'candidateCount', x.n
                   )
                   order by x.n desc, x.value
               ) as opts
          from (
            select fuel_type as value, count(*)::integer as n
              from filtered
             where fuel_type is not null
             group by fuel_type
          ) x
    ),
    trans_opt as (
        select jsonb_agg(
                   jsonb_build_object(
                       'value', x.value,
                       'candidateCount', x.n
                   )
                   order by x.n desc, x.value
               ) as opts
          from (
            select transmission_type as value, count(*)::integer as n
              from filtered
             where transmission_type in (
                 'manual', 'automatic', 'cvt', 'dual_clutch', 'robotic'
             )
             group by transmission_type
          ) x
    )
    select
        c.n,
        c.body_cons,
        c.fuel_cons,
        c.trans_cons,
        c.displ_cons,
        c.power_cons,
        coalesce(b.opts, np.opts),
        f.opts,
        t.opts
      into
        v_candidate_count,
        v_body_cons,
        v_fuel_cons,
        v_trans_cons,
        v_displ_cons,
        v_power_cons,
        v_body_opts,
        v_fuel_opts,
        v_trans_opts
      from counted c
      left join body_opt b on true
      left join nameplate_opt np on true
      left join fuel_opt f on true
      left join trans_opt t on true;

    if coalesce(v_candidate_count, 0) = 0 then
        v_status := 'noData';
        v_confidence := 'none';
        v_clarification := null;
        v_body_cons := null;
        v_fuel_cons := null;
        v_trans_cons := null;
        v_displ_cons := null;
        v_power_cons := null;
    else
        if v_attr = 'body' then
            v_body_cons := v_value;
        elsif v_attr = 'fuel' then
            v_fuel_cons := v_value;
        elsif v_attr = 'transmission' then
            v_trans_cons := v_value;
        end if;

        if v_attr is null then
            if v_body_cons is null
               and v_body_opts is not null
               and jsonb_array_length(v_body_opts) between 2 and 5
            then
                v_clarification := jsonb_build_object(
                    'attribute', 'body',
                    'options', v_body_opts
                );
            elsif v_fuel_cons is null
               and v_fuel_opts is not null
               and jsonb_array_length(v_fuel_opts) between 2 and 5
            then
                v_clarification := jsonb_build_object(
                    'attribute', 'fuel',
                    'options', v_fuel_opts
                );
            elsif v_trans_cons is null
               and v_trans_opts is not null
               and jsonb_array_length(v_trans_opts) between 2 and 5
            then
                v_clarification := jsonb_build_object(
                    'attribute', 'transmission',
                    'options', v_trans_opts
                );
            end if;
        end if;

        if v_body_cons is not null
           or v_fuel_cons is not null
           or v_trans_cons is not null
           or v_displ_cons is not null
           or v_power_cons is not null
        then
            if v_clarification is null then
                v_confidence := 'high';
            else
                v_confidence := 'partial';
            end if;
        elsif v_clarification is not null then
            v_confidence := 'partial';
        else
            v_confidence := 'low';
        end if;
    end if;

    return jsonb_build_object(
        'status', v_status,
        'mappingVersion', public.carzon_open_data_mapping_version(),
        'identity', jsonb_build_object(
            'makeKey', v_keys.make_key,
            'modelKey', v_keys.model_key,
            'year', p_year,
            'yearTolerance', 1,
            'yearEvidence', 'registration_window'
        ),
        'consensusSpecs', jsonb_build_object(
            'bodyType', v_body_cons,
            'fuelType', v_fuel_cons,
            'engineDisplacementLiters',
                public.carzon_open_data_cm3_to_liters(v_displ_cons),
            'enginePowerHp', public.carzon_open_data_kw_to_hp(v_power_cons),
            'transmissionType', v_trans_cons,
            'drivetrain', null
        ),
        'candidateCount', coalesce(v_candidate_count, 0),
        'clarification', v_clarification,
        'confidence', v_confidence
    );
end;
$$;

comment on function public.resolve_vehicle_by_identity(text, text, integer, jsonb) is
    'Read-only Manual Smart Fill MMY resolver. CARZON taxonomy only. '
    'Transmission uses all-equal consensus. Drivetrain is always null. '
    'Does not write listings or VIN state.';

------------------------------------------------------------------------------
-- 6. Privileges
------------------------------------------------------------------------------

revoke all on function public.carzon_open_data_map_tgk_gearbox(text) from public;
revoke all on function public.carzon_open_data_upsert_tgk_transmissions(uuid, jsonb)
    from public;
revoke all on function public.carzon_open_data_map_tgk_gearbox(text)
    from anon, authenticated;
revoke all on function public.carzon_open_data_upsert_tgk_transmissions(uuid, jsonb)
    from anon, authenticated;

grant execute on function public.carzon_open_data_upsert_tgk_transmissions(uuid, jsonb)
    to service_role;

revoke all on function public.resolve_vehicle_by_identity(text, text, integer, jsonb)
    from public;
revoke all on function public.resolve_vehicle_by_identity(text, text, integer, jsonb)
    from anon;
grant execute on function public.resolve_vehicle_by_identity(text, text, integer, jsonb)
    to authenticated;
