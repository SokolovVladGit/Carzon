import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/data/datasources/listings_remote_datasource.dart';
import 'package:carzon/features/listings/data/repositories/listings_repository_impl.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ListingsRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late ListingsRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = ListingsRepositoryImpl(remote);
  });

  test('fetchBuyerVinReportSources maps successful lookup', () async {
    when(() => remote.fetchBuyerListingVinReportSources('lid')).thenAnswer(
      (_) async => BuyerListingVinReportLookupResult(
        results: [
          const BuyerListingVinReportSourceResult(
            sourceId: 'nhtsa_vpic',
            normalizedSummary: {'make': 'Toyota'},
          ),
        ],
      ),
    );

    final out = await repo.fetchBuyerVinReportSources('lid');
    expect(out, isA<Success<BuyerListingVinReportLookupResult>>());
    final v = (out as Success<BuyerListingVinReportLookupResult>).value;
    expect(v.fetchFailed, isFalse);
    expect(v.results.single.sourceId, 'nhtsa_vpic');
  });

  test('fetchBuyerVinReportSources returns Success with fetchFailed on unknown error', () async {
    when(
      () => remote.fetchBuyerListingVinReportSources('lid'),
    ).thenThrow(Exception('boom'));

    final out = await repo.fetchBuyerVinReportSources('lid');
    expect(out, isA<Success<BuyerListingVinReportLookupResult>>());
    final v = (out as Success<BuyerListingVinReportLookupResult>).value;
    expect(v.fetchFailed, isTrue);
  });
}
