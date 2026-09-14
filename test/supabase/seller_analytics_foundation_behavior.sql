-- Local-only Seller Analytics Phase 1 fixtures. Isolated emails/titles.
-- Requires repository migrations applied. Safe to re-run.

do $$
declare
    v_seller_a uuid := 'aaaaaaaa-0000-4000-8000-0000000000a1';
    v_seller_b uuid := 'bbbbbbbb-0000-4000-8000-0000000000b1';
    v_buyer_1 uuid := '11111111-0000-4000-8000-0000000000c1';
    v_buyer_2 uuid := '22222222-0000-4000-8000-0000000000c2';
    v_empty uuid := 'eeeeeeee-0000-4000-8000-0000000000e1';
    v_listing_active uuid := 'aaaaaaaa-1111-4000-8000-0000000000a1';
    v_listing_sold uuid := 'aaaaaaaa-1111-4000-8000-0000000000a2';
    v_listing_hidden uuid := 'aaaaaaaa-1111-4000-8000-0000000000a3';
    v_listing_archived uuid := 'aaaaaaaa-1111-4000-8000-0000000000a4';
    v_listing_b uuid := 'bbbbbbbb-1111-4000-8000-0000000000b1';
    v_conv_empty uuid := 'aaaaaaaa-2222-4000-8000-0000000000d1';
    v_conv_seller_only uuid := 'aaaaaaaa-2222-4000-8000-0000000000d2';
    v_conv_buyer uuid := 'aaaaaaaa-2222-4000-8000-0000000000d3';
    v_conv_buyer_2 uuid := 'aaaaaaaa-2222-4000-8000-0000000000d4';
    v_conv_old uuid := 'aaaaaaaa-2222-4000-8000-0000000000d5';
    v_today date := (now() at time zone 'Europe/Chisinau')::date;
    v_old date := v_today - 20;
    v_summary record;
    v_daily_count integer;
    v_zero_days integer;
    v_listings_count integer;
    v_b_views integer;
    v_type text;
    v_verified boolean;
    v_sold_at timestamptz;
    v_sold_at_2 timestamptz;
    v_err text;
