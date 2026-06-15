import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Model Passport buyer RPC volatility hotfix.
void main() {
  group('20260706130000_model_data_buyer_rpc_volatile.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260706130000_model_data_buyer_rpc_volatile.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'volatile hotfix migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('alters only get_listing_model_data_for_buyer volatility', () {
      expect(
        lower,
        contains(
          'alter function public.get_listing_model_data_for_buyer(uuid) volatile',
        ),
      );
    });

    test('does not recreate function body or change grants', () {
      expect(lower, isNot(contains('create or replace function')));
      expect(lower, isNot(contains('grant execute')));
      expect(lower, isNot(contains('revoke')));
    });

    test('does not alter schema objects', () {
      expect(lower, isNot(contains('create table')));
      expect(lower, isNot(contains('alter table')));
      expect(lower, isNot(contains('create policy')));
      expect(lower, isNot(contains('enable row level security')));
    });

    test('notifies PostgREST to reload schema', () {
      expect(lower, contains("notify pgrst, 'reload schema'"));
    });

    test('does not touch VIN or Recall objects', () {
      expect(lower, isNot(contains('listing_vin')));
      expect(lower, isNot(contains('vin_processing')));
      expect(lower, isNot(contains('recall')));
    });
  });
}
