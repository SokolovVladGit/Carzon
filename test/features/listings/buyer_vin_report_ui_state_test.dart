import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/buyer_vin_report_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveBuyerVinReportUiState', () {
    test('noVin when listing vin_status is not_provided', () {
      expect(
        resolveBuyerVinReportUiState(
          listingVinStatus: ListingVinStatus.notProvided,
        ),
        BuyerVinReportUiState.noVin,
      );
    });

    test('loading when fetch in progress', () {
      expect(
        resolveBuyerVinReportUiState(
          listingVinStatus: ListingVinStatus.formatValid,
          loading: true,
        ),
        BuyerVinReportUiState.loading,
      );
    });

    test('unavailableOrError when fetchFailed', () {
      expect(
        resolveBuyerVinReportUiState(
          listingVinStatus: ListingVinStatus.formatValid,
          lookup: const BuyerListingVinReportLookupResult(fetchFailed: true),
          fetchFailed: true,
        ),
        BuyerVinReportUiState.unavailableOrError,
      );
    });

    test('reportAvailable when displayable normalized_summary exists', () {
      expect(
        resolveBuyerVinReportUiState(
          listingVinStatus: ListingVinStatus.formatValid,
          lookup: BuyerListingVinReportLookupResult(
            results: [
              BuyerListingVinReportSourceResult(
                sourceId: 'nhtsa_vpic',
                normalizedSummary: {'make': 'Toyota'},
              ),
            ],
          ),
        ),
        BuyerVinReportUiState.reportAvailable,
      );
    });

    test('pendingOrNotReady when status is pending or processing', () {
      expect(
        resolveBuyerVinReportUiState(
          listingVinStatus: ListingVinStatus.formatValid,
          lookup: BuyerListingVinReportLookupResult(
            results: [
              BuyerListingVinReportSourceResult(
                sourceId: 'nhtsa_vpic',
                statusRaw: 'pending',
              ),
            ],
          ),
        ),
        BuyerVinReportUiState.pendingOrNotReady,
      );
      expect(
        resolveBuyerVinReportUiState(
          listingVinStatus: ListingVinStatus.formatValid,
          lookup: BuyerListingVinReportLookupResult(
            results: [
              BuyerListingVinReportSourceResult(
                sourceId: 'nhtsa_vpic',
                statusRaw: 'processing',
              ),
            ],
          ),
        ),
        BuyerVinReportUiState.pendingOrNotReady,
      );
    });

    test('noPublicData when VIN present but no displayable decode', () {
      expect(
        resolveBuyerVinReportUiState(
          listingVinStatus: ListingVinStatus.formatValid,
          lookup: const BuyerListingVinReportLookupResult(),
        ),
        BuyerVinReportUiState.noPublicData,
      );
      expect(
        resolveBuyerVinReportUiState(
          listingVinStatus: ListingVinStatus.formatValid,
          lookup: BuyerListingVinReportLookupResult(
            results: [
              BuyerListingVinReportSourceResult(
                sourceId: 'nhtsa_vpic',
                normalizedSummary: const {},
              ),
            ],
          ),
        ),
        BuyerVinReportUiState.noPublicData,
      );
    });
  });

  group('buyerVinReportShowsSuccessBadge', () {
    test('only true for reportAvailable', () {
      expect(
        buyerVinReportShowsSuccessBadge(BuyerVinReportUiState.reportAvailable),
        isTrue,
      );
      for (final s in BuyerVinReportUiState.values) {
        if (s == BuyerVinReportUiState.reportAvailable) continue;
        expect(buyerVinReportShowsSuccessBadge(s), isFalse, reason: '$s');
      }
    });
  });
}
