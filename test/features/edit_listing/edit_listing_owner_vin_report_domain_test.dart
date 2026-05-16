import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_report_status.dart';
import 'package:carzon/features/edit_listing/presentation/utils/edit_listing_owner_vin_report_ui.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnerListingVinReportStatus.tryParse', () {
    test('parses decoded summary fields and excludes vin_hash key', () {
      final s = OwnerListingVinReportStatus.tryParse({
        'listing_id': '550e8400-e29b-41d4-a716-446655440000',
        'vin_status': 'format_valid',
        'processing_status': 'succeeded',
        'decode_status': 'decoded',
        'decoded_make': ' HONDA ',
        'decoded_model': 'Civic',
        'decoded_year': 2020,
        'decoded_body_type': 'Sedan',
        'decoded_fuel_type': 'Gasoline',
        'report_updated_at': '2026-05-01T12:00:00.000Z',
      });
      expect(s, isNotNull);
      expect(s!.decodedMake, 'HONDA');
      expect(s.decodedModel, 'Civic');
      expect(s.decodedYear, 2020);
      expect(s.decodedBodyType, 'Sedan');
      expect(s.decodedFuelType, 'Gasoline');
      expect(s.reportUpdatedAt, isNotNull);
    });

    test('returns null when listing_id missing', () {
      expect(
        OwnerListingVinReportStatus.tryParse({
          'decode_status': 'decoded',
        }),
        isNull,
      );
    });
  });

  group('resolveEditListingOwnerVinReportUiKind', () {
    test('no public VIN → noVinListed', () {
      expect(
        resolveEditListingOwnerVinReportUiKind(
          listingPublicVinStatus: ListingVinStatus.notProvided,
          reportFetchFailed: false,
          report: null,
        ),
        EditListingOwnerVinReportUiKind.noVinListed,
      );
    });

    test('fetch failure → unavailable', () {
      expect(
        resolveEditListingOwnerVinReportUiKind(
          listingPublicVinStatus: ListingVinStatus.formatValid,
          reportFetchFailed: true,
          report: null,
        ),
        EditListingOwnerVinReportUiKind.unavailable,
      );
    });

    test('succeeded + decoded → basicInfoProcessed', () {
      expect(
        resolveEditListingOwnerVinReportUiKind(
          listingPublicVinStatus: ListingVinStatus.formatValid,
          reportFetchFailed: false,
          report: const OwnerListingVinReportStatus(
            listingId: 'l1',
            processingStatusRaw: 'succeeded',
            decodeStatusRaw: 'decoded',
          ),
        ),
        EditListingOwnerVinReportUiKind.basicInfoProcessed,
      );
    });

    test('unknown future processing token → unavailable (fail safe)', () {
      expect(
        resolveEditListingOwnerVinReportUiKind(
          listingPublicVinStatus: ListingVinStatus.formatValid,
          reportFetchFailed: false,
          report: const OwnerListingVinReportStatus(
            listingId: 'l1',
            processingStatusRaw: 'quantum_processing',
          ),
        ),
        EditListingOwnerVinReportUiKind.unavailable,
      );
    });
  });

  group('editListingOwnerVinReportShowDecodedSummary', () {
    test('true only when succeeded+decoded and at least one field', () {
      expect(
        editListingOwnerVinReportShowDecodedSummary(
          const OwnerListingVinReportStatus(
            listingId: 'l1',
            processingStatusRaw: 'succeeded',
            decodeStatusRaw: 'decoded',
            decodedMake: 'X',
          ),
        ),
        isTrue,
      );
      expect(
        editListingOwnerVinReportShowDecodedSummary(
          const OwnerListingVinReportStatus(
            listingId: 'l1',
            processingStatusRaw: 'succeeded',
            decodeStatusRaw: 'decoded',
          ),
        ),
        isFalse,
      );
      expect(
        editListingOwnerVinReportShowDecodedSummary(
          const OwnerListingVinReportStatus(
            listingId: 'l1',
            processingStatusRaw: 'pending',
            decodeStatusRaw: 'decoded',
            decodedMake: 'X',
          ),
        ),
        isFalse,
      );
    });
  });
}
