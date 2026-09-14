import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _sqlPath = 'test/supabase/seller_analytics_foundation_behavior.sql';

Future<ProcessResult?> _dockerPsql(String command) async {
  try {
    return await Process.run('docker', [
      'exec',
      '-i',
      'supabase_db_carzon',
      'psql',
      '-U',
      'postgres',
      '-d',
      'postgres',
      '-v',
      'ON_ERROR_STOP=1',
      '-c',
      command,
    ]);
  } catch (_) {
    return null;
  }
}

Future<bool> _localPostgresAvailable() async {
  final result = await _dockerPsql(
    'select to_regprocedure('
    '''public.get_my_seller_analytics_summary(integer)'''
    ');',
  );
  return result != null && result.exitCode == 0;
}

void main() {
  test('Seller Analytics Phase 1 behavior against local fixtures', () async {
    final available = await _localPostgresAvailable();
    if (!available) {
      // ignore: avoid_print
      print(
        'SKIP live seller analytics SQL fixtures: local Supabase Postgres '
        'is not reachable via docker exec supabase_db_carzon, or the Phase 1 '
        'migration is not applied. Static migration tests still run.',
      );
      return;
    }

    final result = await Process.run('bash', [
      '-lc',
      'docker exec -i supabase_db_carzon psql -U postgres -d postgres '
          '-v ON_ERROR_STOP=1 < ${_sqlPath}',
    ]);
    expect(
      result.exitCode,
      0,
      reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
    );
  });
}
