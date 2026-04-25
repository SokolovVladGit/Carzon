-- =============================================================
-- Carzon — temporary PHOTO DEMO listings (UI development only)
-- =============================================================
--
-- Purpose: populate the marketplace with 20 synthetic listings that
-- carry real-looking car photos so the product team can polish the
-- Flutter UI (listing cards, feed, details, placeholders) against
-- realistic data.
--
-- !!! IMPORTANT — READ BEFORE RUNNING !!!
--
--   * This file is TEMPORARY demo data. It is NOT part of the
--     production seed flow and is NOT applied automatically.
--   * The `cover_image_url` values point to external `kareta.md`
--     assets. Carzon does NOT own or license these images. They are
--     used only for internal UI mockups and may disappear at any
--     time if the remote host rotates or removes the files.
--   * DO NOT import this file into production.
--   * DO NOT copy these photo URLs into Flutter code, migrations, or
--     `supabase/seed.sql`.
--   * When you are done using the photo demo data, remove it with
--     `supabase/demo/remove_photo_demo_listings.sql`.
--
-- Dataset shape (asserted by
-- `test/supabase/photo_demo_listings_test.dart`):
--   * 20 rows total
--   * 10 `market_region = 'transnistria'`
--   * 10 `market_region = 'moldova'`
--   * every row `status = 'active'`
--   * every row `seller_id = null`
--   * stable UUIDs in the `d0000000-0000-4000-8000-0000000000XX`
--     namespace (distinct from the production-seed `c000...` space)
--   * fake phones `+373 000 100 XXX`
--   * fake Telegram handles `@carzon_photo_demo_XX`
--   * mixed `type` (sale / exchange / both) and
--     `whatsapp_enabled` true / false
--
-- Idempotency: every insert uses `on conflict (id) do update` so this
-- file can be re-applied without producing duplicates.
--
-- Security / RLS: this file does NOT add, drop, or alter any policy,
-- schema object, index, function, extension, grant, or revoke. It
-- only inserts data rows into `public.listings`. When applied via
-- `supabase db reset` or `psql` as a superuser, RLS is bypassed,
-- which is why `seller_id = null` inserts are accepted.
--
-- Duplicate cover URL note: photo #1 and photo #6 in the provided
-- list are the same file. Two demo rows therefore legitimately share
-- the same `cover_image_url`. This is acceptable for temporary UI
-- mockups; the test harness tolerates duplicates but still requires
-- 20 rows.
-- =============================================================

-- -------------------------------------------------------------
-- Transnistria — photo demo listings (10)
-- -------------------------------------------------------------

insert into public.listings
    (id, title, make, model, year, price_eur, mileage_km, type, city,
     market_region, cover_image_url, status, seller_id,
     contact_phone, telegram_username, whatsapp_enabled)
