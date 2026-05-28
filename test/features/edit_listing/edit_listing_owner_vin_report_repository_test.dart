import 'package:carzon/features/edit_listing/data/datasources/edit_listing_remote_datasource.dart';
import 'package:carzon/features/edit_listing/data/repositories/edit_listing_repository_impl.dart';
import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_report_status.dart';
import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_source_result.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements EditListingRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late EditListingRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = EditListingRepositoryImpl(remote);
  });

  test(
    'fetchOwnerVinReportStatus maps successful lookup from datasource',
    () async {
      when(() => remote.fetchOwnerListingVinReportStatus('lid')).thenAnswer(
        (_) async => OwnerListingVinReportLookupResult(
          status: OwnerListingVinReportStatus(
            listingId: 'lid',
            publicVinStatusRaw: 'format_valid',
            processingStatusRaw: 'succeeded',
            decodeStatusRaw: 'decoded',
            decodedMake: 'TOYOTA',
            decodedYear: 2021,
          ),
        ),
      );

      final out = await repo.fetchOwnerVinReportStatus('lid');
      expect(out, isA<Success<OwnerListingVinReportLookupResult>>());
      final v = (out as Success<OwnerListingVinReportLookupResult>).value;
      expect(v.fetchFailed, isFalse);
      expect(v.status?.decodeStatusRaw, 'decoded');
      expect(v.status?.decodedMake, 'TOYOTA');
      expect(v.status?.decodedYear, 2021);
    },
  );

  test(
    'fetchOwnerVinReportStatus returns Failure when datasource throws',
    () async {
      when(
        () => remote.fetchOwnerListingVinReportStatus('lid'),
      ).thenThrow(Exception('network'));

      final out = await repo.fetchOwnerVinReportStatus('lid');
      expect(out, isA<FailureResult<OwnerListingVinReportLookupResult>>());
    },
  );

  test('fetchOwnerVinSourceResults maps successful datasource list', () async {
    when(() => remote.fetchOwnerListingVinSourceResults('lid')).thenAnswer(
      (_) async => OwnerListingVinSourceResultsLookupResult(
        results: [
          OwnerListingVinSourceResult(
            sourceId: 'nhtsa_vpic',
            statusRaw: 'succeeded',
            normalizedSummary: const {'make': 'Mazda'},
          ),
        ],
      ),
    );

    final out = await repo.fetchOwnerVinSourceResults('lid');
    expect(out, isA<Success<OwnerListingVinSourceResultsLookupResult>>());
    final v = (out as Success<OwnerListingVinSourceResultsLookupResult>).value;
    expect(v.fetchFailed, isFalse);
    expect(v.results.single.sourceId, 'nhtsa_vpic');
    expect(v.results.single.normalizedSummary?['make'], 'Mazda');
  });

  test(
    'fetchOwnerVinSourceResults returns Failure when datasource throws',
    () async {
      when(
        () => remote.fetchOwnerListingVinSourceResults('lid'),
      ).thenThrow(Exception('network'));

      final out = await repo.fetchOwnerVinSourceResults('lid');
      expect(
        out,
        isA<FailureResult<OwnerListingVinSourceResultsLookupResult>>(),
      );
    },
  );
}
