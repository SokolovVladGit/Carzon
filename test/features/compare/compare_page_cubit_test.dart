import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/entities/compare_resolved_slot.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_page_cubit.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_page_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_image.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_by_id.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_images.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetListingById extends Mock implements GetListingById {}

class _MockGetListingImages extends Mock implements GetListingImages {}

CompareItem _item(String id) => CompareItem(
  snapshot: CompareListingSnapshot(
    listingId: id,
    addedAt: DateTime.utc(2026, 5, 22),
    make: 'BMW',
    model: '3',
  ),
);

Listing _listing({
  required String id,
  ListingStatus status = ListingStatus.active,
  ListingVinStatus vin = ListingVinStatus.notProvided,
}) {
  return Listing(
    id: id,
    title: 'Test',
    make: 'BMW',
    model: '3',
    year: 2018,
    priceEur: 15000,
    mileageKm: 80000,
    type: ListingType.sale,
    city: 'Chișinău',
    marketRegion: MarketRegion.moldova,
    createdAt: DateTime.utc(2026, 4, 1),
    status: status,
    vinStatus: vin,
    sellerId: 's1',
  );
}

void main() {
  late _MockGetListingById getById;
  late _MockGetListingImages getImages;

  setUp(() {
    getById = _MockGetListingById();
    getImages = _MockGetListingImages();
    registerFallbackValue('');
  });

  ComparePageCubit buildCubit() => ComparePageCubit(
    getListingById: getById,
    getListingImages: getImages,
  );

  blocTest<ComparePageCubit, ComparePageState>(
    'resolve emits loading then ready slots',
    build: buildCubit,
    act: (cubit) async {
      when(() => getById('a')).thenAnswer(
        (_) async => Success(_listing(id: 'a')),
      );
      when(() => getById('b')).thenAnswer(
        (_) async => Success(_listing(id: 'b', vin: ListingVinStatus.formatValid)),
      );
      when(() => getImages(any())).thenAnswer(
        (_) async => Success([
          ListingImage(
            id: 'i1',
            listingId: 'a',
            publicUrl: 'https://example.com/a.jpg',
            position: 0,
            createdAt: DateTime.utc(2026, 4, 1),
          ),
        ]),
      );
      await cubit.resolve([_item('a'), _item('b')]);
    },
    expect: () => [
      ComparePageState.resolving([_item('a'), _item('b')]),
      isA<ComparePageState>()
          .having((s) => s.isResolving, 'isResolving', false)
          .having((s) => s.slots.length, 'slots', 2)
          .having(
            (s) => s.slots.every((x) => x.phase == CompareSlotPhase.ready),
            'all ready',
            true,
          ),
    ],
  );

  blocTest<ComparePageCubit, ComparePageState>(
    'failed fetch marks slot unavailable',
    build: buildCubit,
    act: (cubit) async {
      when(() => getById('gone')).thenAnswer(
        (_) async => const FailureResult(ServerFailure('missing')),
      );
      when(() => getById('ok')).thenAnswer(
        (_) async => Success(_listing(id: 'ok')),
      );
      when(() => getImages(any())).thenAnswer((_) async => const Success([]));
      await cubit.resolve([_item('gone'), _item('ok')]);
    },
    verify: (cubit) {
      expect(cubit.state.slots[0].phase, CompareSlotPhase.unavailable);
      expect(cubit.state.slots[1].phase, CompareSlotPhase.ready);
    },
  );

  blocTest<ComparePageCubit, ComparePageState>(
    'inactive listing marks slot inactive',
    build: buildCubit,
    act: (cubit) async {
      when(() => getById('sold')).thenAnswer(
        (_) async => Success(
          _listing(id: 'sold', status: ListingStatus.sold),
        ),
      );
      when(() => getById('active')).thenAnswer(
        (_) async => Success(_listing(id: 'active')),
      );
      when(() => getImages(any())).thenAnswer((_) async => const Success([]));
      await cubit.resolve([_item('sold'), _item('active')]);
    },
    verify: (cubit) {
      expect(cubit.state.slots[0].phase, CompareSlotPhase.inactive);
      expect(cubit.state.slots[1].phase, CompareSlotPhase.ready);
    },
  );

  test('resolve with fewer than two items resets to idle', () async {
    final cubit = buildCubit();
    await cubit.resolve([_item('only')]);
    expect(cubit.state, const ComparePageState.idle());
    await cubit.close();
  });

  test('stale resolve result is ignored when a newer resolve completes first', () async {
    final cubit = buildCubit();
    final slowDone = Completer<void>();
    final fastDone = Completer<void>();

    when(() => getById('slow-a')).thenAnswer((_) async {
      await slowDone.future;
      return Success(_listing(id: 'slow-a'));
    });
    when(() => getById('slow-b')).thenAnswer((_) async {
      await slowDone.future;
      return Success(_listing(id: 'slow-b'));
    });
    when(() => getById('fast-a')).thenAnswer((_) async {
      await fastDone.future;
      return Success(_listing(id: 'fast-a'));
    });
    when(() => getById('fast-b')).thenAnswer((_) async {
      await fastDone.future;
      return Success(_listing(id: 'fast-b'));
    });
    when(() => getImages(any())).thenAnswer((_) async => const Success([]));

    final slowFuture = cubit.resolve([_item('slow-a'), _item('slow-b')]);
    final fastFuture = cubit.resolve([_item('fast-a'), _item('fast-b')]);

    fastDone.complete();
    await fastFuture;
    expect(cubit.state.slots.every((s) => s.listingId == 'fast-a' || s.listingId == 'fast-b'), isTrue);
    expect(cubit.state.slots.any((s) => s.listingId.startsWith('slow')), isFalse);

    slowDone.complete();
    await slowFuture;
    expect(cubit.state.slots.any((s) => s.listingId.startsWith('slow')), isFalse);
    expect(cubit.state.slots.map((s) => s.listingId), ['fast-a', 'fast-b']);

    await cubit.close();
  });

  test('resolve does not emit after cubit is closed', () async {
    final cubit = buildCubit();
    final gate = Completer<void>();

    when(() => getById('a')).thenAnswer((_) async {
      await gate.future;
      return Success(_listing(id: 'a'));
    });
    when(() => getById('b')).thenAnswer((_) async {
      await gate.future;
      return Success(_listing(id: 'b'));
    });
    when(() => getImages(any())).thenAnswer((_) async => const Success([]));

    final resolveFuture = cubit.resolve([_item('a'), _item('b')]);
    await cubit.close();
    gate.complete();
    await resolveFuture;

    expect(cubit.isClosed, isTrue);
  });
}
