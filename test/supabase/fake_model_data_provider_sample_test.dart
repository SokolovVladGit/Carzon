import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for fake_sample deterministic QA payloads in fake_provider.ts.
void main() {
  late String fakeProvider;

  setUpAll(() {
    fakeProvider = File(
      'supabase/functions/process-model-data-jobs/providers/fake_provider.ts',
    ).readAsStringSync();
  });

  group('fake_sample Toyota Camry 2020', () {
    test('returns succeeded sample with displayable metrics', () {
      expect(fakeProvider, contains('model: "camry"'));
      expect(fakeProvider, contains('year: 2020'));
      expect(fakeProvider, contains('combined_l_per_100km: 7.4'));
      expect(fakeProvider, contains('city_l_per_100km: 8.4'));
      expect(fakeProvider, contains('highway_l_per_100km: 6.0'));
      expect(fakeProvider, contains('co2_g_per_km: 173'));
      expect(fakeProvider, contains('fuel_type: "regular_gasoline"'));
      expect(fakeProvider, contains('status: "succeeded"'));
      expect(fakeProvider, contains('confidence: "official"'));
    });
  });

  group('fake_sample Toyota Highlander 2020', () {
    test('returns succeeded sample with displayable metrics', () {
      expect(fakeProvider, contains('model: "highlander"'));
      expect(fakeProvider, contains('fake-sample-2020-highlander'));
      expect(fakeProvider, contains('combined_l_per_100km: 9.8'));
      expect(fakeProvider, contains('city_l_per_100km: 11.2'));
      expect(fakeProvider, contains('highway_l_per_100km: 8.1'));
      expect(fakeProvider, contains('co2_g_per_km: 217'));
      expect(fakeProvider, contains('fuel_type: "regular_gasoline"'));
      expect(fakeProvider, contains('market: "US"'));
      expect(fakeProvider, contains('match_quality: "exact_make_model_year"'));
    });

    test('uses buyer-facing EPA source label without fake suffix', () {
      expect(fakeProvider, contains('sourceLabel: "EPA · FuelEconomy.gov",'));
      expect(
        fakeProvider.indexOf('sourceLabel: "EPA · FuelEconomy.gov (fake sample)"'),
        greaterThan(-1),
      );
    });
  });

  group('fake provider safety', () {
    test('default fake path still returns no_data', () {
      expect(fakeProvider, contains('status: "no_data"'));
      expect(fakeProvider, contains('fake-no-data-v1'));
    });

    test('includes required limitation codes via DEFAULT_EPA_LIMITATION_CODES', () {
      expect(fakeProvider, contains('DEFAULT_EPA_LIMITATION_CODES'));
      expect(
        File(
          'supabase/functions/process-model-data-jobs/providers/types.ts',
        ).readAsStringSync(),
        contains('us_market_data_only'),
      );
      expect(
        File(
          'supabase/functions/process-model-data-jobs/providers/types.ts',
        ).readAsStringSync(),
        contains('not_recall_data'),
      );
    });

    test('does not call real EPA HTTP', () {
      expect(fakeProvider.toLowerCase(), isNot(contains('await fetch(')));
      expect(fakeProvider.toLowerCase(), isNot(contains('fueleconomy.gov/ws/rest')));
    });
  });
}
