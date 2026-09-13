import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _path =
    'supabase/migrations/20260913180000_manual_smart_fill_terminal_transmission.sql';
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

  test('replaces only v2 and keeps mapping m1.2', () {
    expect(
      sql,
      contains(
        'create or replace function public.resolve_vehicle_by_identity_v2(',
      ),
    );
    expect(sql, contains("select 'm1.2'::text"));
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

  test('allows one terminal transmission after the normal budget', () {
    expect(lower, contains('v_decisions > 4'));
    expect(lower, contains('elsif v_decisions = 3'));
    expect(sql, contains("'maxDecisions', 3"));
    expect(sql, contains('Never a 4th'));
    expect(sql, contains("'drivetrain', null"));
  });

  test('does not alter catalog or listings', () {
    expect(lower, isNot(contains('alter table public.listings')));
    expect(
      lower,
      isNot(contains('alter table public.vehicle_open_data_configuration')),
    );
    expect(lower, isNot(contains('create table')));
    expect(
      lower,
      isNot(contains('insert into public.vehicle_open_data_configuration')),
    );
  });
}
