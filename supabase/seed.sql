-- =============================================================
-- Carzon — local/demo seed data
-- =============================================================
--
-- Purpose: give developers and demo users a populated marketplace
-- immediately after `supabase db reset` on a local stack. All rows
-- inserted here are SYNTHETIC: no real people, no real phone numbers,
-- no real seller identities. Every phone matches the synthetic
-- pattern `+373 000 000 XXX` so it is obviously not a personal number.
--
-- Idempotency: every insert uses a stable UUID and
-- `on conflict (id) do update` so re-running this file is safe and
-- converges on the latest values.
--
-- Security / RLS:
--   * This file does NOT add, drop, or alter any policy.
--   * This file does NOT create or alter any schema.
--   * Seed rows are inserted with `seller_id = null`. The public-feed
--     RLS policy filters by `status = 'active'` only, so these rows
--     show up in the browse feed. They are intentionally un-owned and
--     therefore un-editable through the mobile app. Owner flows must
--     still be exercised with real authenticated users creating
--     listings through the UI.
--   * When applied by the Supabase CLI (`supabase db reset`), this
--     script runs as a superuser, bypassing RLS — the
--     `listings_insert_own` policy (which forbids null seller_id) does
--     not apply to seed loading.
--
-- Coverage (minimum guaranteed, asserted by
-- `test/features/supabase/seed_inspection_test.dart`):
--   * ≥ 12 active Transnistria listings
--   * ≥ 4 active Moldova listings
--   * ≥ 2 non-active listings across `hidden`, `sold`, `archived`
--   * mix of `type` values: sale / exchange / both
--   * mix of `whatsapp_enabled` true / false
--   * mix of telegram_username present / null
-- =============================================================

-- -------------------------------------------------------------
-- Transnistria — active listings (14)
-- -------------------------------------------------------------

insert into public.listings
    (id, title, make, model, year, price_eur, mileage_km, type, city,
     market_region, cover_image_url, status, seller_id,
     contact_phone, telegram_username, whatsapp_enabled)
values
    ('c0000000-0000-4000-8000-000000000001',
     'Toyota Corolla 1.6 — îngrijit, un singur proprietar',
     'Toyota', 'Corolla', 2015, 8200.00, 145000,
     'sale', 'Tiraspol', 'transnistria', null, 'active', null,
     '+373 000 000 001', 'carzon_demo_01', true),

    ('c0000000-0000-4000-8000-000000000002',
     'Volkswagen Golf 7 TDI — economic',
     'Volkswagen', 'Golf', 2014, 7500.00, 178000,
     'sale', 'Bender', 'transnistria', null, 'active', null,
     '+373 000 000 002', null, false),

    ('c0000000-0000-4000-8000-000000000003',
     'Skoda Octavia 1.8 TSI — schimb posibil',
     'Skoda', 'Octavia', 2017, 10800.00, 132000,
     'both', 'Tiraspol', 'transnistria', null, 'active', null,
     '+373 000 000 003', 'carzon_demo_03', true),

    ('c0000000-0000-4000-8000-000000000004',
     'Opel Astra J 1.7 CDTI — preț negociabil',
     'Opel', 'Astra', 2013, 5900.00, 192000,
     'sale', 'Ribnita', 'transnistria', null, 'active', null,
     '+373 000 000 004', null, false),

    ('c0000000-0000-4000-8000-000000000005',
     'Renault Megane 1.5 dCi',
     'Renault', 'Megane', 2016, 7200.00, 156000,
     'sale', 'Dubasari', 'transnistria', null, 'active', null,
     '+373 000 000 005', 'carzon_demo_05', true),

    ('c0000000-0000-4000-8000-000000000006',
     'Dacia Duster 4x4 — ideal drumuri de țară',
     'Dacia', 'Duster', 2018, 9800.00, 112000,
     'sale', 'Grigoriopol', 'transnistria', null, 'active', null,
     '+373 000 000 006', null, true),

    ('c0000000-0000-4000-8000-000000000007',
     'Nissan Qashqai 1.6 — schimb pe break',
     'Nissan', 'Qashqai', 2015, 9900.00, 149000,
     'both', 'Slobozia', 'transnistria', null, 'active', null,
     '+373 000 000 007', 'carzon_demo_07', false),

    ('c0000000-0000-4000-8000-000000000008',
     'Hyundai Tucson 2.0 CRDi',
     'Hyundai', 'Tucson', 2017, 13500.00, 118000,
     'sale', 'Tiraspol', 'transnistria', null, 'active', null,
     '+373 000 000 008', null, true),

    ('c0000000-0000-4000-8000-000000000009',
     'Kia Sportage 1.7 CRDi',
     'Kia', 'Sportage', 2016, 12200.00, 127000,
     'sale', 'Bender', 'transnistria', null, 'active', null,
     '+373 000 000 009', 'carzon_demo_09', false),

    ('c0000000-0000-4000-8000-000000000010',
     'Toyota Prius hibrid — consum mic',
     'Toyota', 'Prius', 2012, 6700.00, 205000,
     'sale', 'Tiraspol', 'transnistria', null, 'active', null,
     '+373 000 000 010', null, true),

    ('c0000000-0000-4000-8000-000000000011',
     'Volkswagen Passat B8 2.0 TDI — exchange welcome',
     'Volkswagen', 'Passat', 2015, 9400.00, 168000,
     'exchange', 'Ribnita', 'transnistria', null, 'active', null,
     '+373 000 000 011', 'carzon_demo_11', false),

    ('c0000000-0000-4000-8000-000000000012',
     'Dacia Logan 1.0 SCe — puțin rulat',
     'Dacia', 'Logan', 2019, 6800.00, 89000,
     'sale', 'Dubasari', 'transnistria', null, 'active', null,
     '+373 000 000 012', null, true),

    ('c0000000-0000-4000-8000-000000000013',
     'BMW 320d xDrive — break',
     'BMW', '320', 2014, 11800.00, 172000,
     'sale', 'Tiraspol', 'transnistria', null, 'active', null,
     '+373 000 000 013', 'carzon_demo_13', true),

    ('c0000000-0000-4000-8000-000000000014',
     'Dacia Sandero Stepway — aproape nouă',
     'Dacia', 'Sandero', 2020, 7500.00, 58000,
     'sale', 'Bender', 'transnistria', null, 'active', null,
     '+373 000 000 014', null, false)

