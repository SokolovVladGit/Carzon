import 'package:carzon/features/vehicle_model_data/domain/entities/buyer_listing_model_data_source_result.dart';
import 'package:carzon/features/vehicle_model_data/presentation/utils/model_passport_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

BuyerListingModelDataSourceResult _epaRow({
  String status = 'succeeded',
  Map<String, dynamic>? summary,
  String sourceId = 'epa_fueleconomy',
}) {
  return BuyerListingModelDataSourceResult(
    sourceId: sourceId,
    status: status,
    normalizedSummary: summary,
  );
}

void main() {
  group('resolveModelPassportUiState', () {
    test('returns hidden for empty list', () {
      expect(
        resolveModelPassportUiState(
          loading: false,
          fetchFailed: false,
          rows: const [],
        ),
        ModelPassportUiState.hidden,
      );
    });

    test('returns hidden for fetch failure', () {
      expect(
        resolveModelPassportUiState(
          loading: false,
          fetchFailed: true,
          rows: const [],
        ),
        ModelPassportUiState.hidden,
      );
    });

    test('returns loading while fetch in progress', () {
      expect(
        resolveModelPassportUiState(
          loading: true,
          fetchFailed: false,
          rows: const [],
        ),
        ModelPassportUiState.loading,
      );
    });

    test('returns hidden for unknown source only', () {
      expect(
        resolveModelPassportUiState(
          loading: false,
          fetchFailed: false,
          rows: [
            _epaRow(
              sourceId: 'wikidata',
              summary: {'combined_l_per_100km': 7.0},
            ),
          ],
        ),
        ModelPassportUiState.hidden,
      );
    });

    test('returns available for succeeded EPA row with displayable values', () {
      expect(
        resolveModelPassportUiState(
          loading: false,
          fetchFailed: false,
          rows: [
            _epaRow(
              summary: {'combined_l_per_100km': 7.35},
            ),
          ],
        ),
        ModelPassportUiState.available,
      );
    });

    test('returns partial for partial EPA row with displayable value', () {
      expect(
        resolveModelPassportUiState(
          loading: false,
          fetchFailed: false,
          rows: [
            _epaRow(
              status: 'partial',
              summary: {'fuel_type': 'Regular Gasoline'},
            ),
          ],
        ),
        ModelPassportUiState.partial,
      );
    });

    test('returns hidden for partial row with only forbidden summary fields', () {
      expect(
        resolveModelPassportUiState(
          loading: false,
          fetchFailed: false,
          rows: [
            _epaRow(
              status: 'partial',
              summary: {
                'transmission': 'Automatic',
                'drive': 'FWD',
                'engine_descriptor': '2.5L',
                'provider_vehicle_id': '12345',
                'combined_mpg': 32,
              },
            ),
          ],
        ),
        ModelPassportUiState.hidden,
      );
    });
  });
}
