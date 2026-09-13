import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _path =
    'supabase/migrations/20260913170000_manual_smart_fill_progressive_refinement.sql';
const _v1Path =
    'supabase/migrations/20260912193000_manual_smart_fill_transmission_tgk.sql';

void main() {
  late String sql;
  late String lower;
  late String v1;

  setUpAll(() {
    final file = File(_path);
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
    lower = sql.toLowerCase();
    v1 = File(_v1Path).readAsStringSync();
  });

  test('creates only v2 resolver and does not replace v1', () {
    expect(
      sql,
      contains(
        'create or replace function public.resolve_vehicle_by_identity_v2(',
      ),
    );
    expect(sql, contains("p_refinement jsonb default '{}'::jsonb"));
    expect(
      sql,
      isNot(
        contains(
          'create or replace function public.resolve_vehicle_by_identity(',
        ),
      ),
    );
    expect(
      v1,
      contains(
        'create or replace function public.resolve_vehicle_by_identity(',
      ),
    );
  });

  test('does not alter catalog, listings, or ingest data', () {
    expect(lower, isNot(contains('alter table public.listings')));
    expect(
      lower,
      isNot(contains('alter table public.vehicle_open_data_configuration')),
    );
    expect(
      lower,
      isNot(contains('alter table public.vehicle_nameplate_identity')),
    );
    expect(
      lower,
      isNot(contains('insert into public.vehicle_open_data_configuration')),
    );
    expect(lower, isNot(contains('create table')));
    expect(sql, isNot(contains('edge function')));
  });

  test('mapping version is m1.2 for v2 only', () {
    expect(sql, contains("select 'm1.2'::text"));
    expect(sql, contains('carzon_open_data_mapping_version_v2'));
    expect(sql, isNot(contains("select 'm1.1'::text")));
  });

  test('security matches authenticated-only resolver posture', () {
    expect(lower, contains('security definer'));
    expect(lower, contains('set search_path = public, pg_temp'));
    expect(
      lower,
      contains(
        'grant execute on function public.resolve_vehicle_by_identity_v2(text, text, integer, jsonb)\n    to authenticated',
      ),
    );
    expect(
      lower,
      contains(
        'revoke all on function public.resolve_vehicle_by_identity_v2(text, text, integer, jsonb)\n    from anon',
      ),
    );
  });

  test('opaque option ids and no raw provider identifiers', () {
    expect(lower, contains('md5('));
    expect(sql, contains('carzon_open_data_v2_option_id'));
    expect(sql, isNot(contains('tan_base')));
    expect(sql, isNot(contains('configuration_key')));
    expect(sql, isNot(contains("'tvv'")));
  });

  test('body evidence prefers row-level rdw over singleton nameplate', () {
    expect(sql, contains('e->>\'body\''));
    expect(sql, contains('v_nameplate'));
    expect(lower, contains('not exists'));
    expect(sql, contains('array_length(v_nameplate, 1), 0) = 1'));
  });

  test('engine option uses seller liters and excludes ev power-only', () {
    expect(sql, contains('carzon_open_data_seller_liters'));
    expect(sql, contains('round(p_cm3::numeric / 1000.0, 1)'));
    expect(lower, contains("e->>'fuel' = 'electric'"));
    expect(lower, contains('v_all_electric'));
    expect(lower, contains('v_engine_n between 2 and 8'));
    expect(lower, contains('v_engine_n > 8'));
  });

  test('refinement budget and skip-only-current-kind', () {
    expect(sql, contains("'maxDecisions', 3"));
    expect(lower, contains('v_decisions > 3'));
    expect(lower, contains('v_skipped_kinds'));
    expect(sql, contains("'invalidRefinement'"));
    expect(sql, contains("'drivetrain', null"));
  });

  test('does not expose helper rpcs to clients', () {
    expect(
      lower,
      contains(
        'revoke all on function public.carzon_open_data_v2_options(jsonb, text, text, text, integer)\n    from anon, authenticated',
      ),
    );
  });
}