values
    ('d0000000-0000-4000-8000-000000000001',
     'Toyota Prius 2015 — гибрид',
     'Toyota', 'Prius', 2015, 7200.00, 184000,
     'sale', 'Tiraspol', 'transnistria',
     'https://content.kareta.md/items/original/3a5edb00-cb9a-46ec-bdfc-a97cf4410ba9.webp',
     'active', null,
     '+373 000 100 001', '@carzon_photo_demo_01', true),

    ('d0000000-0000-4000-8000-000000000002',
     'Volkswagen Passat 2016 — универсал',
     'Volkswagen', 'Passat', 2016, 9800.00, 172000,
     'sale', 'Bender', 'transnistria',
     'https://content.kareta.md/items/original/2b40e21f-fb17-469b-ad28-13fec31cf303.webp',
     'active', null,
     '+373 000 100 002', '@carzon_photo_demo_02', false),

    ('d0000000-0000-4000-8000-000000000003',
     'Skoda Octavia 2018 — автомат',
     'Skoda', 'Octavia', 2018, 12400.00, 138000,
     'sale', 'Tiraspol', 'transnistria',
     'https://content.kareta.md/items/original/52c791f2-6c81-4881-b2cc-38f3ad13cf23.webp',
     'active', null,
     '+373 000 100 003', '@carzon_photo_demo_03', true),

    ('d0000000-0000-4000-8000-000000000004',
     'Opel Astra 2017 — обмен возможен',
     'Opel', 'Astra', 2017, 8900.00, 151000,
     'both', 'Ribnita', 'transnistria',
     'https://content.kareta.md/items/original/14a624ad-6a89-4a90-8a36-c8ea1821fc2c.webp',
     'active', null,
     '+373 000 100 004', '@carzon_photo_demo_04', false),

    ('d0000000-0000-4000-8000-000000000005',
     'Renault Megane 2016 — обмен на кроссовер',
     'Renault', 'Megane', 2016, 7600.00, 166000,
     'exchange', 'Dubasari', 'transnistria',
     'https://content.kareta.md/items/original/9bf392ed-1b7b-469a-a77d-70fb2078fb7e.webp',
     'active', null,
     '+373 000 100 005', '@carzon_photo_demo_05', true),

    ('d0000000-0000-4000-8000-000000000006',
     'Nissan Qashqai 2019 — полный комплект',
     'Nissan', 'Qashqai', 2019, 16900.00, 94000,
     'sale', 'Tiraspol', 'transnistria',
     'https://content.kareta.md/items/original/3a5edb00-cb9a-46ec-bdfc-a97cf4410ba9.webp',
     'active', null,
     '+373 000 100 006', '@carzon_photo_demo_06', false),

    ('d0000000-0000-4000-8000-000000000007',
     'Hyundai Tucson 2018 — дизель',
     'Hyundai', 'Tucson', 2018, 17500.00, 119000,
     'sale', 'Bender', 'transnistria',
     'https://content.kareta.md/items/original/501094c7-ccdb-488d-8cd8-577817876c91.webp',
     'active', null,
     '+373 000 100 007', '@carzon_photo_demo_07', true),

    ('d0000000-0000-4000-8000-000000000008',
     'Kia Sportage 2017 — обмен рассмотрим',
     'Kia', 'Sportage', 2017, 15700.00, 127000,
     'both', 'Slobozia', 'transnistria',
     'https://content.kareta.md/items/original/f9d9f2ee-a023-4d3d-9010-1fcbfda10d2a.webp',
     'active', null,
     '+373 000 100 008', '@carzon_photo_demo_08', true),

    ('d0000000-0000-4000-8000-000000000009',
     'Toyota Corolla 2019 — один владелец',
     'Toyota', 'Corolla', 2019, 13900.00, 88000,
     'sale', 'Grigoriopol', 'transnistria',
     'https://content.kareta.md/items/original/55276754-6b9c-46f7-8264-69cc3c29f69e.webp',
     'active', null,
     '+373 000 100 009', '@carzon_photo_demo_09', false),

    ('d0000000-0000-4000-8000-000000000010',
     'Volkswagen Golf 2016 — экономичный',
     'Volkswagen', 'Golf', 2016, 8700.00, 159000,
     'sale', 'Tiraspol', 'transnistria',
     'https://content.kareta.md/items/original/fcf07c0a-654b-4a63-9723-ea965db1a133.webp',
     'active', null,
     '+373 000 100 010', '@carzon_photo_demo_10', true)

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
-- Moldova — photo demo listings (10)
-- -------------------------------------------------------------

insert into public.listings
    (id, title, make, model, year, price_eur, mileage_km, type, city,
     market_region, cover_image_url, status, seller_id,
     contact_phone, telegram_username, whatsapp_enabled)
