import 'dart:io';

import 'package:carzon/features/listings/domain/catalog/listing_brands.dart';
import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/20260827120000_vehicle_model_catalog.sql';

final _seedPair = RegExp(r"\('((?:[^']|'')*)',\s*'((?:[^']|'')*)'\)");

final _suspiciousModel = RegExp(
  r'\b(hybrid|e:?hev|xdrive|m sport|executive|advance|automatic|manual|cvt|tdi|tfsi|dci|motorcycle|atv|\bbus\b|truck|chassis|package|trim)\b',
  caseSensitive: false,
);

const _requiredExamples = <String, List<String>>{
  'Honda': ['Accord', 'Civic', 'CR-V', 'HR-V'],
  'Toyota': ['Corolla', 'Camry', 'RAV4', 'Highlander'],
  'Audi': ['A4', 'A5', 'A6', 'Q5', 'e-tron GT'],
  'BMW': ['3 Series', '5 Series', 'X3', 'X5', 'M3', 'M4'],
  'Mercedes-Benz': [
    'A-Class',
    'C-Class',
    'E-Class',
    'S-Class',
    'GLC',
    'GLE',
    'G-Class',
  ],
  'Volkswagen': [
    'Golf',
    'Passat',
    'Polo',
    'Tiguan',
    'Touareg',
    'T-Roc',
    'T-Cross',
    'Touran',
    'Caddy',
  ],
  'Skoda': ['Fabia', 'Octavia', 'Superb', 'Karoq', 'Kodiaq', 'Kamiq'],
  'Dacia': ['Logan', 'Sandero', 'Duster'],
  'Renault': ['Clio', 'Megane', 'Scenic', 'Captur', 'Kadjar', 'Austral'],
  'Peugeot': ['208', '308', '508', '2008', '3008', '5008'],
  'Citroen': ['C3', 'C4', 'C5', 'Berlingo'],
  'Opel': ['Astra', 'Corsa', 'Insignia', 'Mokka', 'Zafira'],
  'Kia': ['Ceed', 'Rio', 'Sportage', 'Sorento'],
  'Nissan': ['Micra', 'Qashqai', 'Juke', 'X-Trail'],
};

List<(String, String)> _parseSeed(String sql) {
  final insertAt = sql.indexOf('insert into public.vehicle_model_catalog');
  expect(insertAt, greaterThanOrEqualTo(0));
  return [
    for (final match in _seedPair.allMatches(sql.substring(insertAt)))
      (match.group(1)!, match.group(2)!),
  ];
}

void main() {
  late String sql;
  late String lower;
  late List<(String, String)> seed;

  setUpAll(() {
    final file = File(_migrationPath);
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
    lower = sql.toLowerCase();
    seed = _parseSeed(sql);
  });

  test(
    'creates vehicle_model_catalog with required columns and uniqueness',
    () {
      expect(
        lower,
        contains('create table if not exists public.vehicle_model_catalog'),
      );
      expect(lower, contains('make text not null'));
      expect(lower, contains('model text not null'));
      expect(lower, contains('is_active boolean not null default true'));
      expect(lower, contains('created_at timestamptz not null default now()'));
      expect(lower, contains('vehicle_model_catalog_make_chk'));
      expect(lower, contains('vehicle_model_catalog_model_chk'));
      expect(lower, contains('vehicle_model_catalog_make_model_uniq'));
      expect(lower, contains('lower(btrim(make)), lower(btrim(model))'));
      expect(lower, contains('vehicle_model_catalog_active_make_idx'));
    },
  );

  test('does not alter listings persistence or add model_id / FK', () {
    expect(lower, isNot(contains('alter table public.listings')));
    expect(lower, isNot(contains('model_id')));
    expect(lower, isNot(contains('references public.listings')));
    expect(lower, isNot(contains('add column')));
  });

  test('table is RPC-only: RLS on, no direct client grants', () {
    expect(
      lower,
      contains(
        'alter table public.vehicle_model_catalog enable row level security',
      ),
    );
    expect(
      lower,
      contains('revoke all on table public.vehicle_model_catalog from public'),
    );
    expect(
      lower,
      contains('revoke all on table public.vehicle_model_catalog from anon'),
    );
    expect(
      lower,
      contains(
        'revoke all on table public.vehicle_model_catalog from authenticated',
      ),
    );
  });

  test('list_vehicle_models_for_make is a public read RPC', () {
    expect(
      lower,
      contains(
        'create or replace function public.list_vehicle_models_for_make(p_make text)',
      ),
    );
    expect(lower, contains('returns table (model text)'));
    expect(lower, contains('security definer'));
    expect(lower, contains('set search_path = public, pg_temp'));
    expect(lower, contains('c.is_active'));
    expect(lower, contains('lower(btrim(c.make)) = lower(btrim(p_make))'));
    expect(lower, contains('btrim(coalesce(p_make, \'\')) <> \'\''));
    expect(lower, contains('order by c.model'));
    expect(
      lower,
      contains(
        'revoke all on function public.list_vehicle_models_for_make(text) from public',
      ),
    );
    expect(
      lower,
      contains(
        'grant execute on function public.list_vehicle_models_for_make(text)',
      ),
    );
    expect(lower, contains('to anon, authenticated'));
    expect(lower, isNot(contains('auth.uid()')));
    expect(lower, isNot(contains('insert into public.listings')));
    expect(lower, isNot(contains('update public.listings')));
  });

  test('seed has no blanks, duplicates, Other, or trim garbage', () {
    expect(seed, isNotEmpty);
    expect(seed.every((row) => row.$1.trim().isNotEmpty), isTrue);
    expect(seed.every((row) => row.$2.trim().isNotEmpty), isTrue);

    final normalized = <String>{};
    for (final row in seed) {
      final key =
          '${row.$1.trim().toLowerCase()}|${row.$2.trim().toLowerCase()}';
      expect(normalized.add(key), isTrue, reason: 'duplicate $key');
    }

    expect(seed.any((row) => row.$1 == 'Other'), isFalse);
    final dirty = [
      for (final row in seed)
        if (_suspiciousModel.hasMatch(row.$2) ||
            RegExp(r'\b\d\.\d\b').hasMatch(row.$2))
          '${row.$1} ${row.$2}',
    ];
    expect(dirty, isEmpty);
  });

  test('seed covers every real Carzon make; none are intentionally empty', () {
    final represented = {for (final row in seed) row.$1};
    final expected = [
      for (final make in kListingBrandCatalog)
        if (make != kListingBrandCatalogOther) make,
    ];
    expect(expected, hasLength(92));
    expect(represented, expected.toSet());
  });

  test('required canonical model-line examples exist', () {
    final have = {for (final row in seed) '${row.$1}|${row.$2}'};
    for (final entry in _requiredExamples.entries) {
      for (final model in entry.value) {
        expect(
          have.contains('${entry.key}|$model'),
          isTrue,
          reason: '${entry.key} $model',
        );
      }
    }
  });
}
