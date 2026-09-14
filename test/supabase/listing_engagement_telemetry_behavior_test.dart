import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _sqlPath = 'test/supabase/listing_engagement_telemetry_behavior.sql';

Future<bool> _localPostgresAvailable() async {
  try {
    final result = await Process.run('bash', [
      '-lc',
      'docker exec -i supabase_db_carzon psql -U postgres -d postgres '
          "-v ON_ERROR_STOP=1 -c \"select to_regprocedure("
          "'public.record_listing_engagement_event(uuid, text, text)');\"",
    ]);
    return result.exitCode == 0 &&
        result.stdout.toString().contains('record_listing_engagement_event');
  } catch (_) {
    return false;
  }
}

void main() {
  test('listing engagement telemetry behavior against local fixtures', () async {
    final available = await _localPostgresAvailable();
    if (!available) {
      // ignore: avoid_print
      print(
        'SKIP live listing engagement SQL fixtures: local Supabase Postgres '
        'is not reachable via docker exec supabase_db_carzon, or the Phase 4A '
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