values
    ('d0000000-0000-4000-8000-000000000011',
     'Dacia Duster 2018 — полный привод',
     'Dacia', 'Duster', 2018, 11200.00, 122000,
     'sale', 'Chișinău', 'moldova',
     'https://content.kareta.md/items/original/fe1e2e5b-c916-4d97-8990-103b6a8ec95e.webp',
     'active', null,
     '+373 000 100 011', '@carzon_photo_demo_11', true),

    ('d0000000-0000-4000-8000-000000000012',
     'Toyota RAV4 2020 — гибрид, как новый',
     'Toyota', 'RAV4', 2020, 24500.00, 76000,
     'sale', 'Chișinău', 'moldova',
     'https://content.kareta.md/items/original/f6d95256-c1ee-4ed8-a6bc-ee7388a2e8aa.webp',
     'active', null,
     '+373 000 100 012', '@carzon_photo_demo_12', false),

    ('d0000000-0000-4000-8000-000000000013',
     'BMW 320 2017 — обмен рассмотрим',
     'BMW', '320', 2017, 18900.00, 132000,
     'both', 'Bălți', 'moldova',
     'https://content.kareta.md/items/original/f84d69cb-9ab9-462d-85a9-7d3a282c750b.webp',
     'active', null,
     '+373 000 100 013', '@carzon_photo_demo_13', true),

    ('d0000000-0000-4000-8000-000000000014',
     'Mercedes-Benz E-Class 2016 — полная комплектация',
     'Mercedes-Benz', 'E-Class', 2016, 21500.00, 148000,
     'sale', 'Chișinău', 'moldova',
     'https://content.kareta.md/items/original/4915f0a0-b247-47d6-b96a-edaefb547724.webp',
     'active', null,
     '+373 000 100 014', '@carzon_photo_demo_14', false),

    ('d0000000-0000-4000-8000-000000000015',
     'Audi A4 2018 — дизель, автомат',
     'Audi', 'A4', 2018, 19800.00, 116000,
     'sale', 'Orhei', 'moldova',
     'https://content.kareta.md/items/original/4a32a904-8354-45a7-bd2a-c423131d2fb8.webp',
     'active', null,
     '+373 000 100 015', '@carzon_photo_demo_15', true),

    ('d0000000-0000-4000-8000-000000000016',
     'Volkswagen Tiguan 2019 — кроссовер',
     'Volkswagen', 'Tiguan', 2019, 22700.00, 103000,
     'sale', 'Chișinău', 'moldova',
     'https://content.kareta.md/items/original/fb0872e1-90bb-4f2f-86c8-27e51a2f289c.webp',
     'active', null,
     '+373 000 100 016', '@carzon_photo_demo_16', true),

    ('d0000000-0000-4000-8000-000000000017',
     'Renault Duster 2017 — обмен на седан',
     'Renault', 'Duster', 2017, 10600.00, 137000,
     'exchange', 'Bălți', 'moldova',
     'https://content.kareta.md/items/original/1ec1e37c-c25b-421c-a05d-9a34d2ff50fa.webp',
     'active', null,
     '+373 000 100 017', '@carzon_photo_demo_17', false),

    ('d0000000-0000-4000-8000-000000000018',
     'Hyundai Elantra 2020 — малый пробег',
     'Hyundai', 'Elantra', 2020, 15900.00, 69000,
     'sale', 'Chișinău', 'moldova',
     'https://content.kareta.md/items/original/8b756038-e4bb-401b-934e-3c631bc4408a.webp',
     'active', null,
     '+373 000 100 018', '@carzon_photo_demo_18', true),

    ('d0000000-0000-4000-8000-000000000019',
     'Kia Ceed 2018 — возможен обмен',
     'Kia', 'Ceed', 2018, 12800.00, 111000,
     'both', 'Orhei', 'moldova',
     'https://content.kareta.md/items/original/02e792bf-a212-418a-85fe-891f0d9f15b9.webp',
     'active', null,
     '+373 000 100 019', '@carzon_photo_demo_19', false),

    ('d0000000-0000-4000-8000-000000000020',
     'Dacia Logan 2019 — экономичный',
     'Dacia', 'Logan', 2019, 8400.00, 96000,
     'sale', 'Chișinău', 'moldova',
     'https://content.kareta.md/items/original/03d865d7-756c-4f8b-b5c0-6c2a0e62aee3.webp',
     'active', null,
     '+373 000 100 020', '@carzon_photo_demo_20', true)

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
