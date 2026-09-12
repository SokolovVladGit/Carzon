import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _path =
    'supabase/migrations/20260912180000_manual_smart_fill_open_data.sql';

void main() {
  late String sql;
  late String lower;

  setUpAll(() {
    final file = File(_path);
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
    lower = sql.toLowerCase();
  });

  test('creates catalog tables without listings mutation', () {
    expect(lower, contains('create table if not exists public.vehicle_open_data_import_batch'));
    expect(lower, contains('create table if not exists public.vehicle_identity_alias'));
    expect(lower, contains('create table if not exists public.vehicle_nameplate_identity'));
    expect(lower, contains('create table if not exists public.vehicle_open_data_configuration'));
    expect(sql, isNot(contains('alter table public.listings')));
  });

  test('revokes client table access and enables rls', () {
    for (final table in [
      'vehicle_open_data_import_batch',
      'vehicle_identity_alias',
      'vehicle_nameplate_identity',
      'vehicle_open_data_configuration',
    ]) {
      expect(
        lower,
        contains('alter table public.$table enable row level security'),
      );
      expect(
        lower,
        contains('revoke all on table public.$table from authenticated'),
      );
    }
  });

  test('does not persist plate or vin columns', () {
    expect(lower, contains('must not retain plate/vin/owner keys'));
    expect(lower, contains("v_row ? 'kenteken'"));
    expect(lower, isNot(contains('kenteken text')));
    expect(lower, isNot(contains('license_plate text')));
    expect(lower, isNot(contains('vin text')));
    expect(lower, isNot(contains('chassisnummer text')));
  });

  test('m1 leaves transmission and drivetrain null on eu path', () {
    expect(lower, contains('vehicle_open_data_configuration_m1_trans_null_chk'));
    expect(lower, contains('vehicle_open_data_configuration_m1_drive_null_chk'));
    expect(lower, contains('check (transmission_type is null)'));
    expect(lower, contains('check (drivetrain is null)'));
  });

  test('year evidence is registration not oem model year', () {
    expect(lower, contains("year_basis text not null default 'registration'"));
    expect(lower, contains("'registration_window'"));
    expect(lower, contains('year_min - 1 <= p_year'));
  });

  test('tvv configuration key and tan base helpers exist', () {
    expect(lower, contains('carzon_open_data_configuration_key'));
    expect(lower, contains('carzon_open_data_normalize_tan_base'));
    expect(lower, contains(r"'\*[0-9]{1,3}$'"));
  });

  test('fuel mapping is conservative', () {
    expect(lower, contains("when v_ft = 'petrol' and v_fm = 'm' then 'petrol'"));
    expect(lower, contains("when v_ft in ('petrol/electric', 'diesel/electric') and v_fm = 'p'"));
    expect(lower, contains('else null'));
  });

  test('resolver is authenticated read-only rpc', () {
    expect(
      lower,
      contains(
        'create or replace function public.resolve_vehicle_by_identity(',
      ),
    );
    expect(lower, contains('p_answer jsonb default null'));
    expect(sql, contains("'consensusSpecs'"));
    expect(sql, contains("'clarification'"));
    expect(sql, contains("'transmissionType', null"));
    expect(sql, contains("'drivetrain', null"));
    expect(
      lower,
      contains(
        'grant execute on function public.resolve_vehicle_by_identity(text, text, integer, jsonb)\n    to authenticated',
      ),
    );
    expect(
      lower,
      contains(
        'revoke all on function public.resolve_vehicle_by_identity(text, text, integer, jsonb)\n    from anon',
      ),
    );
  });

  test('importer upserts are service_role only', () {
    expect(lower, contains('carzon_open_data_upsert_configurations'));
    expect(lower, contains('carzon_open_data_merge_rdw_body'));
    expect(
      lower,
      contains(
        'grant execute on function public.carzon_open_data_upsert_configurations(uuid, jsonb)\n    to service_role',
      ),
    );
    expect(
      lower,
      contains(
        'revoke all on function public.carzon_open_data_upsert_configurations(uuid, jsonb) from anon, authenticated',
      ),
    );
  });

  test('does not touch vin resolver', () {
    expect(sql, isNot(contains('listing_vehicle_identity')));
    expect(sql, isNot(contains('DecodeVinValues')));
    expect(sql, isNot(contains('carzon_enqueue_vin_decode')));
    expect(sql, isNot(contains('vin_decode_cache')));
  });
}
