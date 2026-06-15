import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/vehicle_model_data/data/repositories/model_data_repository_impl.dart';
import 'package:carzon/features/vehicle_model_data/data/datasources/model_data_remote_datasource.dart';
import 'package:carzon/features/vehicle_model_data/domain/entities/buyer_listing_model_data_source_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ModelDataRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late ModelDataRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = ModelDataRepositoryImpl(remote);
  });

  test('getListingModelDataForBuyer maps successful RPC list', () async {
    when(() => remote.fetchListingModelDataForBuyer('lid')).thenAnswer(
      (_) async => const [
        BuyerListingModelDataSourceResult(
          sourceId: 'epa_fueleconomy',
          status: 'succeeded',
          normalizedSummary: {'combined_mpg': 32},
        ),
      ],
    );

    final out = await repo.getListingModelDataForBuyer('lid');
    expect(out, isA<Success<List<BuyerListingModelDataSourceResult>>>());
    final value =
        (out as Success<List<BuyerListingModelDataSourceResult>>).value;
    expect(value.single.sourceId, 'epa_fueleconomy');
  });

  test('getListingModelDataForBuyer maps datasource failure to FailureResult', () async {
    when(
      () => remote.fetchListingModelDataForBuyer('lid'),
    ).thenThrow(Exception('boom'));

    final out = await repo.getListingModelDataForBuyer('lid');
    expect(out, isA<FailureResult<List<BuyerListingModelDataSourceResult>>>());
    final failure =
        (out as FailureResult<List<BuyerListingModelDataSourceResult>>)
            .failure;
    expect(failure, isA<UnknownFailure>());
  });
}
