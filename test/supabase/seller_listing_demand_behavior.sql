-- Local-only Seller Buyer Demand Phase 5B fixtures. Isolated emails/titles.
-- Requires repository migrations applied. Safe to re-run.

do $$
declare
    v_dealer_a uuid := 'aaaaaaaa-5b00-4000-8000-0000000000a1';
    v_dealer_b uuid := 'bbbbbbbb-5b00-4000-8000-0000000000b1';
    v_private uuid := 'pppppppp-5b00-4000-8000-0000000000p1';
    v_empty uuid := 'eeeeeeee-5b00-4000-8000-0000000000e1';
    v_buyers uuid[] := array[
        '11111111-5b00-4000-8000-0000000000c1'::uuid,
        '11111111-5b00-4000-8000-0000000000c2'::uuid,
        '11111111-5b00-4000-8000-0000000000c3'::uuid,
        '11111111-5b00-4000-8000-0000000000c4'::uuid,
        '11111111-5b00-4000-8000-0000000000c5'::uuid,
        '11111111-5b00-4000-8000-0000000000c6'::uuid
    ];
    v_l_a1 uuid := 'aaaaaaaa-5b11-4000-8000-0000000000a1';
    v_l_a2 uuid := 'aaaaaaaa-5b11-4000-8000-0000000000a2';
    v_l_sold uuid := 'aaaaaaaa-5b11-4000-8000-0000000000a3';
    v_l_hidden uuid := 'aaaaaaaa-5b11-4000-8000-0000000000a4';
    v_l_archived uuid := 'aaaaaaaa-5b11-4000-8000-0000000000a5';
    v_l_b uuid := 'bbbbbbbb-5b11-4000-8000-0000000000b1';
    v_listing public.listings;
    v_row record;
    v_port record;
    v_n integer;
    v_case record;
    v_i integer;
    v_seen uuid[];
