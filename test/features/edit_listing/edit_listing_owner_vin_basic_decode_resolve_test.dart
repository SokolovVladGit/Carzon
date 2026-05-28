import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_report_status.dart';
import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_source_result.dart';
import 'package:carzon/features/edit_listing/presentation/utils/edit_listing_owner_vin_report_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveOwnerVinBasicDecodeFields', () {
    test(
      'prefers NHTSA normalized_summary over empty legacy decoded fields',
      () {
        final report = OwnerListingVinReportStatus(
          listingId: 'l1',
          publicVinStatusRaw: 'format_valid',
          processingStatusRaw: 'succeeded',
          decodeStatusRaw: 'decoded',
        );
        final sources = [
          OwnerListingVinSourceResult(
            sourceId: 'nhtsa_vpic',
            statusRaw: 'succeeded',
            normalizedSummary: const {
              'make': 'Honda',
              'model': 'Civic',
              'year': 2019,
            },
          ),
        ];
        final f = resolveOwnerVinBasicDecodeFields(
          report: report,
          sourceResults: sources,
          sourceResultsLookupFailed: false,
        );
        expect(f, isNotNull);
        expect(f!.make, 'Honda');
        expect(f.model, 'Civic');
        expect(f.year, 2019);
      },
    );

    test('maps expanded NHTSA summary fields for owner display', () {
      final report = OwnerListingVinReportStatus(
        listingId: 'l1',
        publicVinStatusRaw: 'format_valid',
        processingStatusRaw: 'succeeded',
        decodeStatusRaw: 'decoded',
      );
      final sources = [
        OwnerListingVinSourceResult(
          sourceId: 'nhtsa_vpic',
          statusRaw: 'succeeded',
          normalizedSummary: const {
            'make': 'BMW',
            'engine': '2.0L',
            'transmission': 'Automatic',
            'trim': 'M Sport',
            'drive_type': 'AWD',
            'manufacturer': 'BMW AG',
          },
        ),
      ];
      final f = resolveOwnerVinBasicDecodeFields(
        report: report,
        sourceResults: sources,
        sourceResultsLookupFailed: false,
      );
      expect(f?.engine, '2.0L');
      expect(f?.transmission, 'Automatic');
      expect(f?.trim, 'M Sport');
      expect(f?.driveType, 'AWD');
      expect(f?.manufacturer, 'BMW AG');
    });

    test('falls back to legacy snapshot when source results empty', () {
      final report = OwnerListingVinReportStatus(
        listingId: 'l1',
        publicVinStatusRaw: 'format_valid',
        processingStatusRaw: 'succeeded',
        decodeStatusRaw: 'decoded',
        decodedMake: 'FORD',
      );
      final f = resolveOwnerVinBasicDecodeFields(
        report: report,
        sourceResults: const [],
        sourceResultsLookupFailed: false,
      );
      expect(f?.make, 'FORD');
    });

    test('when source-results fetch failed, still uses legacy snapshot', () {
      final report = OwnerListingVinReportStatus(
        listingId: 'l1',
        publicVinStatusRaw: 'format_valid',
        processingStatusRaw: 'succeeded',
        decodeStatusRaw: 'decoded',
        decodedMake: 'VW',
      );
      final f = resolveOwnerVinBasicDecodeFields(
        report: report,
        sourceResults: const [
          OwnerListingVinSourceResult(
            sourceId: 'nhtsa_vpic',
            statusRaw: 'succeeded',
            normalizedSummary: {'make': 'IGNORE'},
          ),
        ],
        sourceResultsLookupFailed: true,
      );
      expect(f?.make, 'VW');
    });
  });

  group('editListingOwnerVinReportShowDecodedSummaryForOwner', () {
    test('is true when only NHTSA source supplies fields', () {
      final ok = editListingOwnerVinReportShowDecodedSummaryForOwner(
        report: OwnerListingVinReportStatus(
          listingId: 'l1',
          publicVinStatusRaw: 'format_valid',
          processingStatusRaw: 'succeeded',
          decodeStatusRaw: 'decoded',
        ),
        sourceResults: const [
          OwnerListingVinSourceResult(
            sourceId: 'nhtsa_vpic',
            statusRaw: 'succeeded',
            normalizedSummary: {'make': 'X'},
          ),
        ],
        sourceResultsLookupFailed: false,
      );
      expect(ok, isTrue);
    });
  });
}
