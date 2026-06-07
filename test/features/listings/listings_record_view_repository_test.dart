import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/data/datasources/listings_remote_datasource.dart';
import 'package:carzon/features/listings/data/repositories/listings_repository_impl.dart';
import 'package:carzon/features/listings/domain/entities/listing_view_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ListingsRemoteDataSource {}

void main() {
  late _MockRemote remote;

  setUp(() {
    remote = _MockRemote();
  });

  test('recordListingView returns Success with mapped stats', () async {
    when(() => remote.recordListingView('l1', 'anon-1')).thenAnswer(
      (_) async => const ListingViewStats(totalViews: 128, todayViews: 12),
    );

    final repo = ListingsRepositoryImpl(remote);
    final result = await repo.recordListingView('l1', 'anon-1');

    expect(result, isA<Success<ListingViewStats>>());
    expect((result as Success).value.totalViews, 128);
    expect((result as Success).value.todayViews, 12);
    verify(() => remote.recordListingView('l1', 'anon-1')).called(1);
  });

  test('recordListingView maps ServerException to FailureResult', () async {
    when(
      () => remote.recordListingView('l1', 'anon-1'),
    ).thenThrow(Exception('network'));

    final repo = ListingsRepositoryImpl(remote);
    final result = await repo.recordListingView('l1', 'anon-1');

    expect(result, isA<FailureResult<ListingViewStats>>());
    expect((result as FailureResult).failure, isA<UnknownFailure>());
  });
}
