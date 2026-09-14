-- Local-only listing engagement telemetry fixtures. Isolated emails/titles.
-- Requires repository migrations applied. Safe to re-run.

do $$
declare
    v_seller_a uuid := 'aaaaaaaa-0000-4000-8000-0000000004a1';
    v_seller_b uuid := 'bbbbbbbb-0000-4000-8000-0000000004b1';
    v_buyer uuid := '11111111-0000-4000-8000-0000000004c1';
    v_empty uuid := 'eeeeeeee-0000-4000-8000-0000000004e1';
    v_listing_active uuid := 'aaaaaaaa-1111-4000-8000-0000000004a1';
    v_listing_sold uuid := 'aaaaaaaa-1111-4000-8000-0000000004a2';
    v_listing_hidden uuid := 'aaaaaaaa-1111-4000-8000-0000000004a3';
    v_listing_archived uuid := 'aaaaaaaa-1111-4000-8000-0000000004a4';
    v_listing_b uuid := 'bbbbbbbb-1111-4000-8000-0000000004b1';
    v_missing uuid := 'ffffffff-1111-4000-8000-0000000004ff';
    v_today date := (now() at time zone 'Europe/Chisinau')::date;
    v_old date := v_today - 20;
    v_recorded boolean;
    v_count integer;
    v_recorded_2 boolean;
    v_count_2 integer;
    v_summary record;
    v_row record;
    v_listings_count integer;
    v_hash_count integer;
    v_err text;
