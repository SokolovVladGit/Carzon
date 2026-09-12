-- Carzon — Manual Smart Fill M1: free/open-data configuration catalog + MMY resolver.
--
-- Separate from the VIN decode path.
-- Does not mutate public.listings.
-- Clients never read catalog tables; authenticated create-listing path uses
-- public.resolve_vehicle_by_identity only.
--
-- Sources: EEA CO2 cars (CC-BY 4.0, DG-CLIMA), RDW Open Data (CC0),
-- VehiclesDB identity layer (CC-BY 4.0). See docs/legal/open_vehicle_data_attribution.md.
-- Mapping version: m1.0
--
-- M1 may persist body/fuel/displacement/power only.
-- transmission_type and drivetrain stay null on this EU path.

------------------------------------------------------------------------------
-- 1. Internal helpers
------------------------------------------------------------------------------

create or replace function public.carzon_open_data_mapping_version()
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select 'm1.0'::text;
$$;

create or replace function public.carzon_open_data_fold_ascii(p_raw text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select nullif(
    translate(
      lower(btrim(coalesce(p_raw, ''))),
      'áàäâãåéèëêíìïîóòöôõúùüûýÿčćšžñř',
      'aaaaaaeeeeiiiiooooouuuuyyccsznr'
    ),
    ''
  );
$$;

create or replace function public.carzon_open_data_normalize_tan_base(p_tan text)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select nullif(
    regexp_replace(
      lower(regexp_replace(btrim(coalesce(p_tan, '')), '\s+', '', 'g')),
      '\*[0-9]{1,3}$',
      ''
    ),
    ''
  );
$$;

create or replace function public.carzon_open_data_configuration_key(
    p_type text,
    p_variant text,
    p_version text
)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select nullif(
    lower(btrim(coalesce(p_type, '')))
      || '|'
      || lower(btrim(coalesce(p_variant, '')))
      || '|'
      || lower(btrim(coalesce(p_version, ''))),
    '||'
  );
$$;

-- Conservative Ft+Fm → CARZON fuel. Bifuel / unknown → null.
create or replace function public.carzon_open_data_normalize_fuel(
    p_ft text,
    p_fm text
)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case
    when v_ft in ('electric') and v_fm in ('e', 'm', '') then 'electric'
    when v_ft in ('petrol/electric', 'diesel/electric') and v_fm = 'p'
      then 'plug_in_hybrid'
    when v_ft in ('petrol', 'diesel') and v_fm = 'h' then 'hybrid'
    when v_ft = 'petrol' and v_fm = 'm' then 'petrol'
    when v_ft = 'diesel' and v_fm = 'm' then 'diesel'
    when v_ft = 'lpg' and v_fm = 'm' then 'lpg'
    when v_ft in ('cng', 'ng') and v_fm = 'm' then 'cng'
    else null
  end
  from (
    select
      lower(btrim(coalesce(p_ft, ''))) as v_ft,
      lower(btrim(coalesce(p_fm, ''))) as v_fm
  ) s;
$$;

-- RDW EU body / inrichting → CARZON body. Caller must still apply safety rules.
create or replace function public.carzon_open_data_normalize_rdw_body(
    p_carrosserietype text,
    p_eu_description text,
    p_inrichting text
)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case
    when v_code = 'aa' then 'sedan'
    when v_code = 'ab' then 'hatchback'
    when v_code = 'ac' then 'wagon'
    when v_code = 'ad' then 'coupe'
    when v_code in ('ae', 'ag') then 'convertible'
    when v_code in ('af', 'sa') then 'minivan'
    when v_inl in ('sedan', 'limousine') then 'sedan'
    when v_inl in ('hatchback') then 'hatchback'
    when v_inl in (
        'wagon', 'stationwagen', 'stationwagen/combi'
    ) then 'wagon'
    when v_inl in ('suv') then 'suv'
    when v_inl in ('coupe', 'coupé') then 'coupe'
    when v_inl in ('cabriolet', 'cabrio', 'convertible', 'roadster') then 'convertible'
    when v_inl in ('mpv', 'minivan') then 'minivan'
    when v_inl in ('pick-up', 'pickup') then 'pickup'
    when v_inl in ('van') then 'van'
    when v_desc in ('sedan') then 'sedan'
    when v_desc in ('hatchback') then 'hatchback'
    when v_desc in ('stationwagen', 'wagon') then 'wagon'
    when v_desc in ('coupe', 'coupé') then 'coupe'
    when v_desc in ('cabriolet') then 'convertible'
    else null
  end
  from (
    select
      lower(btrim(coalesce(p_carrosserietype, ''))) as v_code,
      lower(btrim(coalesce(p_eu_description, ''))) as v_desc,
      lower(btrim(coalesce(p_inrichting, ''))) as v_inl
  ) s;
$$;

-- VehiclesDB nameplate vocabulary → CARZON body. Unknown → null.
create or replace function public.carzon_open_data_normalize_nameplate_body(
    p_body text
)
returns text
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case lower(btrim(coalesce(p_body, '')))
    when 'sedan' then 'sedan'
    when 'hatchback' then 'hatchback'
    when 'wagon' then 'wagon'
    when 'suv' then 'suv'
    when 'coupe' then 'coupe'
    when 'convertible' then 'convertible'
    when 'roadster' then 'convertible'
    when 'mpv' then 'minivan'
    when 'minivan' then 'minivan'
    when 'pickup' then 'pickup'
    when 'van' then 'van'
    else null
  end;
$$;

-- DIN PS used in EU listing copy. Catalog stores kW; conversion is display-only.
create or replace function public.carzon_open_data_kw_to_hp(p_kw integer)
returns integer
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case
    when p_kw is null or p_kw <= 0 then null
    else round(p_kw::numeric * 1.35962)::integer
  end;
$$;

create or replace function public.carzon_open_data_cm3_to_liters(p_cm3 integer)
returns numeric
language sql
immutable
parallel safe
security invoker
set search_path = public, pg_temp
as $$
  select case
    when p_cm3 is null or p_cm3 <= 0 then null
    else p_cm3::numeric / 1000.0
  end;
$$;

------------------------------------------------------------------------------
-- 2. Tables
------------------------------------------------------------------------------

create table if not exists public.vehicle_open_data_import_batch (
    id uuid primary key default gen_random_uuid(),
    source text not null,
    source_dataset text not null,
    source_version text not null,
    mapping_version text not null default public.carzon_open_data_mapping_version(),
    status text not null default 'started',
    row_count integer not null default 0,
    created_at timestamptz not null default now(),
    completed_at timestamptz,
    constraint vehicle_open_data_import_batch_source_chk
        check (source in ('eea', 'rdw', 'vehiclesdb', 'curated')),
    constraint vehicle_open_data_import_batch_status_chk
        check (status in ('started', 'completed', 'failed')),
    constraint vehicle_open_data_import_batch_dataset_chk
        check (btrim(source_dataset) <> ''),
    constraint vehicle_open_data_import_batch_version_chk
        check (btrim(source_version) <> '')
);

create unique index if not exists vehicle_open_data_import_batch_uniq
    on public.vehicle_open_data_import_batch (
        source, source_dataset, source_version, mapping_version
    );

comment on table public.vehicle_open_data_import_batch is
    'Idempotent open-data import batches. service_role / importer only.';

create table if not exists public.vehicle_identity_alias (
    id uuid primary key default gen_random_uuid(),
    make_key text not null,
    model_key text not null,
    alias_make_key text not null,
    alias_model_key text not null,
    source text not null,
    source_version text,
    mapping_version text not null default public.carzon_open_data_mapping_version(),
    created_at timestamptz not null default now(),
    constraint vehicle_identity_alias_keys_chk
        check (
            btrim(make_key) <> ''
            and btrim(model_key) <> ''
            and btrim(alias_make_key) <> ''
            and btrim(alias_model_key) <> ''
        ),
    constraint vehicle_identity_alias_source_chk
        check (source in ('vehiclesdb', 'carzon_catalog', 'curated'))
);

create unique index if not exists vehicle_identity_alias_alias_uniq
    on public.vehicle_identity_alias (alias_make_key, alias_model_key);

create index if not exists vehicle_identity_alias_canonical_idx
    on public.vehicle_identity_alias (make_key, model_key);

comment on table public.vehicle_identity_alias is
    'Exact alias → canonical make_key/model_key. No fuzzy guessing.';

create table if not exists public.vehicle_nameplate_identity (
    make_key text not null,
    model_key text not null,
    display_make text,
    display_model text,
    body_types text[] not null default '{}',
    tan_bases text[] not null default '{}',
    source text not null,
    source_version text,
    mapping_version text not null default public.carzon_open_data_mapping_version(),
    updated_at timestamptz not null default now(),
    primary key (make_key, model_key),
    constraint vehicle_nameplate_identity_source_chk
        check (source in ('vehiclesdb', 'carzon_catalog', 'curated'))
);

comment on table public.vehicle_nameplate_identity is
    'VehiclesDB/CARZON nameplate metadata. body_types are clarification metadata, not sole autofill.';

create table if not exists public.vehicle_open_data_configuration (
    id uuid primary key default gen_random_uuid(),
    configuration_key text not null,
    type_code text,
    variant_code text,
    version_code text,
    tan_base text,
    make_key text not null,
    model_key text not null,
    year_min integer not null,
    year_max integer not null,
    year_basis text not null default 'registration',
    fuel_type text,
    engine_displacement_cm3 integer,
    power_kw integer,
    body_type_rdw text,
    body_classes text[] not null default '{}',
    body_class_count integer not null default 0,
    transmission_type text,
    drivetrain text,
    observation_count integer not null default 0,
    field_lineage jsonb not null default '{}'::jsonb,
    mapping_version text not null default public.carzon_open_data_mapping_version(),
    import_batch_id uuid references public.vehicle_open_data_import_batch (id),
    updated_at timestamptz not null default now(),
    constraint vehicle_open_data_configuration_key_chk
        check (btrim(configuration_key) <> '' and configuration_key <> '||'),
    constraint vehicle_open_data_configuration_year_chk
        check (
            year_min >= 1900
            and year_max <= 2100
            and year_min <= year_max
        ),
    constraint vehicle_open_data_configuration_year_basis_chk
        check (year_basis in ('registration', 'first_admission')),
    constraint vehicle_open_data_configuration_fuel_chk
        check (
            fuel_type is null
            or fuel_type in (
                'petrol', 'diesel', 'hybrid', 'plug_in_hybrid',
                'electric', 'lpg', 'cng', 'other'
            )
        ),
    constraint vehicle_open_data_configuration_displ_chk
        check (
            engine_displacement_cm3 is null
            or (
                engine_displacement_cm3 > 0
                and engine_displacement_cm3 <= 20000
            )
        ),
    constraint vehicle_open_data_configuration_power_chk
        check (
            power_kw is null
            or (power_kw > 0 and power_kw <= 2000)
        ),
    constraint vehicle_open_data_configuration_rdw_body_chk
        check (
            body_type_rdw is null
            or body_type_rdw in (
                'sedan', 'hatchback', 'wagon', 'suv', 'coupe',
                'convertible', 'minivan', 'pickup', 'van', 'other'
            )
        ),
    constraint vehicle_open_data_configuration_m1_trans_null_chk
        check (transmission_type is null),
    constraint vehicle_open_data_configuration_m1_drive_null_chk
        check (drivetrain is null)
);

create unique index if not exists vehicle_open_data_configuration_identity_uniq
    on public.vehicle_open_data_configuration (
        configuration_key, make_key, model_key
    );

create index if not exists vehicle_open_data_configuration_mmy_idx
    on public.vehicle_open_data_configuration (
        make_key, model_key, year_min, year_max
    );

create index if not exists vehicle_open_data_configuration_tvv_idx
    on public.vehicle_open_data_configuration (configuration_key);

comment on table public.vehicle_open_data_configuration is
    'Aggregated EU configuration facts. No plates, VINs, or owner rows. '
    'year_min/year_max are registration/admission evidence, not OEM model year.';

comment on column public.vehicle_open_data_configuration.transmission_type is
    'Reserved. M1 EU open-data path must remain null.';

comment on column public.vehicle_open_data_configuration.drivetrain is
    'Reserved. M1 EU open-data path must remain null.';

alter table public.vehicle_open_data_import_batch enable row level security;
alter table public.vehicle_identity_alias enable row level security;
alter table public.vehicle_nameplate_identity enable row level security;
alter table public.vehicle_open_data_configuration enable row level security;

revoke all on table public.vehicle_open_data_import_batch from public;
revoke all on table public.vehicle_open_data_import_batch from anon;
revoke all on table public.vehicle_open_data_import_batch from authenticated;
revoke all on table public.vehicle_identity_alias from public;
revoke all on table public.vehicle_identity_alias from anon;
revoke all on table public.vehicle_identity_alias from authenticated;
revoke all on table public.vehicle_nameplate_identity from public;
revoke all on table public.vehicle_nameplate_identity from anon;
revoke all on table public.vehicle_nameplate_identity from authenticated;
revoke all on table public.vehicle_open_data_configuration from public;
revoke all on table public.vehicle_open_data_configuration from anon;
revoke all on table public.vehicle_open_data_configuration from authenticated;

------------------------------------------------------------------------------
-- 3. Identity resolution
------------------------------------------------------------------------------

create or replace function public.carzon_open_data_resolve_identity_keys(
    p_make text,
    p_model text
)
returns table (
    make_key text,
    model_key text
)
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
    v_make_key text;
    v_model_key text;
    v_canon_make text;
    v_canon_model text;
begin
    v_make_key := public.carzon_model_data_normalize_make_key(
        public.carzon_open_data_fold_ascii(p_make)
    );
    v_model_key := public.carzon_model_data_normalize_model_key(
        public.carzon_open_data_fold_ascii(p_model)
    );
    if v_make_key is null or v_model_key is null then
        return;
    end if;
    v_make_key := public.carzon_model_data_apply_make_alias_key(v_make_key);

    select a.make_key, a.model_key
      into v_canon_make, v_canon_model
      from public.vehicle_identity_alias a
     where a.alias_make_key = v_make_key
       and a.alias_model_key = v_model_key
     limit 1;

    if v_canon_make is not null then
        make_key := v_canon_make;
        model_key := v_canon_model;
        return next;
        return;
    end if;

    make_key := v_make_key;
    model_key := v_model_key;
    return next;
end;
$$;

------------------------------------------------------------------------------
-- 4. Import upserts (service_role)
------------------------------------------------------------------------------

create or replace function public.carzon_open_data_begin_import_batch(
    p_source text,
    p_source_dataset text,
    p_source_version text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_id uuid;
begin
    insert into public.vehicle_open_data_import_batch (
        source, source_dataset, source_version, mapping_version, status
    )
    values (
        p_source,
        p_source_dataset,
        p_source_version,
        public.carzon_open_data_mapping_version(),
        'started'
    )
    on conflict (source, source_dataset, source_version, mapping_version)
    do update
       set status = 'started',
           completed_at = null
     returning id into v_id;
    return v_id;
end;
$$;

create or replace function public.carzon_open_data_complete_import_batch(
    p_batch_id uuid,
    p_row_count integer,
    p_ok boolean
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    update public.vehicle_open_data_import_batch
       set status = case when coalesce(p_ok, false) then 'completed' else 'failed' end,
           row_count = greatest(coalesce(p_row_count, 0), 0),
           completed_at = now()
     where id = p_batch_id;
end;
$$;

create or replace function public.carzon_open_data_upsert_configurations(
    p_batch_id uuid,
    p_rows jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row jsonb;
    v_n integer := 0;
    v_keys record;
    v_cfg_key text;
    v_tan_base text;
    v_fuel text;
    v_year integer;
    v_year_max integer;
    v_ec integer;
    v_ep integer;
    v_count integer;
    v_lineage jsonb;
begin
    if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
        raise exception 'p_rows must be a JSON array' using errcode = '22023';
    end if;

    for v_row in select value from jsonb_array_elements(p_rows)
    loop
        v_cfg_key := public.carzon_open_data_configuration_key(
            v_row->>'type_code',
            v_row->>'variant_code',
            v_row->>'version_code'
        );
        if v_cfg_key is null then
            continue;
        end if;

        select * into v_keys
          from public.carzon_open_data_resolve_identity_keys(
              v_row->>'make',
              v_row->>'model'
          );
        if v_keys.make_key is null or v_keys.model_key is null then
            continue;
        end if;

        v_year := coalesce(
            nullif(v_row->>'year_min', '')::integer,
            nullif(v_row->>'year', '')::integer
        );
        v_year_max := coalesce(
            nullif(v_row->>'year_max', '')::integer,
            v_year
        );
        if v_year is null or v_year < 1900 or v_year > 2100 then
            continue;
        end if;
        if v_year_max is null or v_year_max < v_year or v_year_max > 2100 then
            v_year_max := v_year;
        end if;

        v_tan_base := public.carzon_open_data_normalize_tan_base(v_row->>'tan');
        v_fuel := public.carzon_open_data_normalize_fuel(
            v_row->>'ft',
            v_row->>'fm'
        );
        v_ec := nullif(v_row->>'ec_cm3', '')::integer;
        v_ep := nullif(v_row->>'ep_kw', '')::integer;
        if v_fuel = 'electric' then
            v_ec := null;
        end if;
        v_count := greatest(coalesce(nullif(v_row->>'observation_count', '')::integer, 1), 1);
        v_lineage := jsonb_build_object(
            'fuel', jsonb_build_object(
                'source', 'eea',
                'evidence', 'DIRECT',
                'raw', coalesce(v_row->>'ft', '') || '|' || coalesce(v_row->>'fm', '')
            ),
            'displacement_cm3', jsonb_build_object(
                'source', 'eea',
                'evidence', 'DIRECT'
            ),
            'power_kw', jsonb_build_object(
                'source', 'eea',
                'evidence', 'DIRECT'
            )
        );

        insert into public.vehicle_open_data_configuration (
            configuration_key,
            type_code,
            variant_code,
            version_code,
            tan_base,
            make_key,
            model_key,
            year_min,
            year_max,
            year_basis,
            fuel_type,
            engine_displacement_cm3,
            power_kw,
            observation_count,
            field_lineage,
            mapping_version,
            import_batch_id
        )
        values (
            v_cfg_key,
            nullif(btrim(coalesce(v_row->>'type_code', '')), ''),
            nullif(btrim(coalesce(v_row->>'variant_code', '')), ''),
            nullif(btrim(coalesce(v_row->>'version_code', '')), ''),
            v_tan_base,
            v_keys.make_key,
            v_keys.model_key,
            v_year,
            v_year_max,
            'registration',
            v_fuel,
            v_ec,
            v_ep,
            v_count,
            v_lineage,
            public.carzon_open_data_mapping_version(),
            p_batch_id
        )
        on conflict (configuration_key, make_key, model_key)
        do update set
            tan_base = coalesce(
                excluded.tan_base,
                public.vehicle_open_data_configuration.tan_base
            ),
            year_min = least(
                public.vehicle_open_data_configuration.year_min,
                excluded.year_min
            ),
            year_max = greatest(
                public.vehicle_open_data_configuration.year_max,
                excluded.year_max
            ),
            fuel_type = case
                when public.vehicle_open_data_configuration.fuel_type
                     is not distinct from excluded.fuel_type
                    then excluded.fuel_type
                when public.vehicle_open_data_configuration.fuel_type is null
                    then excluded.fuel_type
                when excluded.fuel_type is null
                    then public.vehicle_open_data_configuration.fuel_type
                else null
            end,
            engine_displacement_cm3 = case
                when public.vehicle_open_data_configuration.engine_displacement_cm3
                     is not distinct from excluded.engine_displacement_cm3
                    then excluded.engine_displacement_cm3
                when public.vehicle_open_data_configuration.engine_displacement_cm3 is null
                    then excluded.engine_displacement_cm3
                when excluded.engine_displacement_cm3 is null
                    then public.vehicle_open_data_configuration.engine_displacement_cm3
                else null
            end,
            power_kw = case
                when public.vehicle_open_data_configuration.power_kw
                     is not distinct from excluded.power_kw
                    then excluded.power_kw
                when public.vehicle_open_data_configuration.power_kw is null
                    then excluded.power_kw
                when excluded.power_kw is null
                    then public.vehicle_open_data_configuration.power_kw
                else null
            end,
            observation_count = excluded.observation_count,
            import_batch_id = excluded.import_batch_id,
            mapping_version = excluded.mapping_version,
            updated_at = now();

        v_n := v_n + 1;
    end loop;

    return v_n;
end;
$$;

create or replace function public.carzon_open_data_merge_rdw_body(
    p_batch_id uuid,
    p_rows jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row jsonb;
    v_n integer := 0;
    v_cfg_key text;
    v_body text;
    v_classes text[];
begin
    if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
        raise exception 'p_rows must be a JSON array' using errcode = '22023';
    end if;

    for v_row in select value from jsonb_array_elements(p_rows)
    loop
        -- Refuse any payload that still carries plate/VIN-like keys.
        if v_row ? 'kenteken'
           or v_row ? 'license_plate'
           or v_row ? 'vin'
           or v_row ? 'chassisnummer'
           or v_row ? 'tenaamstelling'
        then
            raise exception 'rdw payload must not retain plate/VIN/owner keys'
                using errcode = '22023';
        end if;

        v_cfg_key := public.carzon_open_data_configuration_key(
            v_row->>'type_code',
            v_row->>'variant_code',
            v_row->>'version_code'
        );
        if v_cfg_key is null then
            continue;
        end if;

        v_body := public.carzon_open_data_normalize_rdw_body(
            v_row->>'carrosserietype',
            v_row->>'eu_description',
            v_row->>'inrichting'
        );
        if v_body is null then
            continue;
        end if;

        v_classes := array[v_body];

        update public.vehicle_open_data_configuration c
           set body_classes = (
                    select coalesce(array_agg(distinct x order by x), '{}')
                      from unnest(c.body_classes || v_classes) as x
               ),
               body_class_count = (
                    select count(distinct x)
                      from unnest(c.body_classes || v_classes) as x
               ),
               body_type_rdw = case
                    when c.body_type_rdw is null then v_body
                    when c.body_type_rdw = v_body then v_body
                    else null
               end,
               field_lineage = coalesce(c.field_lineage, '{}'::jsonb)
                   || jsonb_build_object(
                       'body',
                       jsonb_build_object(
                           'source', 'rdw',
                           'evidence', 'JOINED'
                       )
                   ),
               import_batch_id = coalesce(p_batch_id, c.import_batch_id),
               updated_at = now()
         where c.configuration_key = v_cfg_key;

        if found then
            v_n := v_n + 1;
        end if;
    end loop;

    return v_n;
end;
$$;

create or replace function public.carzon_open_data_upsert_nameplates(
    p_rows jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row jsonb;
    v_n integer := 0;
    v_keys record;
    v_bodies text[];
    v_tans text[];
begin
    if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
        raise exception 'p_rows must be a JSON array' using errcode = '22023';
    end if;

    for v_row in select value from jsonb_array_elements(p_rows)
    loop
        select * into v_keys
          from public.carzon_open_data_resolve_identity_keys(
              v_row->>'make',
              v_row->>'model'
          );
        if v_keys.make_key is null then
            continue;
        end if;

        select coalesce(array_agg(distinct b order by b), '{}')
          into v_bodies
          from (
            select public.carzon_open_data_normalize_nameplate_body(value #>> '{}') as b
              from jsonb_array_elements(
                  case
                    when jsonb_typeof(v_row->'body_types') = 'array'
                      then v_row->'body_types'
                    else '[]'::jsonb
                  end
              )
          ) s
         where b is not null;

        select coalesce(array_agg(distinct t order by t), '{}')
          into v_tans
          from (
            select public.carzon_open_data_normalize_tan_base(value #>> '{}') as t
              from jsonb_array_elements(
                  case
                    when jsonb_typeof(v_row->'tan_bases') = 'array'
                      then v_row->'tan_bases'
                    else '[]'::jsonb
                  end
              )
          ) s
         where t is not null;

        insert into public.vehicle_nameplate_identity (
            make_key,
            model_key,
            display_make,
            display_model,
            body_types,
            tan_bases,
            source,
            source_version,
            mapping_version
        )
        values (
            v_keys.make_key,
            v_keys.model_key,
            nullif(btrim(coalesce(v_row->>'display_make', '')), ''),
            nullif(btrim(coalesce(v_row->>'display_model', '')), ''),
            v_bodies,
            v_tans,
            coalesce(nullif(v_row->>'source', ''), 'vehiclesdb'),
            v_row->>'source_version',
            public.carzon_open_data_mapping_version()
        )
        on conflict (make_key, model_key)
        do update set
            display_make = coalesce(
                excluded.display_make,
                public.vehicle_nameplate_identity.display_make
            ),
            display_model = coalesce(
                excluded.display_model,
                public.vehicle_nameplate_identity.display_model
            ),
            body_types = excluded.body_types,
            tan_bases = excluded.tan_bases,
            source = excluded.source,
            source_version = excluded.source_version,
            mapping_version = excluded.mapping_version,
            updated_at = now();

        v_n := v_n + 1;
    end loop;
    return v_n;
end;
$$;

create or replace function public.carzon_open_data_upsert_aliases(
    p_rows jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row jsonb;
    v_n integer := 0;
    v_canon record;
    v_alias record;
begin
    if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
        raise exception 'p_rows must be a JSON array' using errcode = '22023';
    end if;

    for v_row in select value from jsonb_array_elements(p_rows)
    loop
        select * into v_canon
          from public.carzon_open_data_resolve_identity_keys(
              v_row->>'make',
              v_row->>'model'
          );
        select
            public.carzon_model_data_apply_make_alias_key(
                public.carzon_model_data_normalize_make_key(
                    public.carzon_open_data_fold_ascii(v_row->>'alias_make')
                )
            ) as make_key,
            public.carzon_model_data_normalize_model_key(
                public.carzon_open_data_fold_ascii(v_row->>'alias_model')
            ) as model_key
          into v_alias;
        if v_canon.make_key is null or v_alias.make_key is null or v_alias.model_key is null then
            continue;
        end if;

        insert into public.vehicle_identity_alias (
            make_key,
            model_key,
            alias_make_key,
            alias_model_key,
            source,
            source_version,
            mapping_version
        )
        values (
            v_canon.make_key,
            v_canon.model_key,
            v_alias.make_key,
            v_alias.model_key,
            coalesce(nullif(v_row->>'source', ''), 'curated'),
            v_row->>'source_version',
            public.carzon_open_data_mapping_version()
        )
        on conflict (alias_make_key, alias_model_key)
        do update set
            make_key = excluded.make_key,
            model_key = excluded.model_key,
            source = excluded.source,
            source_version = excluded.source_version,
            mapping_version = excluded.mapping_version;

        v_n := v_n + 1;
    end loop;
    return v_n;
end;
$$;

------------------------------------------------------------------------------
-- 5. Read-only MMY resolver
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
    v_displ_cons integer;
    v_power_cons integer;
    v_body_opts jsonb;
    v_fuel_opts jsonb;
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
    if v_attr not in ('body', 'fuel') or v_value = '' then
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
    )
    select
        c.n,
        c.body_cons,
        c.fuel_cons,
        c.displ_cons,
        c.power_cons,
        coalesce(b.opts, np.opts),
        f.opts
      into
        v_candidate_count,
        v_body_cons,
        v_fuel_cons,
        v_displ_cons,
        v_power_cons,
        v_body_opts,
        v_fuel_opts
      from counted c
      left join body_opt b on true
      left join nameplate_opt np on true
      left join fuel_opt f on true;

    if coalesce(v_candidate_count, 0) = 0 then
        v_status := 'noData';
        v_confidence := 'none';
        v_clarification := null;
        v_body_cons := null;
        v_fuel_cons := null;
        v_displ_cons := null;
        v_power_cons := null;
    else
        -- Seller clarification fills that field without a second question.
        if v_attr = 'body' then
            v_body_cons := v_value;
        elsif v_attr = 'fuel' then
            v_fuel_cons := v_value;
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
            end if;
        end if;

        if v_body_cons is not null
           or v_fuel_cons is not null
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
            'transmissionType', null,
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
    'Does not write listings or VIN state. Failure never blocks create-listing.';

------------------------------------------------------------------------------
-- 6. Privileges
------------------------------------------------------------------------------

revoke all on function public.carzon_open_data_mapping_version() from public;
revoke all on function public.carzon_open_data_fold_ascii(text) from public;
revoke all on function public.carzon_open_data_normalize_tan_base(text) from public;
revoke all on function public.carzon_open_data_configuration_key(text, text, text) from public;
revoke all on function public.carzon_open_data_normalize_fuel(text, text) from public;
revoke all on function public.carzon_open_data_normalize_rdw_body(text, text, text) from public;
revoke all on function public.carzon_open_data_normalize_nameplate_body(text) from public;
revoke all on function public.carzon_open_data_kw_to_hp(integer) from public;
revoke all on function public.carzon_open_data_cm3_to_liters(integer) from public;
revoke all on function public.carzon_open_data_resolve_identity_keys(text, text) from public;
revoke all on function public.carzon_open_data_begin_import_batch(text, text, text) from public;
revoke all on function public.carzon_open_data_complete_import_batch(uuid, integer, boolean) from public;
revoke all on function public.carzon_open_data_upsert_configurations(uuid, jsonb) from public;
revoke all on function public.carzon_open_data_merge_rdw_body(uuid, jsonb) from public;
revoke all on function public.carzon_open_data_upsert_nameplates(jsonb) from public;
revoke all on function public.carzon_open_data_upsert_aliases(jsonb) from public;

revoke all on function public.carzon_open_data_mapping_version() from anon, authenticated;
revoke all on function public.carzon_open_data_fold_ascii(text) from anon, authenticated;
revoke all on function public.carzon_open_data_normalize_tan_base(text) from anon, authenticated;
revoke all on function public.carzon_open_data_configuration_key(text, text, text) from anon, authenticated;
revoke all on function public.carzon_open_data_normalize_fuel(text, text) from anon, authenticated;
revoke all on function public.carzon_open_data_normalize_rdw_body(text, text, text) from anon, authenticated;
revoke all on function public.carzon_open_data_normalize_nameplate_body(text) from anon, authenticated;
revoke all on function public.carzon_open_data_kw_to_hp(integer) from anon, authenticated;
revoke all on function public.carzon_open_data_cm3_to_liters(integer) from anon, authenticated;
revoke all on function public.carzon_open_data_resolve_identity_keys(text, text) from anon, authenticated;
revoke all on function public.carzon_open_data_begin_import_batch(text, text, text) from anon, authenticated;
revoke all on function public.carzon_open_data_complete_import_batch(uuid, integer, boolean) from anon, authenticated;
revoke all on function public.carzon_open_data_upsert_configurations(uuid, jsonb) from anon, authenticated;
revoke all on function public.carzon_open_data_merge_rdw_body(uuid, jsonb) from anon, authenticated;
revoke all on function public.carzon_open_data_upsert_nameplates(jsonb) from anon, authenticated;
revoke all on function public.carzon_open_data_upsert_aliases(jsonb) from anon, authenticated;

grant execute on function public.carzon_open_data_begin_import_batch(text, text, text)
    to service_role;
grant execute on function public.carzon_open_data_complete_import_batch(uuid, integer, boolean)
    to service_role;
grant execute on function public.carzon_open_data_upsert_configurations(uuid, jsonb)
    to service_role;
grant execute on function public.carzon_open_data_merge_rdw_body(uuid, jsonb)
    to service_role;
grant execute on function public.carzon_open_data_upsert_nameplates(jsonb)
    to service_role;
grant execute on function public.carzon_open_data_upsert_aliases(jsonb)
    to service_role;

revoke all on function public.resolve_vehicle_by_identity(text, text, integer, jsonb)
    from public;
revoke all on function public.resolve_vehicle_by_identity(text, text, integer, jsonb)
    from anon;
grant execute on function public.resolve_vehicle_by_identity(text, text, integer, jsonb)
    to authenticated;

------------------------------------------------------------------------------
-- 7. Conservative curated aliases (explicit only; no marketing inference)
------------------------------------------------------------------------------

insert into public.vehicle_identity_alias (
    make_key, model_key, alias_make_key, alias_model_key, source, source_version
)
values
    ('bmw', '3 series', 'bmw', '318i', 'curated', 'm1.0'),
    ('bmw', '3 series', 'bmw', '318d', 'curated', 'm1.0'),
    ('bmw', '3 series', 'bmw', '320i', 'curated', 'm1.0'),
    ('bmw', '3 series', 'bmw', '320d', 'curated', 'm1.0'),
    ('bmw', '3 series', 'bmw', '320e', 'curated', 'm1.0'),
    ('bmw', '3 series', 'bmw', '330i', 'curated', 'm1.0'),
    ('bmw', '3 series', 'bmw', '330d', 'curated', 'm1.0'),
    ('bmw', '3 series', 'bmw', '330e', 'curated', 'm1.0'),
    ('bmw', '3 series', 'bmw', '340i', 'curated', 'm1.0'),
    ('mercedesbenz', 'e-class', 'mercedesbenz', 'e 200', 'curated', 'm1.0'),
    ('mercedesbenz', 'e-class', 'mercedesbenz', 'e 200 d', 'curated', 'm1.0'),
    ('mercedesbenz', 'e-class', 'mercedesbenz', 'e 220 d', 'curated', 'm1.0'),
    ('mercedesbenz', 'e-class', 'mercedesbenz', 'e 300 e', 'curated', 'm1.0'),
    ('mercedesbenz', 'e-class', 'mercedesbenz', 'e 300 de', 'curated', 'm1.0'),
    ('tesla', 'model 3', 'tesla', 'model3', 'curated', 'm1.0')
on conflict (alias_make_key, alias_model_key) do nothing;
