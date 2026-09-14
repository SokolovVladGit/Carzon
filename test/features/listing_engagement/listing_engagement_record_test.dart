import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listing_engagement/data/datasources/listing_engagement_remote_datasource.dart';
import 'package:carzon/features/listing_engagement/data/mappers/listing_engagement_mapper.dart';
import 'package:carzon/features/listing_engagement/data/repositories/listing_engagement_repository_impl.dart';
import 'package:carzon/features/listing_engagement/domain/entities/listing_engagement_event_type.dart';
import 'package:carzon/features/listing_engagement/domain/entities/listing_engagement_record_result.dart';
import 'package:carzon/features/listing_engagement/domain/repositories/listing_engagement_repository.dart';
import 'package:carzon/features/listing_engagement/domain/usecases/record_listing_engagement.dart';
import 'package:carzon/features/listings/domain/repositories/anonymous_viewer_id_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ListingEngagementRepository {}

class _MockAnon extends Mock implements AnonymousViewerIdRepository {}

class _MockRemote extends Mock implements ListingEngagementRemoteDataSource {}

class _ThrowingRepo implements ListingEngagementRepository {
  @override
  Future<Result<ListingEngagementRecordResult>> recordEvent({
    required String listingId,
    required ListingEngagementEventType eventType,
    required String anonymousViewerId,
  }) {
    throw StateError('rpc exploded');
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(ListingEngagementEventType.phone);
  });

  test('maps recorded + today_count and never exposes viewer identity', () {
    final result = listingEngagementRecordResultFromRow({
      'recorded': true,
      'today_count': 3,
      'viewer_hash': 'must-not-be-mapped',
    });
    expect(result.recorded, isTrue);
    expect(result.todayCount, 3);
    expect(result.props, [true, 3]);
  });

  test('anonymous viewer id is forwarded to the repository', () async {
    final repo = _MockRepo();
    final anon = _MockAnon();
    when(() => anon.getOrCreate()).thenAnswer((_) async => 'anon-42');
    when(
      () => repo.recordEvent(
        listingId: any(named: 'listingId'),
        eventType: any(named: 'eventType'),
        anonymousViewerId: any(named: 'anonymousViewerId'),
      ),
    ).thenAnswer(
      (_) async => const Success(
        ListingEngagementRecordResult(recorded: true, todayCount: 1),
      ),
    );

    final result = await RecordListingEngagement(repo, anon)(
      listingId: 'listing-1',
      eventType: ListingEngagementEventType.whatsapp,
    );

    expect(result, isA<Success<ListingEngagementRecordResult>>());
    verify(
      () => repo.recordEvent(
        listingId: 'listing-1',
        eventType: ListingEngagementEventType.whatsapp,
        anonymousViewerId: 'anon-42',
      ),
    ).called(1);
  });

  test(
    'authenticated recording still supplies the anonymous parameter',
    () async {
      final repo = _MockRepo();
      final anon = _MockAnon();
      when(() => anon.getOrCreate()).thenAnswer((_) async => 'device-id');
      when(
        () => repo.recordEvent(
          listingId: any(named: 'listingId'),
          eventType: any(named: 'eventType'),
          anonymousViewerId: any(named: 'anonymousViewerId'),
        ),
      ).thenAnswer(
        (_) async => const Success(
          ListingEngagementRecordResult(recorded: false, todayCount: 1),
        ),
      );

      await RecordListingEngagement(repo, anon)(
        listingId: 'listing-1',
        eventType: ListingEngagementEventType.phone,
      );

      verify(
        () => repo.recordEvent(
          listingId: 'listing-1',
          eventType: ListingEngagementEventType.phone,
          anonymousViewerId: 'device-id',
        ),
      ).called(1);
    },
  );

  test('anonymous id failure still records with an empty viewer id', () async {
    final repo = _MockRepo();
    final anon = _MockAnon();
    when(() => anon.getOrCreate()).thenThrow(StateError('prefs down'));
    when(
      () => repo.recordEvent(
        listingId: any(named: 'listingId'),
        eventType: any(named: 'eventType'),
        anonymousViewerId: any(named: 'anonymousViewerId'),
      ),
    ).thenAnswer(
      (_) async => const Success(
        ListingEngagementRecordResult(recorded: false, todayCount: 0),
      ),
    );

    await RecordListingEngagement(repo, anon)(
      listingId: 'listing-1',
      eventType: ListingEngagementEventType.share,
    );

    verify(
      () => repo.recordEvent(
        listingId: 'listing-1',
        eventType: ListingEngagementEventType.share,
        anonymousViewerId: '',
      ),
    ).called(1);
  });

  test(
    'RPC failure becomes a controlled Result, not a thrown exception',
    () async {
      final remote = _MockRemote();
      when(
        () => remote.recordEvent(
          listingId: any(named: 'listingId'),
          eventType: any(named: 'eventType'),
          anonymousViewerId: any(named: 'anonymousViewerId'),
        ),
      ).thenThrow(ServerException('rpc failed'));

      final result = await ListingEngagementRepositoryImpl(remote).recordEvent(
        listingId: 'listing-1',
        eventType: ListingEngagementEventType.impression,
        anonymousViewerId: 'anon',
      );

      expect(result, isA<FailureResult<ListingEngagementRecordResult>>());
      expect(
        (result as FailureResult<ListingEngagementRecordResult>).failure,
        isA<ServerFailure>(),
      );
    },
  );

  test('fire-and-forget swallows recorder exceptions', () async {
    final anon = _MockAnon();
    when(() => anon.getOrCreate()).thenAnswer((_) async => 'anon');
    final useCase = RecordListingEngagement(_ThrowingRepo(), anon);

    expect(
      () => useCase.recordFireAndForget(
        listingId: 'listing-1',
        eventType: ListingEngagementEventType.phone,
      ),
      returnsNormally,
    );
    await Future<void>.delayed(Duration.zero);
  });
}