begin
    delete from public.saved_searches
     where user_id in (
        v_dealer_a, v_dealer_b, v_private, v_empty, v_buyers[1], v_buyers[2],
        v_buyers[3], v_buyers[4], v_buyers[5], v_buyers[6]
     );
    delete from public.listings
     where id in (v_l_a1, v_l_a2, v_l_sold, v_l_hidden, v_l_archived, v_l_b);
    delete from public.seller_profiles
     where user_id in (v_dealer_a, v_dealer_b, v_private, v_empty);
    delete from auth.users
     where id in (
        v_dealer_a, v_dealer_b, v_private, v_empty, v_buyers[1], v_buyers[2],
        v_buyers[3], v_buyers[4], v_buyers[5], v_buyers[6]
     );

    insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at
    ) values
        ('00000000-0000-0000-0000-000000000000', v_dealer_a, 'authenticated', 'authenticated',
         'd5b_a@carzon.demand.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_dealer_b, 'authenticated', 'authenticated',
         'd5b_b@carzon.demand.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_private, 'authenticated', 'authenticated',
         'd5b_p@carzon.demand.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_empty, 'authenticated', 'authenticated',
         'd5b_e@carzon.demand.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

    for v_i in 1..6 loop
        insert into auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
            created_at, updated_at
        ) values (
            '00000000-0000-0000-0000-000000000000', v_buyers[v_i], 'authenticated', 'authenticated',
            'd5b_c' || v_i::text || '@carzon.demand.test', crypt('x', gen_salt('bf')), now(),
            '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
        );
    end loop;

    insert into public.seller_profiles (user_id, seller_type, verified_dealer, member_since)
    values
        (v_dealer_a, 'dealer', true, now()),
        (v_dealer_b, 'dealer', false, now()),
        (v_private, 'private', true, now()),
        (v_empty, 'dealer', false, now());

    insert into public.listings (
        id, title, make, model, year, price_eur, mileage_km, type, city,
        market_region, seller_id, status, view_count, body_type, fuel_type,
        transmission_type, drivetrain, price_currency
    ) values
        (v_l_a1, 'Toyota RAV4 Limited', 'Toyota', 'RAV4', 2020, 20000, 50000, 'sale',
         'Chisinau', 'moldova', v_dealer_a, 'active', 0, 'suv', 'petrol',
         'automatic', 'four_wheel', 'eur'),
        (v_l_a2, 'Honda Civic', 'Honda', 'Civic', 2018, 9000, 12000, 'sale',
         'Chisinau', 'moldova', v_dealer_a, 'active', 0, null, null,
         null, null, 'eur'),
        (v_l_sold, 'Sold Car', 'VW', 'Passat', 2018, 8000, 13000, 'sale',
         'Chisinau', 'moldova', v_dealer_a, 'sold', 0, null, null, null, null, 'eur'),
        (v_l_hidden, 'Hidden Car', 'VW', 'Polo', 2017, 7000, 14000, 'sale',
         'Chisinau', 'moldova', v_dealer_a, 'hidden', 0, null, null, null, null, 'eur'),
        (v_l_archived, 'Archived Car', 'VW', 'Jetta', 2016, 6000, 15000, 'sale',
         'Chisinau', 'moldova', v_dealer_a, 'archived', 0, null, null, null, null, 'eur'),
        (v_l_b, 'BMW 3', 'BMW', '3', 2020, 20000, 5000, 'sale',
         'Chisinau', 'moldova', v_dealer_b, 'active', 0, null, null, null, null, 'eur');

    -- Grants / matcher still internal
    if has_function_privilege(
           'anon',
           'public.get_my_seller_listing_demand()',
           'EXECUTE'
       )
       or has_function_privilege(
           'anon',
           'public.get_my_seller_inventory_demand()',
           'EXECUTE'
       )
       or not has_function_privilege(
           'authenticated',
           'public.get_my_seller_listing_demand()',
           'EXECUTE'
       )
       or has_function_privilege(
           'authenticated',
           'public.listing_matches_saved_discovery_criteria(public.listings, jsonb)',
           'EXECUTE'
       )
    then
        raise exception 'demand RPC grants or matcher exposure incorrect';
    end if;

    -- Anonymous rejected
    perform set_config('request.jwt.claim.sub', '', true);
    perform set_config('request.jwt.claims', '', true);
    begin
        perform * from public.get_my_seller_listing_demand();
        raise exception 'anon listing demand must be rejected';
    exception
        when others then
            if sqlstate <> '28000' then
                raise;
            end if;
    end;
    begin
        perform * from public.get_my_seller_inventory_demand();
        raise exception 'anon inventory demand must be rejected';
    exception
        when others then
            if sqlstate <> '28000' then
                raise;
            end if;
    end;

    -- Private seller rejected even if verified_dealer
    perform set_config('request.jwt.claim.sub', v_private::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_private, 'role', 'authenticated')::text,
        true
    );
    begin
        perform * from public.get_my_seller_listing_demand();
        raise exception 'private listing demand must be rejected';
    exception
        when others then
            if sqlstate <> '42501' then
                raise;
            end if;
    end;
    begin
        perform * from public.get_my_seller_inventory_demand();
        raise exception 'private inventory demand must be rejected';
    exception
        when others then
            if sqlstate <> '42501' then
                raise;
            end if;
    end;

    -- Missing seller_profiles row rejected; demand must not auto-create it.
    perform set_config('request.jwt.claim.sub', v_buyers[1]::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_buyers[1], 'role', 'authenticated')::text,
        true
    );
    begin
        perform * from public.get_my_seller_listing_demand();
        raise exception 'missing seller profile listing demand must be rejected';
    exception
        when others then
            if sqlstate <> '42501' then
                raise;
            end if;
    end;
    begin
        perform * from public.get_my_seller_inventory_demand();
        raise exception 'missing seller profile inventory demand must be rejected';
    exception
        when others then
            if sqlstate <> '42501' then
                raise;
            end if;
    end;
    if exists (
        select 1 from public.seller_profiles sp where sp.user_id = v_buyers[1]
    ) then
        raise exception 'demand RPCs must not insert seller_profiles';
    end if;

    -- Unverified professional is allowed
    perform set_config('request.jwt.claim.sub', v_dealer_b::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_dealer_b, 'role', 'authenticated')::text,
        true
    );
    select count(*) into v_n from public.get_my_seller_listing_demand();
    if v_n <> 1 then
        raise exception 'unverified dealer must see own active listing, got %', v_n;
    end if;
    if exists (
        select 1 from public.get_my_seller_listing_demand() d
         where d.listing_id is distinct from v_l_b
    ) then
        raise exception 'dealer B saw another seller listing';
    end if;
    select * into v_port from public.get_my_seller_inventory_demand();
    if v_port.matching_users is distinct from 0 or v_port.is_suppressed then
        raise exception 'dealer B empty demand expected 0';
    end if;

    -- Empty dealer inventory
    perform set_config('request.jwt.claim.sub', v_empty::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_empty, 'role', 'authenticated')::text,
        true
    );
    if exists (select 1 from public.get_my_seller_listing_demand()) then
        raise exception 'empty dealer listing demand must have zero rows';
    end if;
    select * into v_port from public.get_my_seller_inventory_demand();
    if v_port.matching_users is distinct from 0 or v_port.is_suppressed then
        raise exception 'empty dealer portfolio must be visible zero';
    end if;

    -- Dealer A: status filter + zero demand
    perform set_config('request.jwt.claim.sub', v_dealer_a::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_dealer_a, 'role', 'authenticated')::text,
        true
    );
    select array_agg(d.listing_id order by d.listing_id) into v_seen
      from public.get_my_seller_listing_demand() d;
    if v_seen is distinct from array[v_l_a1, v_l_a2] then
        raise exception 'dealer A rows must be active listings only, got %', v_seen;
    end if;
    if exists (
        select 1 from public.get_my_seller_listing_demand() d
         where d.matching_users is distinct from 0
            or d.is_suppressed
    ) then
        raise exception 'zero external searches must be visible zeros';
    end if;
    select * into v_port from public.get_my_seller_inventory_demand();
    if v_port.matching_users is distinct from 0 or v_port.is_suppressed then
        raise exception 'portfolio zero expected';
    end if;

    -- Own search does not count; alerts_enabled true is still excluded
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    values (
        v_dealer_a,
        'Own Toyota',
        '{"schemaVersion":1,"make":"Toyota"}'::jsonb,
        true
    );
    select * into v_row
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a1;
    if v_row.matching_users is distinct from 0 or v_row.is_suppressed then
        raise exception 'own search must not contribute, got % %',
            v_row.matching_users, v_row.is_suppressed;
    end if;

    -- Threshold 1 → suppressed. alerts_enabled false still eligible.
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    values (
        v_buyers[1],
        'B1 Toyota',
        '{"schemaVersion":1,"make":"Toyota"}'::jsonb,
        false
    );
    select * into v_row
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a1;
    if v_row.matching_users is not null or v_row.is_suppressed is not true then
        raise exception '1 user must be suppressed, got % %',
            v_row.matching_users, v_row.is_suppressed;
    end if;
    select * into v_port from public.get_my_seller_inventory_demand();
    if v_port.matching_users is not null or v_port.is_suppressed is not true then
        raise exception 'portfolio 1 user must be suppressed';
    end if;

    -- One user, five overlapping matching searches still counts as 1
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    select v_buyers[1],
           'B1 overlap ' || g::text,
           jsonb_build_object('schemaVersion', 1, 'make', 'Toyota', 'minYear', 1990 + g),
           false
      from generate_series(1, 4) g;
    select * into v_row
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a1;
    if v_row.matching_users is not null or v_row.is_suppressed is not true then
        raise exception 'overlapping searches must still suppress as 1 user';
    end if;

    -- 4 unique users → still suppressed
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    select v_buyers[v_i],
           'Bn Toyota',
           '{"schemaVersion":1,"make":"Toyota"}'::jsonb,
           false
      from generate_series(2, 4) v_i;
    select * into v_row
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a1;
    if v_row.matching_users is not null or v_row.is_suppressed is not true then
        raise exception '4 users must be suppressed, got % %',
            v_row.matching_users, v_row.is_suppressed;
    end if;

    -- 5 unique users → visible 5
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    values (
        v_buyers[5],
        'B5 Toyota',
        '{"schemaVersion":1,"make":"Toyota"}'::jsonb,
        false
    );
    select * into v_row
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a1;
    if v_row.matching_users is distinct from 5 or v_row.is_suppressed then
        raise exception '5 users must be visible 5, got % %',
            v_row.matching_users, v_row.is_suppressed;
    end if;
    select * into v_row
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a2;
    if v_row.matching_users is distinct from 0 or v_row.is_suppressed then
        raise exception 'Honda listing must stay zero';
    end if;

    -- 6 users with extra overlapping searches → 6, not search-row count
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    values
        (v_buyers[6], 'B6 Toyota', '{"schemaVersion":1,"make":"Toyota"}'::jsonb, false),
        (v_buyers[5], 'B5 extra', '{"schemaVersion":1,"make":"Toyota","model":"RAV4"}'::jsonb, false);
    select * into v_row
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a1;
    if v_row.matching_users is distinct from 6 or v_row.is_suppressed then
        raise exception '6 users must be 6 not search count, got %', v_row.matching_users;
    end if;
    select * into v_port from public.get_my_seller_inventory_demand();
    if v_port.matching_users is distinct from 6 or v_port.is_suppressed then
        raise exception 'portfolio 6 expected, got % %',
            v_port.matching_users, v_port.is_suppressed;
    end if;

    -- Same user matching both listings still 1 in portfolio (reset to 1 user on both)
    delete from public.saved_searches
     where user_id = any (v_buyers);
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    values
        (v_buyers[1], 'Both makes', '{"schemaVersion":1,"search":"Limited"}'::jsonb, false),
        (v_buyers[1], 'Honda search', '{"schemaVersion":1,"make":"Honda"}'::jsonb, false);
    select * into v_port from public.get_my_seller_inventory_demand();
    if v_port.matching_users is not null or v_port.is_suppressed is not true then
        raise exception 'one user across two listings must still suppress as 1';
    end if;
    select matching_users into v_n
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a1;
    if v_n is not null then
        raise exception 'listing A1 one user must be suppressed';
    end if;
    select matching_users into v_n
      from public.get_my_seller_listing_demand()
     where listing_id = v_l_a2;
    if v_n is not null then
        raise exception 'listing A2 one user must be suppressed';
    end if;

    -- Different users on different listings: still distinct after threshold
    delete from public.saved_searches where user_id = any (v_buyers);
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    select v_buyers[v_i],
           'Toyota ' || v_i::text,
           '{"schemaVersion":1,"make":"Toyota"}'::jsonb,
           false
      from generate_series(1, 3) v_i;
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    select v_buyers[v_i],
           'Honda ' || v_i::text,
           '{"schemaVersion":1,"make":"Honda"}'::jsonb,
           false
      from generate_series(4, 6) v_i;
    select * into v_port from public.get_my_seller_inventory_demand();
    if v_port.matching_users is distinct from 6 or v_port.is_suppressed then
        raise exception 'split listings must still unique-count 6 users, got %',
            v_port.matching_users;
    end if;
    select matching_users into v_n
      from public.get_my_seller_listing_demand() where listing_id = v_l_a1;
    if v_n is not null then
        raise exception '3 Toyota users must be suppressed on A1';
    end if;
    select matching_users into v_n
      from public.get_my_seller_listing_demand() where listing_id = v_l_a2;
    if v_n is not null then
        raise exception '3 Honda users must be suppressed on A2';
    end if;

    -- Matcher parity: 5 matching users + 1 miss that matches neither listing
    select l into v_listing from public.listings l where l.id = v_l_a1;
    for v_case in
        select * from (values
            ('make', '{"schemaVersion":1,"make":"Toyota"}'::jsonb,
                     '{"schemaVersion":1,"make":"Ferrari"}'::jsonb),
            ('model', '{"schemaVersion":1,"model":"RAV4"}'::jsonb,
                      '{"schemaVersion":1,"model":"XXXX"}'::jsonb),
            ('year', '{"schemaVersion":1,"minYear":2018,"maxYear":2022}'::jsonb,
                     '{"schemaVersion":1,"minYear":1990,"maxYear":1995}'::jsonb),
            ('price', '{"schemaVersion":1,"minPrice":10000,"maxPrice":30000}'::jsonb,
                      '{"schemaVersion":1,"minPrice":999999}'::jsonb),
            ('mileage', '{"schemaVersion":1,"maxMileage":80000}'::jsonb,
                        '{"schemaVersion":1,"maxMileage":1}'::jsonb),
            ('region', '{"schemaVersion":1,"marketRegion":"moldova"}'::jsonb,
                       '{"schemaVersion":1,"marketRegion":"transnistria"}'::jsonb),
            ('city', '{"schemaVersion":1,"city":"Chisinau"}'::jsonb,
                     '{"schemaVersion":1,"city":"Tiraspol"}'::jsonb),
            ('body', '{"schemaVersion":1,"bodyType":"suv"}'::jsonb,
                     '{"schemaVersion":1,"bodyType":"sedan"}'::jsonb),
            ('fuel', '{"schemaVersion":1,"fuelType":"petrol"}'::jsonb,
                     '{"schemaVersion":1,"fuelType":"diesel"}'::jsonb),
            ('transmission', '{"schemaVersion":1,"transmissionType":"automatic"}'::jsonb,
                             '{"schemaVersion":1,"transmissionType":"manual"}'::jsonb),
            ('drivetrain', '{"schemaVersion":1,"drivetrain":"four_wheel"}'::jsonb,
                           '{"schemaVersion":1,"drivetrain":"fwd"}'::jsonb),
            ('typeIn', '{"schemaVersion":1,"typeIn":["sale","both"]}'::jsonb,
                       '{"schemaVersion":1,"typeIn":["exchange"]}'::jsonb),
            ('currency', '{"schemaVersion":1,"priceCurrencyFilter":"eur"}'::jsonb,
                         '{"schemaVersion":1,"priceCurrencyFilter":"usd"}'::jsonb),
            ('search', '{"schemaVersion":1,"search":"RAV4"}'::jsonb,
                       '{"schemaVersion":1,"search":"ZZZZNOMATCH"}'::jsonb)
        ) as t(name, match_c, miss_c)
    loop
        if not public.listing_matches_saved_discovery_criteria(v_listing, v_case.match_c) then
            raise exception 'matcher must accept %', v_case.name;
        end if;
        if public.listing_matches_saved_discovery_criteria(v_listing, v_case.miss_c) then
            raise exception 'matcher must reject miss for %', v_case.name;
        end if;

        delete from public.saved_searches where user_id = any (v_buyers);
        insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
        select v_buyers[v_i],
               'match ' || v_case.name,
               v_case.match_c,
               false
          from generate_series(1, 5) v_i;
        insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
        values (v_buyers[6], 'miss ' || v_case.name, v_case.miss_c, false);

        select * into v_row
          from public.get_my_seller_listing_demand()
         where listing_id = v_l_a1;
        if v_row.matching_users is distinct from 5 or v_row.is_suppressed then
            raise exception 'demand mismatch for % got % %',
                v_case.name, v_row.matching_users, v_row.is_suppressed;
        end if;
        select * into v_port from public.get_my_seller_inventory_demand();
        if v_port.matching_users is distinct from 5 or v_port.is_suppressed then
            raise exception 'portfolio mismatch for % got %',
                v_case.name, v_port.matching_users;
        end if;
    end loop;

    -- Selling the matching listing drops it from current demand immediately
    delete from public.saved_searches where user_id = any (v_buyers);
    insert into public.saved_searches (user_id, name, criteria, alerts_enabled)
    select v_buyers[v_i],
           'Toyota live',
           '{"schemaVersion":1,"make":"Toyota"}'::jsonb,
           false
      from generate_series(1, 5) v_i;
    update public.listings
       set status = 'sold',
           sold_at = now()
     where id = v_l_a1;
    if exists (
        select 1 from public.get_my_seller_listing_demand() d
         where d.listing_id = v_l_a1
    ) then
        raise exception 'sold listing must leave current demand';
    end if;
    select * into v_port from public.get_my_seller_inventory_demand();
    if v_port.matching_users is distinct from 0 or v_port.is_suppressed then
        raise exception 'portfolio after sale must be 0, got % %',
            v_port.matching_users, v_port.is_suppressed;
    end if;
    if exists (select 1 from public.saved_searches where user_id = v_buyers[1]) then
        null;
    else
        raise exception 'saved searches must not be deleted on listing status change';
    end if;

    -- Seller cannot SELECT another user's saved searches
    perform set_config('request.jwt.claim.sub', v_dealer_a::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_dealer_a, 'role', 'authenticated')::text,
        true
    );
    execute 'set role authenticated';
    execute 'select count(*) from public.saved_searches where user_id = $1'
       into v_n
      using v_buyers[1];
    execute 'reset role';
    if v_n <> 0 then
        raise exception 'seller must not read buyer saved searches, got %', v_n;
    end if;

    -- cleanup
    delete from public.saved_searches
     where user_id in (
        v_dealer_a, v_dealer_b, v_private, v_empty, v_buyers[1], v_buyers[2],
        v_buyers[3], v_buyers[4], v_buyers[5], v_buyers[6]
     );
    delete from public.listings
     where id in (v_l_a1, v_l_a2, v_l_sold, v_l_hidden, v_l_archived, v_l_b);
    delete from public.seller_profiles
     where user_id in (v_dealer_a, v_dealer_b, v_private, v_empty);
    delete from auth.users
     where id in (
        v_dealer_a, v_dealer_b, v_private, v_empty, v_buyers[1], v_buyers[2],
        v_buyers[3], v_buyers[4], v_buyers[5], v_buyers[6]
     );
end;
$$;
