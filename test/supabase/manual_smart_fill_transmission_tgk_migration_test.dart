import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _path =
    'supabase/migrations/20260912193000_manual_smart_fill_transmission_tgk.sql';

void main() {
  late String sql;
  late String lower;

  setUpAll(() {
    final file = File(_path);
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
    lower = sql.toLowerCase();
  });

  test('does not edit listings or the applied m1 migration', () {
    expect(sql, isNot(contains('alter table public.listings')));
    expect(sql, isNot(contains('20260912180000')));
  });

  test('opens transmission taxonomy and keeps drivetrain null-only', () {
    expect(
      lower,
      contains('drop constraint if exists vehicle_open_data_configuration_m1_trans_null_chk'),
    );
    expect(lower, contains("transmission_type in ("));
    expect(lower, contains("'manual'"));
    expect(lower, contains("'automatic'"));
    expect(lower, contains("'cvt'"));
    expect(lower, contains("'robotic'"));
    expect(lower, contains("'dual_clutch'"));
    expect(lower, contains("'other'"));
    expect(sql, contains('vehicle_open_data_configuration_m1_drive_null_chk'));
    expect(lower, isNot(contains('drop constraint if exists vehicle_open_data_configuration_m1_drive_null_chk')));
  });

  test('maps official gearbox codes only', () {
    expect(lower, contains("when 'm' then 'manual'"));
    expect(lower, contains("when 'a' then 'automatic'"));
    expect(lower, contains("when 'c' then 'cvt'"));
    expect(lower, contains("when 'd' then 'dual_clutch'"));
    expect(lower, contains("when 'g' then 'robotic'"));
    expect(lower, contains("when 'o' then 'other'"));
    expect(lower, contains('else null'));
    expect(sql, isNot(contains("when 'F'")));
    expect(sql, isNot(contains("when 'H'")));
  });

  test('import batch source allows TGK versnelling', () {
    expect(lower, contains("'rdw_tgk_versnelling'"));
    expect(lower, contains('vehicle_open_data_import_batch_source_chk'));
  });

  test('tgk importer updates existing configs only', () {
    expect(lower, contains('carzon_open_data_upsert_tgk_transmissions'));
    expect(lower, contains('rdw_tgk_versnelling'));
    expect(lower, contains("'joined'"));
    expect(lower, contains("mapping_version = 'm1.1'"));
    expect(lower, contains('and c.drivetrain is null'));
    expect(lower, contains('update public.vehicle_open_data_configuration c'));
    expect(lower, isNot(contains('insert into public.vehicle_open_data_configuration')));
  });

  test('resolver consensus and clarification include transmission', () {
    expect(lower, contains("select 'm1.1'::text"));
    expect(sql, contains("'transmissionType', v_trans_cons"));
    expect(sql, contains("'drivetrain', null"));
    expect(lower, contains("v_attr not in ('body', 'fuel', 'transmission')"));
    expect(lower, contains("'attribute', 'transmission'"));
    expect(lower, contains("'manual', 'automatic', 'cvt', 'dual_clutch', 'robotic'"));
    expect(
      lower,
      contains(
        'grant execute on function public.carzon_open_data_upsert_tgk_transmissions(uuid, jsonb)\n    to service_role',
      ),
    );
  });

  test('does not open drivetrain or touch vin', () {
    expect(sql, isNot(contains('aangedrevenasindicator')));
    expect(sql, isNot(contains('xDrive')));
    expect(sql, isNot(contains('DecodeVinValues')));
    expect(lower, isNot(contains('alter table public.listings')));
  });
}