begin
    delete from public.listings
     where id in (
        v_listing_active, v_listing_sold, v_listing_hidden,
        v_listing_archived, v_listing_b
     );
    delete from public.seller_profiles
     where user_id in (v_seller_a, v_seller_b, v_empty);
    delete from auth.users
     where id in (v_seller_a, v_seller_b, v_buyer_1, v_buyer_2, v_empty);

    insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at
    ) values
        ('00000000-0000-0000-0000-000000000000', v_seller_a, 'authenticated', 'authenticated',
         'sa1_a@carzon.analytics.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_seller_b, 'authenticated', 'authenticated',
         'sa1_b@carzon.analytics.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_buyer_1, 'authenticated', 'authenticated',
         'sa1_c1@carzon.analytics.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_buyer_2, 'authenticated', 'authenticated',
         'sa1_c2@carzon.analytics.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
        ('00000000-0000-0000-0000-000000000000', v_empty, 'authenticated', 'authenticated',
         'sa1_empty@carzon.analytics.test', crypt('x', gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

    insert into public.seller_profiles (user_id, seller_type, verified_dealer, member_since)
    values
        (v_seller_a, 'private', true, now()),
        (v_seller_b, 'private', false, now());

    insert into public.listings (
        id, title, make, model, year, price_eur, mileage_km, type, city,
        market_region, seller_id, status, view_count
    ) values
        (v_listing_active, 'SA1 Active', 'VW', 'Golf', 2019, 10000, 10000, 'sale', 'Chisinau',
         'moldova', v_seller_a, 'active', 999),
        (v_listing_sold, 'SA1 Sold', 'VW', 'Passat', 2018, 9000, 12000, 'sale', 'Chisinau',
         'moldova', v_seller_a, 'sold', 0),
        (v_listing_hidden, 'SA1 Hidden', 'VW', 'Polo', 2017, 8000, 13000, 'sale', 'Chisinau',
         'moldova', v_seller_a, 'hidden', 0),
        (v_listing_archived, 'SA1 Archived', 'VW', 'Jetta', 2016, 7000, 14000, 'sale', 'Chisinau',
         'moldova', v_seller_a, 'archived', 0),
        (v_listing_b, 'SA1 Other Seller', 'BMW', '3', 2020, 20000, 5000, 'sale', 'Chisinau',
         'moldova', v_seller_b, 'active', 50);

    -- Hidden/archived/other-seller daily views must not leak into seller A.
    insert into public.listing_view_daily (listing_id, view_date, view_count)
    values
        (v_listing_active, v_today, 4),
        (v_listing_active, v_today - 1, 3),
        (v_listing_sold, v_today, 2),
        (v_listing_hidden, v_today, 80),
        (v_listing_archived, v_today, 70),
        (v_listing_b, v_today, 60);

    insert into public.favorites (user_id, listing_id)
    values
        (v_buyer_1, v_listing_active),
        (v_buyer_2, v_listing_active),
        (v_buyer_1, v_listing_sold),
        (v_buyer_1, v_listing_hidden),
        (v_buyer_1, v_listing_b);

    insert into public.conversations (
        id, listing_id, buyer_id, seller_id, conversation_kind
    ) values
        (v_conv_empty, v_listing_active, v_buyer_1, v_seller_a, 'listing'),
        (v_conv_seller_only, v_listing_active, v_buyer_2, v_seller_a, 'listing'),
        (v_conv_old, v_listing_sold, v_buyer_1, v_seller_a, 'listing');

    -- Unique (listing_id, buyer_id) — second buyer inquiry on sold listing.
    insert into public.conversations (
        id, listing_id, buyer_id, seller_id, conversation_kind
    ) values
        (v_conv_buyer, v_listing_sold, v_buyer_2, v_seller_a, 'listing');

    insert into public.messages (conversation_id, sender_id, body, created_at)
    values
        (v_conv_seller_only, v_seller_a, 'seller only', now()),
        (v_conv_buyer, v_buyer_2, 'first buyer', now()),
        (v_conv_buyer, v_buyer_2, 'second buyer same thread', now()),
        (v_conv_old, v_buyer_1, 'old inquiry', (v_old::timestamp at time zone 'Europe/Chisinau'));

    perform set_config('request.jwt.claim.sub', v_seller_a::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_seller_a, 'role', 'authenticated')::text,
        true
    );

    -- sold_at lifecycle
    update public.listings set sold_at = null where id = v_listing_active;
    perform public.set_listing_status(v_listing_active, 'sold');
    select sold_at into v_sold_at from public.listings where id = v_listing_active;
    if v_sold_at is null then
        raise exception 'active → sold must set sold_at';
    end if;

    perform public.set_listing_status(v_listing_active, 'sold');
    select sold_at into v_sold_at_2 from public.listings where id = v_listing_active;
    if v_sold_at_2 is distinct from v_sold_at then
        raise exception 'sold → sold must preserve sold_at';
    end if;

    perform public.set_listing_status(v_listing_active, 'active');
    select sold_at into v_sold_at from public.listings where id = v_listing_active;
    if v_sold_at is not null then
        raise exception 'sold → active must clear sold_at';
    end if;

    perform public.set_listing_status(v_listing_active, 'sold');
    perform public.set_listing_status(v_listing_active, 'hidden');
    select sold_at, status into v_sold_at, v_type
      from public.listings where id = v_listing_active;
    if v_sold_at is not null or v_type <> 'hidden' then
        raise exception 'sold → hidden must clear sold_at';
    end if;

    perform public.set_listing_status(v_listing_active, 'sold');
    perform public.set_listing_status(v_listing_active, 'archived');
    select sold_at into v_sold_at from public.listings where id = v_listing_active;
    if v_sold_at is not null then
        raise exception 'sold → archived must clear sold_at';
    end if;

    perform public.set_listing_status(v_listing_active, 'active');
    perform public.set_listing_status(v_listing_active, 'hidden');
    select sold_at into v_sold_at from public.listings where id = v_listing_active;
    if v_sold_at is not null then
        raise exception 'active → hidden must not invent sold_at';
    end if;
    perform public.set_listing_status(v_listing_active, 'active');

    begin
        perform set_config('request.jwt.claim.sub', v_seller_b::text, true);
        perform set_config(
            'request.jwt.claims',
            json_build_object('sub', v_seller_b, 'role', 'authenticated')::text,
            true
        );
        perform public.set_listing_status(v_listing_active, 'sold');
        raise exception 'seller B must not change seller A listing';
    exception
        when others then
            if sqlerrm not like '%not owned%' then
                raise;
            end if;
    end;

    perform set_config('request.jwt.claim.sub', v_seller_a::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_seller_a, 'role', 'authenticated')::text,
        true
    );

    -- seller mode
    select s.seller_type, s.verified_dealer
      into v_type, v_verified
      from public.set_my_seller_type('dealer') s;
    if v_type <> 'dealer' or v_verified is not true then
        raise exception 'private → dealer failed or mutated verified_dealer: % %', v_type, v_verified;
    end if;
    select s.seller_type, s.verified_dealer
      into v_type, v_verified
      from public.set_my_seller_type('private') s;
    if v_type <> 'private' or v_verified is not true then
        raise exception 'dealer → private failed or mutated verified_dealer';
    end if;

    begin
        perform public.set_my_seller_type('shop');
        raise exception 'invalid seller type must be rejected';
    exception
        when others then
            if sqlstate <> '22023' then
                raise;
            end if;
    end;

    perform set_config('request.jwt.claim.sub', '', true);
    perform set_config('request.jwt.claims', '', true);
    begin
        perform public.set_my_seller_type('dealer');
        raise exception 'anonymous set_my_seller_type must be rejected';
    exception
        when others then
            if sqlstate <> '28000' then
                raise;
            end if;
    end;

    perform set_config('request.jwt.claim.sub', v_seller_b::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_seller_b, 'role', 'authenticated')::text,
        true
    );
    perform public.set_my_seller_type('dealer');
    select * into v_summary from public.get_my_seller_analytics_summary(7);
    if v_summary.seller_type is distinct from 'dealer'
       or v_summary.verified_dealer is not false then
        raise exception 'existing dealer profile must surface dealer/unverified: % %',
            v_summary.seller_type, v_summary.verified_dealer;
    end if;
    if exists (
        select 1 from public.seller_profiles
         where user_id = v_seller_a and seller_type = 'dealer'
    ) then
        raise exception 'seller B must not change seller A type';
    end if;
    if (select verified_dealer from public.seller_profiles where user_id = v_seller_a) is not true then
        raise exception 'verified_dealer on A changed unexpectedly';
    end if;
    perform public.set_my_seller_type('private');

    perform set_config('request.jwt.claim.sub', v_seller_a::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_seller_a, 'role', 'authenticated')::text,
        true
    );

    select * into v_summary
      from public.get_my_seller_analytics_summary(7);

    if v_summary.seller_type is distinct from 'private'
       or v_summary.verified_dealer is not true then
        raise exception 'existing private profile must surface actual type/verified: % %',
            v_summary.seller_type, v_summary.verified_dealer;
    end if;
    if v_summary.active_count <> 1 or v_summary.sold_count <> 1 then
        raise exception 'inventory counts % %', v_summary.active_count, v_summary.sold_count;
    end if;
    if v_summary.period_views <> 9 then
        raise exception 'period views must be 4+3+2=9 from daily, not lifetime 999; got %',
            v_summary.period_views;
    end if;
    if v_summary.current_favorites <> 2 then
        raise exception 'summary favorites must be current active only, got %',
            v_summary.current_favorites;
    end if;
    -- buyer-2 first message today on sold listing = 1 period inquiry.
    -- empty + seller-only = 0; old buyer message outside 7d = 0.
    if v_summary.period_inquiries <> 1 then
        raise exception 'period inquiries expected 1, got %', v_summary.period_inquiries;
    end if;
    if v_summary.conversion_percent is distinct from ((1::numeric * 100) / 9) then
        raise exception 'conversion expected 100/9, got %', v_summary.conversion_percent;
    end if;

    delete from public.favorites
     where user_id = v_buyer_2 and listing_id = v_listing_active;
    select current_favorites into v_b_views
      from public.get_my_seller_analytics_summary(7);
    if v_b_views <> 1 then
        raise exception 'unfavorite must drop current favorites to 1, got %', v_b_views;
    end if;

    select count(*) into v_daily_count
      from public.get_my_seller_analytics_daily(7);
    if v_daily_count <> 7 then
        raise exception '7-day series must have 7 rows, got %', v_daily_count;
    end if;
    select count(*) into v_zero_days
      from public.get_my_seller_analytics_daily(7)
     where views = 0;
    if v_zero_days < 1 then
        raise exception 'daily series must include zero-view dates';
    end if;

    select count(*) into v_listings_count
      from public.get_my_seller_analytics_listings(7);
    if v_listings_count <> 2 then
        raise exception 'listings RPC must return only active+sold, got %', v_listings_count;
    end if;
    if exists (
        select 1 from public.get_my_seller_analytics_listings(7)
         where listing_id in (v_listing_hidden, v_listing_archived, v_listing_b)
    ) then
        raise exception 'hidden/archived/other-seller listing leaked';
    end if;
    if exists (
        select 1 from public.get_my_seller_analytics_listings(7)
         where listing_id = v_listing_active and period_views <> 7
    ) then
        raise exception 'active listing period views expected 7';
    end if;
    if exists (
        select 1 from public.get_my_seller_analytics_listings(7)
         where listing_id = v_listing_sold and period_inquiries <> 1
    ) then
        raise exception 'sold listing should have 1 period inquiry';
    end if;
    if exists (
        select 1 from public.get_my_seller_analytics_listings(7)
         where listing_id = v_listing_sold and current_favorites <> 1
    ) then
        raise exception 'sold listing current favorites expected 1';
    end if;

    -- 30-day includes the 20-day-old inquiry
    select period_inquiries into v_b_views
      from public.get_my_seller_analytics_summary(30);
    if v_b_views <> 2 then
        raise exception '30-day inquiries expected 2 (today + old), got %', v_b_views;
    end if;

    perform set_config('request.jwt.claim.sub', v_seller_b::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_seller_b, 'role', 'authenticated')::text,
        true
    );
    select * into v_summary from public.get_my_seller_analytics_summary(7);
    if v_summary.period_views <> 60 then
        raise exception 'seller B views leaked or wrong: %', v_summary.period_views;
    end if;
    if exists (
        select 1 from public.get_my_seller_analytics_listings(7)
         where listing_id <> v_listing_b
    ) then
        raise exception 'seller B saw seller A listings';
    end if;

    perform set_config('request.jwt.claim.sub', v_empty::text, true);
    perform set_config(
        'request.jwt.claims',
        json_build_object('sub', v_empty, 'role', 'authenticated')::text,
        true
    );
    select * into v_summary from public.get_my_seller_analytics_summary(7);
    if v_summary.seller_type is distinct from 'private'
       or v_summary.verified_dealer is not false then
        raise exception 'missing seller profile must default to private/unverified: % %',
            v_summary.seller_type, v_summary.verified_dealer;
    end if;
    if v_summary.active_count <> 0
       or v_summary.sold_count <> 0
       or v_summary.period_views <> 0
       or v_summary.current_favorites <> 0
       or v_summary.period_inquiries <> 0
       or v_summary.conversion_percent is not null then
        raise exception 'empty seller summary must be zeros + null conversion';
    end if;
    if exists (select 1 from public.seller_profiles where user_id = v_empty) then
        raise exception 'analytics summary must not insert seller_profiles';
    end if;
    select count(*) into v_daily_count from public.get_my_seller_analytics_daily(7);
    if v_daily_count <> 7 then
        raise exception 'empty seller daily must still be 7 zero rows';
    end if;
    if exists (select 1 from public.get_my_seller_analytics_listings(7)) then
        raise exception 'empty seller listings must be empty';
    end if;

    begin
        perform public.get_my_seller_analytics_summary(14);
        raise exception 'unsupported period must be rejected';
    exception
        when others then
            if sqlstate <> '22023' then
                raise;
            end if;
    end;

    -- cleanup
    delete from public.listings
     where id in (
        v_listing_active, v_listing_sold, v_listing_hidden,
        v_listing_archived, v_listing_b
     );
    delete from public.seller_profiles
     where user_id in (v_seller_a, v_seller_b, v_empty);
    delete from auth.users
     where id in (v_seller_a, v_seller_b, v_buyer_1, v_buyer_2, v_empty);
end;
$$;
