-- Synthetic V2 resolver fixtures. Safe on local Postgres after migrations.
-- Uses isolated make/model keys so it never depends on hosted catalog counts.

do $$
declare
    v jsonb;
    v2 jsonb;
    v_id text;
    v_kinds text;
    v_count integer;
    v_opt_count integer;
begin
    delete from public.vehicle_open_data_configuration
     where make_key like 'sfv2%' or model_key like 'sfv2%';
    delete from public.vehicle_nameplate_identity
     where make_key like 'sfv2%';
    delete from public.vehicle_identity_alias
     where make_key like 'sfv2%' or alias_make_key like 'sfv2%';

    -- 1. Fabia-like: one body, three engine tuples, trans depends on engine.
    insert into public.vehicle_nameplate_identity (
        make_key, model_key, display_make, display_model, body_types, source
    ) values (
        'sfv2fabia', 'caseone', 'Sfv2fabia', 'Caseone', array['hatchback'], 'curated'
    );

    insert into public.vehicle_open_data_configuration (
        configuration_key, make_key, model_key, year_min, year_max,
        fuel_type, engine_displacement_cm3, power_kw, body_type_rdw, transmission_type
    ) values
        ('sfv2|fabia|a', 'sfv2fabia', 'caseone', 2018, 2020, 'petrol', 999, 70, 'hatchback', 'manual'),
        ('sfv2|fabia|b', 'sfv2fabia', 'caseone', 2018, 2020, 'petrol', 999, 70, 'hatchback', 'automatic'),
        ('sfv2|fabia|c', 'sfv2fabia', 'caseone', 2018, 2020, 'petrol', 999, 81, 'hatchback', 'automatic'),
        ('sfv2|fabia|d', 'sfv2fabia', 'caseone', 2018, 2020, 'diesel', 1422, 66, 'hatchback', 'manual'),
        ('sfv2|fabia|e', 'sfv2fabia', 'caseone', 2018, 2020, 'petrol', 999, 70, 'hatchback', 'manual');

    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia', 'Caseone', 2019, '{"answers":[],"skippedKinds":[]}'::jsonb
    );
    if v->>'status' <> 'ok' then
        raise exception 'fabia initial status %', v->>'status';
    end if;
    if v->>'mappingVersion' <> 'm1.2' then
        raise exception 'fabia mapping %', v->>'mappingVersion';
    end if;
    if v->'consensusSpecs'->>'bodyType' <> 'hatchback' then
        raise exception 'fabia should consensus single body, got %', v->'consensusSpecs';
    end if;
    if v->'nextRefinement'->>'kind' <> 'engine' then
        raise exception 'fabia next should be engine, got %', v->'nextRefinement';
    end if;
    if jsonb_array_length(v->'nextRefinement'->'options') <> 3 then
        raise exception 'fabia engine options %, expected 3', v->'nextRefinement'->'options';
    end if;

    -- Dedup: petrol 1.0 95 has 3 underlying rows (a,b,e).
    select (e->>'candidateCount')::int
      into v_count
      from jsonb_array_elements(v->'nextRefinement'->'options') e
     where e->>'fuelType' = 'petrol'
       and (e->>'engineDisplacementLiters')::numeric = 1.0
       and (e->>'enginePowerHp')::int = 95;
    if v_count <> 3 then
        raise exception 'fabia 1.0/95 candidateCount %, expected 3', v_count;
    end if;

    select e->>'id'
      into v_id
      from jsonb_array_elements(v->'nextRefinement'->'options') e
     where (e->>'enginePowerHp')::int = 95
     limit 1;

    v2 := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia',
        'Caseone',
        2019,
        jsonb_build_object(
            'answers', jsonb_build_array(
                jsonb_build_object('kind', 'engine', 'optionId', v_id)
            ),
            'skippedKinds', '[]'::jsonb
        )
    );
    if v2->'consensusSpecs'->>'enginePowerHp' <> '95' then
        raise exception 'selected engine should set 95 hp, got %', v2->'consensusSpecs';
    end if;
    if (v2->'consensusSpecs'->>'engineDisplacementLiters')::numeric <> 1.0 then
        raise exception '999cc must be 1.0 L, got %', v2->'consensusSpecs';
    end if;
    if v2->'nextRefinement'->>'kind' <> 'transmission' then
        raise exception 'after 95hp engine, next should be transmission, got %', v2->'nextRefinement';
    end if;
    if exists (
        select 1
          from jsonb_array_elements(v2->'nextRefinement'->'options') e
         where e->>'transmissionType' not in ('manual', 'automatic')
    ) then
        raise exception 'impossible transmission leaked: %', v2->'nextRefinement';
    end if;
    if jsonb_array_length(v2->'nextRefinement'->'options') <> 2 then
        raise exception '95hp should keep manual+auto, got %', v2->'nextRefinement';
    end if;

    -- Tampered optionId.
    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia',
        'Caseone',
        2019,
        '{"answers":[{"kind":"engine","optionId":"deadbeef"}],"skippedKinds":[]}'::jsonb
    );
    if v->>'status' <> 'invalidRefinement' then
        raise exception 'tampered id should be invalidRefinement, got %', v;
    end if;

    -- 2. Golf body regression.
    insert into public.vehicle_nameplate_identity (
        make_key, model_key, display_make, display_model, body_types, source
    ) values (
        'sfv2golf', 'casegolf', 'Sfv2golf', 'Casegolf', array['hatchback'], 'curated'
    );
    insert into public.vehicle_open_data_configuration (
        configuration_key, make_key, model_key, year_min, year_max,
        fuel_type, engine_displacement_cm3, power_kw, body_type_rdw, transmission_type
    ) values
        ('sfv2|golf|w1', 'sfv2golf', 'casegolf', 2018, 2020, 'petrol', 1498, 110, 'wagon', 'manual'),
        ('sfv2|golf|w2', 'sfv2golf', 'casegolf', 2018, 2020, 'petrol', 1498, 110, 'wagon', 'automatic'),
        ('sfv2|golf|h1', 'sfv2golf', 'casegolf', 2018, 2020, 'petrol', 1498, 110, 'hatchback', 'manual');

    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2golf', 'Casegolf', 2019, '{}'::jsonb
    );
    if v->'consensusSpecs'->>'bodyType' is not null then
        raise exception 'golf v2 must not consensus nameplate hatchback, got %', v->'consensusSpecs';
    end if;
    if v->'nextRefinement'->>'kind' <> 'body' then
        raise exception 'golf v2 should ask body, got %', v->'nextRefinement';
    end if;
    if jsonb_array_length(v->'nextRefinement'->'options') <> 2 then
        raise exception 'golf body options %', v->'nextRefinement';
    end if;

    v := public.resolve_vehicle_by_identity(
        'Sfv2golf', 'Casegolf', 2019, null
    );
    if v->'consensusSpecs'->>'bodyType' <> 'hatchback' then
        raise exception 'v1 golf regression must remain nameplate hatchback, got %', v->'consensusSpecs';
    end if;
    if v->>'mappingVersion' <> 'm1.1' then
        raise exception 'v1 mapping must stay m1.1, got %', v->>'mappingVersion';
    end if;

    -- Sequential body → engine → transmission on a two-body mixed set.
    insert into public.vehicle_open_data_configuration (
        configuration_key, make_key, model_key, year_min, year_max,
        fuel_type, engine_displacement_cm3, power_kw, body_type_rdw, transmission_type
    ) values
        ('sfv2|seq|1', 'sfv2seq', 'caseseq', 2018, 2020, 'petrol', 999, 70, 'hatchback', 'manual'),
        ('sfv2|seq|2', 'sfv2seq', 'caseseq', 2018, 2020, 'petrol', 999, 81, 'hatchback', 'automatic'),
        ('sfv2|seq|3', 'sfv2seq', 'caseseq', 2018, 2020, 'petrol', 999, 70, 'wagon', 'manual');

    v := public.resolve_vehicle_by_identity_v2('Sfv2seq', 'Caseseq', 2019, '{}'::jsonb);
    if v->'nextRefinement'->>'kind' <> 'body' then
        raise exception 'seq first kind %, expected body', v->'nextRefinement';
    end if;
    select e->>'id' into v_id
      from jsonb_array_elements(v->'nextRefinement'->'options') e
     where e->>'bodyType' = 'hatchback';
    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2seq', 'Caseseq', 2019,
        jsonb_build_object(
            'answers', jsonb_build_array(jsonb_build_object('kind', 'body', 'optionId', v_id)),
            'skippedKinds', '[]'::jsonb
        )
    );
    if v->'nextRefinement'->>'kind' <> 'engine' then
        raise exception 'seq after body should ask engine, got %', v->'nextRefinement';
    end if;
    select e->>'id' into v_id
      from jsonb_array_elements(v->'nextRefinement'->'options') e
     where (e->>'enginePowerHp')::int = 95;
    v2 := public.resolve_vehicle_by_identity_v2(
        'Sfv2seq', 'Caseseq', 2019,
        jsonb_build_object(
            'answers', jsonb_build_array(
                jsonb_build_object(
                    'kind', 'body',
                    'optionId', public.carzon_open_data_v2_option_id(
                        'sfv2seq', 'caseseq', 2019, 'body', 'hatchback'
                    )
                ),
                jsonb_build_object('kind', 'engine', 'optionId', v_id)
            ),
            'skippedKinds', '[]'::jsonb
        )
    );
    if v2->'consensusSpecs'->>'transmissionType' <> 'manual' then
        raise exception 'seq hatch+95 should consensus manual, got %', v2->'consensusSpecs';
    end if;

    -- 3. Fuel fallback when engines > 8.
    insert into public.vehicle_open_data_configuration (
        configuration_key, make_key, model_key, year_min, year_max,
        fuel_type, engine_displacement_cm3, power_kw, body_type_rdw, transmission_type
    )
    select
        'sfv2|fuel|' || g,
        'sfv2fuel',
        'casefuel',
        2018,
        2020,
        case when g <= 5 then 'petrol' else 'diesel' end,
        1000 + g * 100,
        50 + g,
        'hatchback',
        'manual'
    from generate_series(1, 9) g;

    v := public.resolve_vehicle_by_identity_v2('Sfv2fuel', 'Casefuel', 2019, '{}'::jsonb);
    if v->'nextRefinement'->>'kind' <> 'fuel' then
        raise exception 'fuel fallback expected, got %', v->'nextRefinement';
    end if;
    select e->>'id' into v_id
      from jsonb_array_elements(v->'nextRefinement'->'options') e
     where e->>'fuelType' = 'petrol';
    v2 := public.resolve_vehicle_by_identity_v2(
        'Sfv2fuel', 'Casefuel', 2019,
        jsonb_build_object(
            'answers', jsonb_build_array(jsonb_build_object('kind', 'fuel', 'optionId', v_id)),
            'skippedKinds', '[]'::jsonb
        )
    );
    if v2->'nextRefinement'->>'kind' <> 'engine' then
        raise exception 'after fuel, engine should be askable, got %', v2->'nextRefinement';
    end if;
    if jsonb_array_length(v2->'nextRefinement'->'options') > 8 then
        raise exception 'engine dump after fuel: %', v2->'nextRefinement';
    end if;

    -- 4. EV: electric consensus, no engine/trans question.
    insert into public.vehicle_open_data_configuration (
        configuration_key, make_key, model_key, year_min, year_max,
        fuel_type, engine_displacement_cm3, power_kw, body_type_rdw, transmission_type
    ) values
        ('sfv2|ev|1', 'sfv2ev', 'caseev', 2018, 2021, 'electric', null, 150, 'sedan', null),
        ('sfv2|ev|2', 'sfv2ev', 'caseev', 2018, 2021, 'electric', null, 180, 'sedan', null);

    v := public.resolve_vehicle_by_identity_v2('Sfv2ev', 'Caseev', 2019, '{}'::jsonb);
    if v->'consensusSpecs'->>'fuelType' <> 'electric' then
        raise exception 'ev fuel %, expected electric', v->'consensusSpecs';
    end if;
    if v->'consensusSpecs'->>'transmissionType' is not null then
        raise exception 'ev must not invent transmission, got %', v->'consensusSpecs';
    end if;
    if v->'nextRefinement' is not null and v->'nextRefinement' != 'null'::jsonb then
        raise exception 'ev must not ask engine/trans, got %', v->'nextRefinement';
    end if;

    -- 5. Null/incomplete: missing values stay null, no invented option.
    insert into public.vehicle_open_data_configuration (
        configuration_key, make_key, model_key, year_min, year_max,
        fuel_type, engine_displacement_cm3, power_kw, body_type_rdw, transmission_type
    ) values
        ('sfv2|null|1', 'sfv2null', 'casenull', 2018, 2020, null, null, null, null, null),
        ('sfv2|null|2', 'sfv2null', 'casenull', 2018, 2020, null, null, null, null, null);

    v := public.resolve_vehicle_by_identity_v2('Sfv2null', 'Casenull', 2019, '{}'::jsonb);
    if v->'consensusSpecs'->>'bodyType' is not null
       or v->'consensusSpecs'->>'fuelType' is not null
       or (v->'nextRefinement' is not null and v->'nextRefinement' != 'null'::jsonb)
    then
        raise exception 'null fixture invented values: %', v;
    end if;

    -- 9. Skip does not filter and may ask the next kind.
    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia',
        'Caseone',
        2019,
        '{"answers":[],"skippedKinds":["engine"]}'::jsonb
    );
    if v->'nextRefinement'->>'kind' <> 'transmission' then
        raise exception 'skip engine should still ask transmission, got %', v->'nextRefinement';
    end if;
    if v->'consensusSpecs'->>'enginePowerHp' is not null then
        raise exception 'skip must not write engine, got %', v->'consensusSpecs';
    end if;

    -- 10. Three skips that already include transmission: no extra question.
    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia',
        'Caseone',
        2019,
        '{"answers":[],"skippedKinds":["body","engine","transmission"]}'::jsonb
    );
    if v->'nextRefinement' is not null and v->'nextRefinement' != 'null'::jsonb then
        raise exception 'after 3 skips including transmission next must be null, got %', v->'nextRefinement';
    end if;
    if (v->'refinementState'->>'decisionsUsed')::int <> 3 then
        raise exception 'decisionsUsed %', v->'refinementState';
    end if;

    -- 11. Terminal transmission after three non-transmission decisions.
    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia',
        'Caseone',
        2019,
        '{"answers":[],"skippedKinds":["body","fuel","engine"]}'::jsonb
    );
    if v->'nextRefinement'->>'kind' <> 'transmission' then
        raise exception 'terminal after 3 should be transmission, got %', v->'nextRefinement';
    end if;
    if (v->'refinementState'->>'maxDecisions')::int <> 3 then
        raise exception 'maxDecisions should stay 3, got %', v->'refinementState';
    end if;
    if jsonb_array_length(v->'nextRefinement'->'options') <> 2 then
        raise exception 'terminal trans options %, expected 2', v->'nextRefinement';
    end if;
    select e->>'id' into v_id
      from jsonb_array_elements(v->'nextRefinement'->'options') e
     where e->>'transmissionType' = 'manual';

    v2 := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia',
        'Caseone',
        2019,
        jsonb_build_object(
            'answers', jsonb_build_array(
                jsonb_build_object('kind', 'transmission', 'optionId', v_id)
            ),
            'skippedKinds', '["body","fuel","engine"]'::jsonb
        )
    );
    if v2->>'status' <> 'ok' then
        raise exception 'terminal answer status %', v2;
    end if;
    if v2->'consensusSpecs'->>'transmissionType' <> 'manual' then
        raise exception 'terminal answer should set manual, got %', v2->'consensusSpecs';
    end if;
    if v2->'nextRefinement' is not null and v2->'nextRefinement' != 'null'::jsonb then
        raise exception 'after terminal answer next must be null, got %', v2->'nextRefinement';
    end if;
    if (v2->'refinementState'->>'decisionsUsed')::int <> 4 then
        raise exception 'after terminal answer decisionsUsed %', v2->'refinementState';
    end if;

    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia',
        'Caseone',
        2019,
        '{"answers":[],"skippedKinds":["body","fuel","engine","transmission"]}'::jsonb
    );
    if v->>'status' <> 'ok' then
        raise exception 'terminal skip status %', v;
    end if;
    if v->'consensusSpecs'->>'transmissionType' is not null then
        raise exception 'terminal skip must not write transmission, got %', v->'consensusSpecs';
    end if;
    if v->'nextRefinement' is not null and v->'nextRefinement' != 'null'::jsonb then
        raise exception 'terminal skip next must be null, got %', v->'nextRefinement';
    end if;

    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2fabia',
        'Caseone',
        2019,
        '{"answers":[{"kind":"engine","optionId":"deadbeef"}],"skippedKinds":["body","fuel","engine","transmission"]}'::jsonb
    );
    if v->>'status' <> 'invalidRefinement' then
        raise exception 'fifth decision must be invalidRefinement, got %', v;
    end if;

    -- A fourth prompt is never body/fuel/engine: already asserted above
    -- (next.kind = transmission). Five decisions stay invalid.

    -- Consensus after decision 3: no terminal question.
    select e->>'id' into v_id
      from jsonb_array_elements(
          public.resolve_vehicle_by_identity_v2(
              'Sfv2seq', 'Caseseq', 2019, '{}'::jsonb
          )->'nextRefinement'->'options'
      ) e
     where e->>'bodyType' = 'hatchback';
    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2seq',
        'Caseseq',
        2019,
        jsonb_build_object(
            'answers', jsonb_build_array(
                jsonb_build_object('kind', 'body', 'optionId', v_id)
            ),
            'skippedKinds', '["fuel"]'::jsonb
        )
    );
    select e->>'id' into v_id
      from jsonb_array_elements(v->'nextRefinement'->'options') e
     where (e->>'enginePowerHp')::int = 95;
    v2 := public.resolve_vehicle_by_identity_v2(
        'Sfv2seq',
        'Caseseq',
        2019,
        jsonb_build_object(
            'answers', jsonb_build_array(
                jsonb_build_object(
                    'kind', 'body',
                    'optionId', public.carzon_open_data_v2_option_id(
                        'sfv2seq', 'caseseq', 2019, 'body', 'hatchback'
                    )
                ),
                jsonb_build_object('kind', 'engine', 'optionId', v_id)
            ),
            'skippedKinds', '["fuel"]'::jsonb
        )
    );
    if v2->'consensusSpecs'->>'transmissionType' <> 'manual' then
        raise exception 'seq after 3 should consensus manual, got %', v2->'consensusSpecs';
    end if;
    if v2->'nextRefinement' is not null and v2->'nextRefinement' != 'null'::jsonb then
        raise exception 'consensus after 3 must not ask again, got %', v2->'nextRefinement';
    end if;

    -- Absent transmission evidence: no terminal question.
    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2null',
        'Casenull',
        2019,
        '{"answers":[],"skippedKinds":["body","fuel","engine"]}'::jsonb
    );
    if v->'nextRefinement' is not null and v->'nextRefinement' != 'null'::jsonb then
        raise exception 'null trans evidence must not ask terminal, got %', v;
    end if;

    -- EV after 3 skips: still no engine/trans question.
    v := public.resolve_vehicle_by_identity_v2(
        'Sfv2ev',
        'Caseev',
        2020,
        '{"answers":[],"skippedKinds":["body","fuel","engine"]}'::jsonb
    );
    if v->'consensusSpecs'->>'fuelType' <> 'electric' then
        raise exception 'ev fuel after skips %, expected electric', v->'consensusSpecs';
    end if;
    if v->'nextRefinement' is not null and v->'nextRefinement' != 'null'::jsonb then
        raise exception 'ev must not get terminal transmission, got %', v->'nextRefinement';
    end if;

    delete from public.vehicle_open_data_configuration
     where make_key like 'sfv2%' or model_key like 'sfv2%';
    delete from public.vehicle_nameplate_identity
     where make_key like 'sfv2%';
end $$;
