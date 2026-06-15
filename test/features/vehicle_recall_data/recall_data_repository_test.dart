import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/vehicle_recall_data/data/datasources/recall_data_remote_data_source.dart';
import 'package:carzon/features/vehicle_recall_data/data/repositories/recall_data_repository_impl.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_campaign.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_source_result.dart';
import 'package:carzon/features/vehicle_recall_data/domain/repositories/recall_data_repository.dart';
import 'package:carzon/features/vehicle_recall_data/domain/usecases/get_listing_recalls_for_buyer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements RecallDataRemoteDataSource {}

class _MockRepository extends Mock implements RecallDataRepository {}

void main() {
  group('RecallDataRepositoryImpl', () {
    late _MockRemote remote;
    late RecallDataRepositoryImpl repo;

    setUp(() {
      remote = _MockRemote();
      repo = RecallDataRepositoryImpl(remote);
    });

    test('returns parsed result on success', () async {
      const result = BuyerListingRecallSourceResult(
        sourceId: 'nhtsa_recalls',
        status: 'succeeded',
        campaigns: [
          BuyerListingRecallCampaign(
            campaignNumber: '20TA01',
            summary: 'One',
          ),
        ],
        campaignCount: 1,
        market: 'US',
      );

      when(
        () => remote.fetchListingRecallsForBuyer('lid'),
      ).thenAnswer((_) async => result);

      final out = await repo.getListingRecallsForBuyer('lid');
      expect(out, isA<Success<BuyerListingRecallSourceResult>>());
      expect(
        (out as Success<BuyerListingRecallSourceResult>).value.campaignCount,
        1,
      );
    });

    test('returns empty result without failure', () async {
      when(
        () => remote.fetchListingRecallsForBuyer('lid'),
      ).thenAnswer((_) async => BuyerListingRecallSourceResult.empty);

      final out = await repo.getListingRecallsForBuyer('lid');
      expect(out, isA<Success<BuyerListingRecallSourceResult>>());
      expect(
        (out as Success<BuyerListingRecallSourceResult>).value.hasCampaigns,
        isFalse,
      );
    });

    test('maps datasource failure to FailureResult', () async {
      when(
        () => remote.fetchListingRecallsForBuyer('lid'),
      ).thenThrow(Exception('boom'));

      final out = await repo.getListingRecallsForBuyer('lid');
      expect(out, isA<FailureResult<BuyerListingRecallSourceResult>>());
      expect(
        (out as FailureResult<BuyerListingRecallSourceResult>).failure,
        isA<UnknownFailure>(),
      );
    });
  });

  group('GetListingRecallsForBuyer', () {
    late _MockRepository repository;
    late GetListingRecallsForBuyer useCase;

    setUp(() {
      repository = _MockRepository();
      useCase = GetListingRecallsForBuyer(repository);
    });

    test('delegates to repository', () async {
      const result = BuyerListingRecallSourceResult(
        sourceId: 'nhtsa_recalls',
        campaignCount: 0,
      );

      when(
        () => repository.getListingRecallsForBuyer('lid'),
      ).thenAnswer((_) async => const Success(result));

      final out = await useCase('lid');
      expect(out, isA<Success<BuyerListingRecallSourceResult>>());
      verify(() => repository.getListingRecallsForBuyer('lid')).called(1);
    });
  });
}
