import 'package:carzon/features/vehicle_model_data/presentation/utils/model_passport_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();

  group('formatModelPassportConsumption', () {
    test('formats L/100km with one decimal', () {
      expect(formatModelPassportConsumption(7.35), '7.4');
      expect(formatModelPassportConsumption(8.0), '8.0');
    });
  });

  group('formatModelPassportCo2', () {
    test('formats CO₂ as integer g/km', () {
      expect(formatModelPassportCo2(175), '175');
    });
  });

  group('buildModelPassportMetricRows', () {
    test('omits null and invalid values', () {
      final rows = buildModelPassportMetricRows(ru, {
        'combined_l_per_100km': 7.35,
        'city_l_per_100km': null,
        'highway_l_per_100km': 'not-a-number',
        'co2_g_per_km': 0,
        'fuel_type': '  ',
      });

      expect(rows, hasLength(1));
      expect(rows[0].label, ru.listingModelPassportCombinedConsumption);
      expect(rows[0].value, '7.4');
      expect(rows[0].unit, ru.listingModelPassportUnitLPer100km);
    });

    test('includes city, highway, fuel type when present', () {
      final rows = buildModelPassportMetricRows(ru, {
        'city_l_per_100km': 8.12,
        'highway_l_per_100km': 6.78,
        'fuel_type': 'Regular Gasoline',
      });

      expect(rows.map((r) => r.label), [
        ru.listingModelPassportCityConsumption,
        ru.listingModelPassportHighwayConsumption,
        ru.listingModelPassportFuelType,
      ]);
      expect(rows[0].value, '8.1');
      expect(rows[1].value, '6.8');
      expect(rows[2].value, ru.listingModelPassportFuelRegularGasoline);
      expect(rows[2].unit, isNull);
    });
  });

  group('formatModelPassportFuelTypeDisplay', () {
    test('maps known EPA fuel type codes to localized labels', () {
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'regular_gasoline'),
        ru.listingModelPassportFuelRegularGasoline,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'regular gasoline'),
        ru.listingModelPassportFuelRegularGasoline,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'regular'),
        ru.listingModelPassportFuelRegularGasoline,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'premium_gasoline'),
        ru.listingModelPassportFuelPremiumGasoline,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'midgrade_gasoline'),
        ru.listingModelPassportFuelMidgradeGasoline,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'diesel'),
        ru.listingModelPassportFuelDiesel,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'electricity'),
        ru.listingModelPassportFuelElectricity,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'electric'),
        ru.listingModelPassportFuelElectricity,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'hybrid'),
        ru.listingModelPassportFuelHybrid,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'plug_in_hybrid'),
        ru.listingModelPassportFuelPlugInHybrid,
      );
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'plug-in hybrid'),
        ru.listingModelPassportFuelPlugInHybrid,
      );
    });

    test('unknown snake_case values use generic fallback', () {
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'flex_fuel_e85'),
        ru.listingModelPassportFuelTypeGeneric,
      );
    });

    test('unknown values without underscores are shown humanized', () {
      expect(
        formatModelPassportFuelTypeDisplay(ru, 'Natural Gas'),
        'Natural Gas',
      );
    });
  });

  group('resolveModelPassportSourceLabel', () {
    test('uses localized EPA label when source_label missing', () {
      expect(
        resolveModelPassportSourceLabel(ru, null),
        ru.listingModelPassportSourceEpa,
      );
      expect(
        resolveModelPassportSourceLabel(ru, '  '),
        ru.listingModelPassportSourceEpa,
      );
    });

    test('keeps provider source_label when present', () {
      expect(
        resolveModelPassportSourceLabel(ru, 'Custom EPA label'),
        'Custom EPA label',
      );
    });
  });

  test('readModelPassportDouble ignores invalid numeric strings safely', () {
    expect(readModelPassportDouble('abc'), isNull);
    expect(readModelPassportDouble('-1'), isNull);
    expect(readModelPassportDouble('7.4'), 7.4);
  });

  group('buildModelPassportPrimaryMetricTiles', () {
    test('returns consumption and fuel type tiles without CO2', () {
      final tiles = buildModelPassportPrimaryMetricTiles(
        ru,
        const {
          'combined_l_per_100km': 7.35,
          'city_l_per_100km': 8.12,
          'highway_l_per_100km': 6.78,
          'co2_g_per_km': 175.6,
          'fuel_type': 'Regular Gasoline',
        },
      );

      expect(tiles, hasLength(4));
      expect(tiles.first.isPrimaryHighlight, isTrue);
      expect(tiles.skip(1).every((t) => !t.isPrimaryHighlight), isTrue);
      expect(tiles.map((t) => t.label), [
        ru.listingModelPassportCombinedConsumption,
        ru.listingModelPassportCityConsumption,
        ru.listingModelPassportHighwayConsumption,
        ru.listingModelPassportFuelType,
      ]);
    });
  });

  group('buildModelPassportCo2MetricTile', () {
    test('returns separate CO2 tile when present', () {
      final tile = buildModelPassportCo2MetricTile(
        ru,
        const {'co2_g_per_km': 175.6},
      );

      expect(tile, isNotNull);
      expect(tile!.label, ru.listingModelPassportCo2Emissions);
      expect(tile.value, '176');
    });
  });
}