on conflict (id) do update set
    title             = excluded.title,
    make              = excluded.make,
    model             = excluded.model,
    year              = excluded.year,
    price_eur         = excluded.price_eur,
    mileage_km        = excluded.mileage_km,
    type              = excluded.type,
    city              = excluded.city,
    market_region     = excluded.market_region,
    cover_image_url   = excluded.cover_image_url,
    status            = excluded.status,
    seller_id         = excluded.seller_id,
    contact_phone     = excluded.contact_phone,
    telegram_username = excluded.telegram_username,
    whatsapp_enabled  = excluded.whatsapp_enabled;

-- -------------------------------------------------------------
-- Moldova — active listings (5)
-- -------------------------------------------------------------

insert into public.listings
    (id, title, make, model, year, price_eur, mileage_km, type, city,
     market_region, cover_image_url, status, seller_id,
     contact_phone, telegram_username, whatsapp_enabled)
values
    ('c0000000-0000-4000-8000-000000000101',
     'Mercedes-Benz E-Class 220d — full option',
     'Mercedes-Benz', 'E-Class', 2016, 17500.00, 138000,
     'sale', 'Chișinău', 'moldova', null, 'active', null,
     '+373 000 000 101', 'carzon_demo_21', true),

    ('c0000000-0000-4000-8000-000000000102',
     'Audi A4 2.0 TDI Avant — schimb posibil',
     'Audi', 'A4', 2015, 12800.00, 162000,
     'both', 'Bălți', 'moldova', null, 'active', null,
     '+373 000 000 102', null, false),

    ('c0000000-0000-4000-8000-000000000103',
     'Toyota RAV4 Hybrid',
     'Toyota', 'RAV4', 2018, 18900.00, 94000,
     'sale', 'Chișinău', 'moldova', null, 'active', null,
     '+373 000 000 103', 'carzon_demo_23', true),

    ('c0000000-0000-4000-8000-000000000104',
     'Renault Megane III — familie',
     'Renault', 'Megane', 2014, 5900.00, 184000,
     'sale', 'Orhei', 'moldova', null, 'active', null,
     '+373 000 000 104', null, false),

    ('c0000000-0000-4000-8000-000000000105',
     'Skoda Octavia Combi 2.0 TDI',
     'Skoda', 'Octavia', 2019, 13200.00, 98000,
     'sale', 'Chișinău', 'moldova', null, 'active', null,
     '+373 000 000 105', 'carzon_demo_25', true)

on conflict (id) do update set
    title             = excluded.title,
    make              = excluded.make,
    model             = excluded.model,
    year              = excluded.year,
    price_eur         = excluded.price_eur,
    mileage_km        = excluded.mileage_km,
    type              = excluded.type,
    city              = excluded.city,
    market_region     = excluded.market_region,
    cover_image_url   = excluded.cover_image_url,
    status            = excluded.status,
    seller_id         = excluded.seller_id,
    contact_phone     = excluded.contact_phone,
    telegram_username = excluded.telegram_username,
    whatsapp_enabled  = excluded.whatsapp_enabled;

-- -------------------------------------------------------------
-- Non-active listings (3) — hidden / sold / archived
--
-- These must NOT appear in the public feed (RLS `status = 'active'`).
-- They exist so developers can reason about owner/status visibility
-- when browsing the seed in psql or the Supabase dashboard.
-- -------------------------------------------------------------

insert into public.listings
    (id, title, make, model, year, price_eur, mileage_km, type, city,
     market_region, cover_image_url, status, seller_id,
     contact_phone, telegram_username, whatsapp_enabled)
values
    ('c0000000-0000-4000-8000-000000000201',
     'Opel Astra H 1.6 — ascuns temporar de vânzător',
     'Opel', 'Astra', 2011, 3800.00, 218000,
     'sale', 'Tiraspol', 'transnistria', null, 'hidden', null,
     '+373 000 000 201', null, false),

    ('c0000000-0000-4000-8000-000000000202',
     'Toyota Corolla — deja vândută',
     'Toyota', 'Corolla', 2013, 6200.00, 176000,
     'sale', 'Chișinău', 'moldova', null, 'sold', null,
     '+373 000 000 202', 'carzon_demo_42', false),

    ('c0000000-0000-4000-8000-000000000203',
     'Nissan Qashqai — arhivat',
     'Nissan', 'Qashqai', 2014, 8200.00, 189000,
     'sale', 'Bălți', 'moldova', null, 'archived', null,
     '+373 000 000 203', null, true)

on conflict (id) do update set
    title             = excluded.title,
    make              = excluded.make,
    model             = excluded.model,
    year              = excluded.year,
    price_eur         = excluded.price_eur,
    mileage_km        = excluded.mileage_km,
    type              = excluded.type,
    city              = excluded.city,
    market_region     = excluded.market_region,
    cover_image_url   = excluded.cover_image_url,
    status            = excluded.status,
    seller_id         = excluded.seller_id,
    contact_phone     = excluded.contact_phone,
    telegram_username = excluded.telegram_username,
    whatsapp_enabled  = excluded.whatsapp_enabled;
