-- Carzon — sample listings for local/dev verification.
-- Safe to re-run: uses fixed UUIDs so re-execution will conflict with
-- existing rows. Truncate first if you want a clean slate:
--   truncate table public.listings restart identity;

insert into public.listings
    (id, title, make, model, year, price_eur, mileage_km, type, city, cover_image_url, status)
values
    ('11111111-1111-1111-1111-111111111111',
     'Volkswagen Golf 7 — 1.6 TDI',
     'Volkswagen', 'Golf', 2016, 8900.00, 168000,
     'sale', 'Chișinău', null, 'active'),

    ('22222222-2222-2222-2222-222222222222',
     'Skoda Octavia 1.8 TSI — schimb posibil',
     'Skoda', 'Octavia', 2018, 11500.00, 142000,
     'both', 'Bălți', null, 'active'),

    ('33333333-3333-3333-3333-333333333333',
     'BMW 320d xDrive — full option',
     'BMW', '320', 2019, 18750.00, 95000,
     'sale', 'Chișinău', null, 'active');
