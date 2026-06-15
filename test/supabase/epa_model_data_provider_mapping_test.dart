import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static + formula checks for EPA FuelEconomy.gov mapping helpers.
void main() {
  late String mappingTs;
  late String providerTs;

  setUpAll(() {
    mappingTs = File(
      'supabase/functions/process-model-data-jobs/providers/epa_mapping.ts',
    ).readAsStringSync();
    providerTs = File(
      'supabase/functions/process-model-data-jobs/providers/epa_provider.ts',
    ).readAsStringSync();
  });

  group('epa_mapping.ts formulas', () {
    double mpgToLPer100km(double mpg) =>
        (235.214 / mpg * 10).roundToDouble() / 10;

    int co2GPerMileToGPerKm(double gPerMile) =>
        (gPerMile * 0.621371).round();

    test('MPG to L/100km conversion matches documented formula', () {
      expect(mpgToLPer100km(32), 7.4);
      expect(mpgToLPer100km(28), 8.4);
      expect(mappingTs, contains('235.214'));
      expect(mappingTs, contains('mpgToLPer100km'));
    });

    test('CO2 g/mile to g/km conversion matches documented formula', () {
      expect(co2GPerMileToGPerKm(278), 173);
      expect(mappingTs, contains('0.621371'));
      expect(mappingTs, contains('co2GPerMileToGPerKm'));
    });

    test('invalid MPG yields null handling in mapper source', () {
      expect(mappingTs, contains('mpg <= 0'));
      expect(mappingTs, contains('return null'));
    });
  });

  group('epa_mapping.ts XML parsing', () {
    test('vehicle detail parser reads EPA XML tags', () {
      expect(mappingTs, contains('city08'));
      expect(mappingTs, contains('highway08'));
      expect(mappingTs, contains('comb08'));
      expect(mappingTs, contains('co2TailpipeGpm'));
      expect(mappingTs, contains('fuelType'));
      expect(mappingTs, contains('VClass'));
      expect(mappingTs, contains('parseEpaVehicleDetailXml'));
    });

    test('menu options parser extracts vehicle ids', () {
      expect(mappingTs, contains('parseMenuOptionVehicleIds'));
      expect(mappingTs, contains('<menuItem>'));
      expect(mappingTs, contains('<value>'));
    });

    test('menu options parser handles EPA text-before-value XML order', () {
      expect(
        mappingTs,
        contains('<menuItem>[\\s\\S]*?<value>([^<]+)<\\/value>'),
      );
      expect(mappingTs, isNot(contains('<menuItem>\\s*<value>')));
    });

    test('sample vehicle XML maps to expected numeric fields in source', () {
      const sampleXml = '''
<vehicle>
  <id>12345</id>
  <city08>28</city08>
  <highway08>39</highway08>
  <comb08>32</comb08>
  <co2TailpipeGpm>278</co2TailpipeGpm>
  <fuelType>Regular Gasoline</fuelType>
  <VClass>Midsize Cars</VClass>
</vehicle>
''';
      expect(sampleXml, contains('<comb08>32</comb08>'));
      expect(mappingTs, contains('buildEpaSummaryFromVehicleDetail'));
      expect(mappingTs, isNot(contains('DOMParser')));
    });
  });

  group('epa provider behavior (static)', () {
    test('uses official FuelEconomy.gov REST endpoints', () {
      expect(mappingTs, contains('fueleconomy.gov/ws/rest/vehicle'));
      expect(mappingTs, contains('/menu/options'));
      expect(providerTs, contains('EpaFuelEconomyProvider'));
    });

    test('no-data and multiple-option strategies are explicit', () {
      expect(mappingTs, contains('buildEpaNoDataResult'));
      expect(mappingTs, contains('aggregateEpaVehicleDetails'));
      expect(mappingTs, contains('make_model_year_multiple_options'));
      expect(providerTs, contains('MAX_MULTI_OPTIONS'));
      expect(providerTs, contains('average_numeric_fields'));
    });

    test('required limitation codes are present', () {
      final typesTs = File(
        'supabase/functions/process-model-data-jobs/providers/types.ts',
      ).readAsStringSync();
      expect(typesTs, contains('us_market_data_only'));
      expect(mappingTs, contains('defaultEpaSuccessLimitationCodes'));
      expect(providerTs, contains('multiple_configurations_possible'));
      expect(mappingTs, contains('source_data_unavailable'));
    });

    test('does not store raw XML in normalized summary', () {
      expect(mappingTs, isNot(contains('normalized_summary: xml')));
      expect(providerTs, isNot(contains('rawXml')));
      expect(providerTs, isNot(contains('console.log')));
    });

    test('no Wikidata or manufacturer scraping', () {
      expect(providerTs.toLowerCase(), isNot(contains('wikidata')));
      expect(mappingTs.toLowerCase(), isNot(contains('wikidata')));
      expect(providerTs.toLowerCase(), isNot(contains('manufacturer.com')));
    });

    test('epa mode is opt-in via factory', () {
      final factoryTs = File(
        'supabase/functions/process-model-data-jobs/providers/factory.ts',
      ).readAsStringSync();
      expect(factoryTs, contains('"epa"'));
      expect(factoryTs, contains('EpaFuelEconomyProvider'));
      expect(factoryTs, contains('"fake"'));
    });
  });
}