begin
    delete from public.listings
     where id in (
        v_listing_active, v_listing_sold, v_listing_hidden,
        v_listing_archived, v_listing_b
     );
    delete from public.seller_profiles
     where user_id in (v_seller_a, v_seller_b, v_empty, v_buyer);
    delete from auth.users
     where id in (v_seller_a, v_seller_b, v_buyer, v_empty);

    insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at
    ) values
        ('00000000-0000-0000-0000-000000000000', v_seller_a, 'authenticated', 'authenticated',
         'le4a_a@carzon.engagement.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_seller_b, 'authenticated', 'authenticated',
         'le4a_b@carzon.engagement.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_buyer, 'authenticated', 'authenticated',
         'le4a_c@carzon.engagement.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_empty, 'authenticated', 'authenticated',
         'le4a_empty@carzon.engagement.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

    insert into public.listings (
        id, title, make, model, year, price_eur, mileage_km, type, city,
        market_region, seller_id, status, view_count
    ) values
        (v_listing_active, 'LE4A Active', 'VW', 'Golf', 2019, 10000, 10000, 'sale', 'Chisinau',
         'moldova', v_seller_a, 'active', 0),
        (v_listing_sold, 'LE4A Sold', 'VW', 'Passat', 2018, 9000, 12000, 'sale', 'Chisinau',
         'moldova', v_seller_a, 'sold', 0),
        (v_listing_hidden, 'LE4A Hidden', 'VW', 'Polo', 2017, 8000, 13000, 'sale', 'Chisinau',
         'moldova', v_seller_a, 'hidden', 0),
        (v_listing_archived, 'LE4A Archived', 'VW', 'Jetta', 2016, 7000, 14000, 'sale', 'Chisinau',
         'moldova', v_seller_a, 'archived', 0),
        (v_listing_b, 'LE4A Other Seller', 'BMW', '3', 2020, 20000, 5000, 'sale', 'Chisinau',
         'moldova', v_seller_b, 'active', 0);

    -- Storage constraints
    begin
        insert into public.listing_engagement_daily (
            listing_id, event_date, event_type, event_count
        ) values (v_listing_active, v_today, 'view', 1);
        raise exception 'invalid taxonomy must be rejected';
    exception
        when check_violation then
            null;
        when others then
            if sqlstate <> '23514' then
                raise;
            end if;
    end;

    begin
        insert into public.listing_engagement_daily (
            listing_id, event_date, event_type, event_count
        ) values (v_listing_active, v_today, 'impression', -1);
        raise exception 'negative event_count must be rejected';
    exception
        when check_violation then
            null;
        when others then
            if sqlstate <> '23514' then
                raise;
            end if;
    end;

    insert into public.listing_engagement_dedupe (
        listing_id, event_date, event_type, viewer_hash
    ) values (v_listing_active, v_today, 'share', 'fixture-hash');
    begin
        insert into public.listing_engagement_dedupe (
            listing_id, event_date, event_type, viewer_hash
        ) values (v_listing_active, v_today, 'share', 'fixture-hash');
        raise exception 'duplicate dedupe key must be rejected';
    exception
        when unique_violation then
            null;
    end;
    delete from public.listing_engagement_dedupe
     where listing_id = v_listing_active and viewer_hash = 'fixture-hash';

    if has_table_privilege('anon', 'public.listing_engagement_daily', 'SELECT')
       or has_table_privilege('authenticated', 'public.listing_engagement_daily', 'SELECT')
       or has_table_privilege('anon', 'public.listing_engagement_dedupe', 'SELECT')
       or has_table_privilege('authenticated', 'public.listing_engagement_dedupe', 'SELECT')
       or has_table_privilege('anon', 'public.listing_engagement_daily', 'INSERT')
       or has_table_privilege('authenticated', 'public.listing_engagement_daily', 'INSERT')
    then
        raise exception 'clients must not directly read/write engagement tables';
    end if;

    -- Anonymous recording
    perform set_config('request.jwt.claim.sub', '', true);
    perform set_config('request.jwt.claims', '', true);

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'impression', 'anon-viewer-1'
      ) r;
    if v_recorded is not true or v_count <> 1 then
        raise exception 'first anon impression must record, got % %', v_recorded, v_count;
    end if;

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'impression', 'anon-viewer-1'
      ) r;
    if v_recorded is not false or v_count <> 1 then
        raise exception 'repeat anon impression must not increment, got % %',
            v_recorded, v_count;
    end if;

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'whatsapp', 'anon-viewer-1'
      ) r;
    if v_recorded is not true or v_count <> 1 then
        raise exception 'same viewer different type must be independent';
    end if;

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_b, 'impression', 'anon-viewer-1'
      ) r;
    if v_recorded is not true or v_count <> 1 then
        raise exception 'same viewer different listing must be independent';
    end if;

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'phone', ''
      ) r;
    if v_recorded is not false or v_count <> 0 then
        raise exception 'blank anonymous viewer must not increment';
    end if;

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'phone', null
      ) r;
    if v_recorded is not false or v_count <> 0 then
        raise exception 'null anonymous viewer must not increment';
    end if;

    -- Authenticated buyer
    perform set_config('request.jwt.claim.sub', v_buyer::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_buyer, 'role', 'authenticated')::text,
        true
    );
    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'telegram', 'ignored-anon'
      ) r;
    if v_recorded is not true or v_count <> 1 then
        raise exception 'authenticated buyer must record';
    end if;
    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'telegram', 'ignored-anon'
      ) r;
    if v_recorded is not false or v_count <> 1 then
        raise exception 'authenticated repeat must dedupe';
    end if;

    -- Seller self-interaction
    perform set_config('request.jwt.claim.sub', v_seller_a::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_seller_a, 'role', 'authenticated')::text,
        true
    );
    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'share', null
      ) r;
    if v_recorded is not false then
        raise exception 'seller must not record own listing';
    end if;
    if exists (
        select 1
          from public.listing_engagement_daily
         where listing_id = v_listing_active
           and event_type = 'share'
           and event_date = v_today
    ) then
        raise exception 'seller self-share must not create a daily row';
    end if;

    -- Listing eligibility
    perform set_config('request.jwt.claim.sub', '', true);
    perform set_config('request.jwt.claims', '', true);

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_hidden, 'impression', 'anon-viewer-1'
      ) r;
    if v_recorded is not false or v_count <> 0 then
        raise exception 'hidden listing must not record';
    end if;

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_sold, 'impression', 'anon-viewer-1'
      ) r;
    if v_recorded is not false or v_count <> 0 then
        raise exception 'sold listing must not record new events';
    end if;

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_archived, 'impression', 'anon-viewer-1'
      ) r;
    if v_recorded is not false or v_count <> 0 then
        raise exception 'archived listing must not record';
    end if;

    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_missing, 'impression', 'anon-viewer-1'
      ) r;
    if v_recorded is not false or v_count <> 0 then
        raise exception 'missing listing must not leak or record';
    end if;

    begin
        perform public.record_listing_engagement_event(
            v_listing_active, 'view', 'anon-viewer-1'
        );
        raise exception 'view event type must be rejected';
    exception
        when others then
            if sqlstate <> '22023' then
                raise;
            end if;
    end;

    -- Concurrent-equivalent sequential duplicates stay unique
    select r.recorded, r.today_count
      into v_recorded, v_count
      from public.record_listing_engagement_event(
          v_listing_active, 'phone', 'anon-viewer-2'
      ) r;
    select r.recorded, r.today_count
      into v_recorded_2, v_count_2
      from public.record_listing_engagement_event(
          v_listing_active, 'phone', 'anon-viewer-2'
      ) r;
    if v_recorded is not true or v_recorded_2 is not false or v_count_2 <> 1 then
        raise exception 'equivalent inserts must increment at most once: % % % %',
            v_recorded, v_count, v_recorded_2, v_count_2;
    end if;

    -- Historical sold engagement remains reportable; hidden/archived excluded
    insert into public.listing_engagement_daily (
        listing_id, event_date, event_type, event_count
    ) values
        (v_listing_sold, v_today, 'impression', 5),
        (v_listing_sold, v_old, 'phone', 2),
        (v_listing_hidden, v_today, 'impression', 80),
        (v_listing_archived, v_today, 'whatsapp', 70),
        (v_listing_b, v_today, 'phone', 40);

    perform set_config('request.jwt.claim.sub', v_seller_a::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_seller_a, 'role', 'authenticated')::text,
        true
    );

    select * into v_summary
      from public.get_my_seller_engagement_summary(7);
    -- active today: impression 1, whatsapp 1, telegram 1, phone 1
    -- sold today: impression 5; sold old phone excluded from 7d
    if v_summary.period_impressions <> 6
       or v_summary.period_phone_actions <> 1
       or v_summary.period_whatsapp_actions <> 1
       or v_summary.period_telegram_actions <> 1
       or v_summary.period_shares <> 0 then
        raise exception 'seller A 7d summary mismatch: % % % % %',
            v_summary.period_impressions,
            v_summary.period_phone_actions,
            v_summary.period_whatsapp_actions,
            v_summary.period_telegram_actions,
            v_summary.period_shares;
    end if;

    select * into v_summary
      from public.get_my_seller_engagement_summary(30);
    if v_summary.period_phone_actions <> 3 then
        raise exception '30d must include sold historical phone=2 + today phone=1, got %',
            v_summary.period_phone_actions;
    end if;

    begin
        perform public.get_my_seller_engagement_summary(14);
        raise exception 'invalid period must be rejected';
    exception
        when others then
            if sqlstate <> '22023' then
                raise;
            end if;
    end;

    select count(*) into v_listings_count
      from public.get_my_seller_engagement_listings(7);
    if v_listings_count <> 2 then
        raise exception 'listings RPC must return active+sold only, got %', v_listings_count;
    end if;

    select * into v_row
      from public.get_my_seller_engagement_listings(7)
     where listing_id = v_listing_sold;
    if v_row.period_impressions <> 5 or v_row.period_phone_actions <> 0 then
        raise exception 'sold listing 7d must keep today impressions and exclude old phone';
    end if;

    if exists (
        select 1
          from public.get_my_seller_engagement_listings(7)
         where listing_id in (v_listing_hidden, v_listing_archived, v_listing_b)
    ) then
        raise exception 'hidden/archived/other-seller listings must be excluded';
    end if;

    perform set_config('request.jwt.claim.sub', v_seller_b::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_seller_b, 'role', 'authenticated')::text,
        true
    );
    select * into v_summary
      from public.get_my_seller_engagement_summary(7);
    if v_summary.period_impressions <> 1 or v_summary.period_phone_actions <> 40 then
        raise exception 'seller B must not see seller A totals: % %',
            v_summary.period_impressions, v_summary.period_phone_actions;
    end if;

    perform set_config('request.jwt.claim.sub', v_empty::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_empty, 'role', 'authenticated')::text,
        true
    );
    select * into v_summary
      from public.get_my_seller_engagement_summary(90);
    if v_summary.period_impressions <> 0
       or v_summary.period_phone_actions <> 0
       or v_summary.period_whatsapp_actions <> 0
       or v_summary.period_telegram_actions <> 0
       or v_summary.period_shares <> 0 then
        raise exception 'empty seller must return zeros';
    end if;

    perform set_config('request.jwt.claim.sub', '', true);
    perform set_config('request.jwt.claims', '', true);
    begin
        perform public.get_my_seller_engagement_summary(7);
        raise exception 'anonymous seller summary must be rejected';
    exception
        when others then
            if sqlstate <> '28000' then
                raise;
            end if;
    end;

    select count(*) into v_hash_count
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'listing_engagement_dedupe'
       and column_name = 'viewer_hash';
    if v_hash_count <> 1 then
        raise exception 'dedupe viewer_hash column missing';
    end if;
    if exists (
        select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public'
           and p.proname in (
                'get_my_seller_engagement_summary',
                'get_my_seller_engagement_listings',
                'record_listing_engagement_event'
           )
           and pg_get_function_result(p.oid) ilike '%viewer_hash%'
    ) then
        raise exception 'client RPCs must not return viewer_hash';
    end if;

    -- Cascade
    delete from public.listings where id = v_listing_b;
    if exists (
        select 1 from public.listing_engagement_daily where listing_id = v_listing_b
    ) or exists (
        select 1 from public.listing_engagement_dedupe where listing_id = v_listing_b
    ) then
        raise exception 'listing delete must cascade engagement rows';
    end if;

    -- Cleanup remaining fixtures
    delete from public.listings
     where id in (
        v_listing_active, v_listing_sold, v_listing_hidden, v_listing_archived
     );
    delete from public.seller_profiles
     where user_id in (v_seller_a, v_seller_b, v_empty, v_buyer);
    delete from auth.users
     where id in (v_seller_a, v_seller_b, v_buyer, v_empty);
end;
$$;
