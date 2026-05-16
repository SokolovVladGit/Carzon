import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/delete_listing.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/listings/domain/usecases/set_listing_status.dart';
import 'package:carzon/features/my_listings/presentation/bloc/my_listings_cubit.dart';
import 'package:carzon/features/my_listings/presentation/bloc/my_listings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

Listing _listing(String id, ListingStatus status) => Listing(
  id: id,
  title: 't-$id',
  make: 'Make',
  model: 'Model',
  year: 2020,
  priceEur: 10000,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
  status: status,
  sellerId: 's1',
);

void main() {
  setUpAll(() {
    registerFallbackValue(ListingStatus.active);
    registerFallbackValue(const ListingsQuery());
  });

  group('MyListingsCubit.updateStatus', () {
    late _MockListingsRepository repo;
    late MyListingsCubit cubit;

    final seededItems = [
      _listing('l1', ListingStatus.active),
      _listing('l2', ListingStatus.active),
    ];

    MyListingsState successState(List<Listing> items) =>
        MyListingsState(status: MyListingsStatus.success, items: items);

    setUp(() {
      repo = _MockListingsRepository();
      when(() => repo.fetchBuyerVinReportSources(any())).thenAnswer(
        (_) async => const Success(BuyerListingVinReportLookupResult()),
      );
      cubit = MyListingsCubit(
        getListings: GetListings(repo),
        setListingStatus: SetListingStatus(repo),
        deleteListing: DeleteListing(repo),
      );
    });

    tearDown(() => cubit.close());

    blocTest<MyListingsCubit, MyListingsState>(
      'replaces only the target item and clears pending on success',
      setUp: () {
        when(
          () => repo.updateStatus('l1', ListingStatus.sold),
        ).thenAnswer((_) async => Success(_listing('l1', ListingStatus.sold)));
      },
      build: () => cubit,
      seed: () => successState(seededItems),
      act: (c) => c.updateStatus('l1', ListingStatus.sold),
      expect: () => [
        successState(seededItems).copyWith(pendingStatusIds: const {'l1'}),
        successState([
          _listing('l1', ListingStatus.sold),
          _listing('l2', ListingStatus.active),
        ]).copyWith(pendingStatusIds: const <String>{}),
      ],
      verify: (_) {
        verify(() => repo.updateStatus('l1', ListingStatus.sold)).called(1);
      },
    );

    test('exposes pendingStatusIds while the RPC is in flight', () async {
      final completer = Completer<Result<Listing>>();
      when(
        () => repo.updateStatus('l1', ListingStatus.sold),
      ).thenAnswer((_) => completer.future);
      cubit.emit(successState(seededItems));

      final future = cubit.updateStatus('l1', ListingStatus.sold);
      // First synchronous emit sets the pending flag before awaiting.
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.pendingStatusIds, {'l1'});
      expect(cubit.state.items.first.status, ListingStatus.active);

      completer.complete(Success(_listing('l1', ListingStatus.sold)));
      await future;

      expect(cubit.state.pendingStatusIds, isEmpty);
      expect(cubit.state.items.first.status, ListingStatus.sold);
    });

    test('drops duplicate taps while the same listing is pending', () async {
      final completer = Completer<Result<Listing>>();
      when(
        () => repo.updateStatus('l1', ListingStatus.sold),
      ).thenAnswer((_) => completer.future);
      cubit.emit(successState(seededItems));

      final first = cubit.updateStatus('l1', ListingStatus.sold);
      await Future<void>.delayed(Duration.zero);
      // Second call while the first is in flight must not call the RPC again.
      await cubit.updateStatus('l1', ListingStatus.sold);

      completer.complete(Success(_listing('l1', ListingStatus.sold)));
      await first;

      verify(() => repo.updateStatus('l1', ListingStatus.sold)).called(1);
    });

    test('is a no-op when requested status equals current status', () async {
      cubit.emit(successState(seededItems));
      await cubit.updateStatus('l1', ListingStatus.active);

      verifyNever(() => repo.updateStatus(any(), any()));
      expect(cubit.state.pendingStatusIds, isEmpty);
      expect(cubit.state.lastActionError, isNull);
      expect(cubit.state.items, seededItems);
    });

    blocTest<MyListingsCubit, MyListingsState>(
      'on failure leaves items unchanged, clears pending, and emits ActionError',
      setUp: () {
        when(() => repo.updateStatus('l1', ListingStatus.sold)).thenAnswer(
          (_) async => const FailureResult(
            ServerFailure('listing not found or not owned by caller'),
          ),
        );
      },
      build: () => cubit,
      seed: () => successState(seededItems),
      act: (c) => c.updateStatus('l1', ListingStatus.sold),
      verify: (c) {
        expect(c.state.items, seededItems);
        expect(c.state.pendingStatusIds, isEmpty);
        expect(c.state.lastActionError, isNotNull);
        // Raw DB wording is mapped to a structured failure kind that the
        // presentation layer renders in the user's language.
        expect(
          c.state.lastActionError!.kind,
          MyListingActionFailureKind.statusNotAllowed,
        );
      },
    );

    test('repeated identical failures emit distinct ActionError ids', () async {
      when(
        () => repo.updateStatus('l1', ListingStatus.sold),
      ).thenAnswer((_) async => const FailureResult(ServerFailure('boom')));
      cubit.emit(successState(seededItems));

      await cubit.updateStatus('l1', ListingStatus.sold);
      final firstId = cubit.state.lastActionError!.id;
      final firstKind = cubit.state.lastActionError!.kind;

      // After the first failure the pending flag is cleared, so the second
      // call proceeds. Current status is still active (failure didn't mutate
      // items), so the same-status guard doesn't trigger either.
      await cubit.updateStatus('l1', ListingStatus.sold);
      final secondId = cubit.state.lastActionError!.id;
      final secondKind = cubit.state.lastActionError!.kind;

      expect(firstKind, secondKind);
      expect(secondId, isNot(firstId));
      expect(secondId, greaterThan(firstId));
    });

    test('maps invalid-status failures to the invalid-status kind', () async {
      when(() => repo.updateStatus('l1', ListingStatus.sold)).thenAnswer(
        (_) async =>
            const FailureResult(ServerFailure('invalid listing status: foo')),
      );
      cubit.emit(successState(seededItems));

      await cubit.updateStatus('l1', ListingStatus.sold);
      expect(
        cubit.state.lastActionError!.kind,
        MyListingActionFailureKind.statusInvalid,
      );
    });

    test('maps unknown failures to the generic status failure kind', () async {
      when(() => repo.updateStatus('l1', ListingStatus.sold)).thenAnswer(
        (_) async => const FailureResult(UnknownFailure('weird network thing')),
      );
      cubit.emit(successState(seededItems));

      await cubit.updateStatus('l1', ListingStatus.sold);
      expect(
        cubit.state.lastActionError!.kind,
        MyListingActionFailureKind.statusGeneric,
      );
    });

    test('acknowledgeActionError clears lastActionError', () async {
      when(() => repo.updateStatus('l1', ListingStatus.sold)).thenAnswer(
        (_) async => const FailureResult(ServerFailure('not owned')),
      );
      cubit.emit(successState(seededItems));

      await cubit.updateStatus('l1', ListingStatus.sold);
      expect(cubit.state.lastActionError, isNotNull);

      cubit.acknowledgeActionError();
      expect(cubit.state.lastActionError, isNull);
    });
  });

  group('MyListingsCubit.deleteListing', () {
    late _MockListingsRepository repo;
    late MyListingsCubit cubit;

    final seededItems = [
      _listing('l1', ListingStatus.active),
      _listing('l2', ListingStatus.archived),
    ];

    MyListingsState successState(List<Listing> items) =>
        MyListingsState(status: MyListingsStatus.success, items: items);

    setUp(() {
      repo = _MockListingsRepository();
      when(() => repo.fetchBuyerVinReportSources(any())).thenAnswer(
        (_) async => const Success(BuyerListingVinReportLookupResult()),
      );
      cubit = MyListingsCubit(
        getListings: GetListings(repo),
        setListingStatus: SetListingStatus(repo),
        deleteListing: DeleteListing(repo),
      );
    });

    tearDown(() => cubit.close());

    blocTest<MyListingsCubit, MyListingsState>(
      'removes the deleted item from state on success',
      setUp: () {
        when(
          () => repo.deleteListing('l1'),
        ).thenAnswer((_) async => const Success(null));
      },
      build: () => cubit,
      seed: () => successState(seededItems),
      act: (c) => c.deleteListing('l1'),
      expect: () => [
        successState(seededItems).copyWith(pendingDeleteIds: const {'l1'}),
        successState([
          _listing('l2', ListingStatus.archived),
        ]).copyWith(pendingDeleteIds: const <String>{}),
      ],
      verify: (_) {
        verify(() => repo.deleteListing('l1')).called(1);
      },
    );

    test('exposes pendingDeleteIds while the RPC is in flight', () async {
      final completer = Completer<Result<void>>();
      when(() => repo.deleteListing('l1')).thenAnswer((_) => completer.future);
      cubit.emit(successState(seededItems));

      final future = cubit.deleteListing('l1');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.pendingDeleteIds, {'l1'});
      expect(cubit.state.items, seededItems);

      completer.complete(const Success(null));
      await future;

      expect(cubit.state.pendingDeleteIds, isEmpty);
      expect(cubit.state.items.map((e) => e.id), ['l2']);
    });

    test(
      'drops duplicate taps while the same listing is being deleted',
      () async {
        final completer = Completer<Result<void>>();
        when(
          () => repo.deleteListing('l1'),
        ).thenAnswer((_) => completer.future);
        cubit.emit(successState(seededItems));

        final first = cubit.deleteListing('l1');
        await Future<void>.delayed(Duration.zero);
        await cubit.deleteListing('l1');

        completer.complete(const Success(null));
        await first;

        verify(() => repo.deleteListing('l1')).called(1);
      },
    );

    test('is a no-op when listing id is not in the current list', () async {
      cubit.emit(successState(seededItems));
      await cubit.deleteListing('does-not-exist');

      verifyNever(() => repo.deleteListing(any()));
      expect(cubit.state.pendingDeleteIds, isEmpty);
      expect(cubit.state.items, seededItems);
      expect(cubit.state.lastActionError, isNull);
    });

    blocTest<MyListingsCubit, MyListingsState>(
      'on failure keeps items, clears pending, and emits a friendly error',
      setUp: () {
        when(() => repo.deleteListing('l1')).thenAnswer(
          (_) async => const FailureResult(
            ServerFailure('listing not found or not owned by caller'),
          ),
        );
      },
      build: () => cubit,
      seed: () => successState(seededItems),
      act: (c) => c.deleteListing('l1'),
      verify: (c) {
        expect(c.state.items, seededItems);
        expect(c.state.pendingDeleteIds, isEmpty);
        expect(c.state.lastActionError, isNotNull);
        expect(
          c.state.lastActionError!.kind,
          MyListingActionFailureKind.deleteNotAllowed,
        );
      },
    );

    test(
      'maps unknown delete failures to the generic delete failure kind',
      () async {
        when(() => repo.deleteListing('l1')).thenAnswer(
          (_) async => const FailureResult(UnknownFailure('weird transport')),
        );
        cubit.emit(successState(seededItems));

        await cubit.deleteListing('l1');
        expect(
          cubit.state.lastActionError!.kind,
          MyListingActionFailureKind.deleteGeneric,
        );
        expect(cubit.state.items, seededItems);
      },
    );
  });

  group('MyListingsCubit.load', () {
    late _MockListingsRepository repo;
    late MyListingsCubit cubit;

    setUp(() {
      repo = _MockListingsRepository();
      when(() => repo.fetchBuyerVinReportSources(any())).thenAnswer(
        (_) async => const Success(BuyerListingVinReportLookupResult()),
      );
      cubit = MyListingsCubit(
        getListings: GetListings(repo),
        setListingStatus: SetListingStatus(repo),
        deleteListing: DeleteListing(repo),
      );
    });

    tearDown(() => cubit.close());

    blocTest<MyListingsCubit, MyListingsState>(
      'queries by sellerId with no status filter so owner sees all statuses',
      setUp: () {
        when(() => repo.getListings(any())).thenAnswer(
          (_) async => Success([_listing('l1', ListingStatus.hidden)]),
        );
      },
      build: () => cubit,
      act: (c) => c.load('s1'),
      verify: (_) {
        final captured = verify(() => repo.getListings(captureAny())).captured;
        expect(captured, hasLength(1));
        final q = captured.single as ListingsQuery;
        expect(q.sellerId, 's1');
        expect(
          q.status,
          isNull,
          reason: 'My Listings must NOT force status = active',
        );
      },
    );
  });
}
