import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_campaign.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_source_result.dart';
import 'package:carzon/features/vehicle_recall_data/presentation/utils/recall_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

BuyerListingRecallSourceResult _result({
  String status = 'succeeded',
  List<BuyerListingRecallCampaign> campaigns = const [],
  List<String> limitationCodes = const [],
}) {
  return BuyerListingRecallSourceResult(
    status: status,
    campaigns: campaigns,
    campaignCount: campaigns.length,
    limitationCodes: limitationCodes,
  );
}

void main() {
  group('resolveRecallUiState', () {
    test('returns loading while fetch in progress', () {
      expect(
        resolveRecallUiState(
          loading: true,
          fetchFailed: false,
          result: null,
        ),
        RecallUiState.loading,
      );
    });

    test('returns hidden on fetch failure', () {
      expect(
        resolveRecallUiState(
          loading: false,
          fetchFailed: true,
          result: null,
        ),
        RecallUiState.hidden,
      );
    });

    test('returns hidden for empty campaigns', () {
      expect(
        resolveRecallUiState(
          loading: false,
          fetchFailed: false,
          result: _result(),
        ),
        RecallUiState.hidden,
      );
    });

    test('returns hidden for campaigns without UI-displayable fields', () {
      expect(
        resolveRecallUiState(
          loading: false,
          fetchFailed: false,
          result: _result(
            campaigns: const [
              BuyerListingRecallCampaign(
                make: 'Toyota',
                model: 'Camry',
                modelYear: 2020,
              ),
            ],
          ),
        ),
        RecallUiState.hidden,
      );
    });

    test('returns visible when displayable campaigns exist', () {
      expect(
        resolveRecallUiState(
          loading: false,
          fetchFailed: false,
          result: _result(
            campaigns: const [
              BuyerListingRecallCampaign(
                campaignNumber: '20TA01',
                summary: 'Airbag inflator',
              ),
            ],
          ),
        ),
        RecallUiState.visible,
      );
    });

    test('returns partial for partial status with displayable campaigns', () {
      expect(
        resolveRecallUiState(
          loading: false,
          fetchFailed: false,
          result: _result(
            status: 'partial',
            limitationCodes: const ['multiple_campaigns_listed'],
            campaigns: const [
              BuyerListingRecallCampaign(
                campaignNumber: '20TA01',
                component: 'Airbag',
              ),
            ],
          ),
        ),
        RecallUiState.partial,
      );
    });
  });
}
