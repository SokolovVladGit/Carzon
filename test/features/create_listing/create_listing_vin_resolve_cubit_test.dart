import 'dart:async';

import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/domain/repositories/create_listing_repository.dart';
import 'package:carzon/features/create_listing/domain/repositories/vehicle_resolver_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/create_listing_v2.dart';
import 'package:carzon/features/create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import 'package:carzon/features/create_listing/domain/usecases/resolve_vehicle.dart';
import 'package:carzon/features/create_listing/domain/usecases/upload_listing_images_sequential.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateRepo extends Mock implements CreateListingRepository {}

class _MockImageRepo extends Mock implements ListingImageRepository {}

class _FakeResolver implements VehicleResolverRepository {
  final calls = <String>[];
  final pending = <String, Completer<Result<VehicleResolveResult>>>{};
  Result<VehicleResolveResult>? next;

  @override
  Future<Result<VehicleResolveResult>> resolveVehicle({required String vin}) {
    calls.add(vin);
    final completer = pending[vin];
    if (completer != null) return completer.future;
    return Future.value(
      next ??
          const FailureResult(
            VehicleResolveFailure(VehicleResolveFailureKind.internalError),
          ),
    );
  }
}

const _vinA = '1HGBH41JXMN109186';
const _vinB = '1HGCM82633A004352';
const _vinChecksumInvalid = '1HGBH41JXMN109187';
const _vinEuropean = 'WVWZZZ1JZXW000001';

VehicleResolveResult _resolved({
  String make = 'BMW',
  String model = 'X5',
  int year = 2020,
  String? trim = 'xDrive30d',
  String? series,
}) {
  return VehicleResolveResult(
    resolution: VehicleResolveResolution.resolved,
    vehicle: VehicleResolveSuggestion(
      make: make,
      model: model,
      year: year,
      trim: trim,
      series: series,
    ),
    completeness: 0.9,
    warnings: const [],
  );
}

NewListingInput _input({String make = 'ManualMake'}) => NewListingInput(
  sellerId: 's1',
  title: 'Manual title',
  make: make,
  model: 'ManualModel',
  year: 2019,
  priceEur: 10000,
  priceCurrency: ListingCurrency.eur,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  contactPhone: '+373 690 00001',
);

Listing _listing() => Listing(
  id: 'l1',
  title: 't',
  make: 'ManualMake',
  model: 'ManualModel',
  year: 2019,
  priceCurrency: ListingCurrency.eur,
  priceEur: 10000,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
  status: ListingStatus.active,
  sellerId: 's1',
);

void main() {
  late _MockCreateRepo createRepo;
  late _MockImageRepo imageRepo;
  late _FakeResolver resolver;
  late CreateListingCubit cubit;

  setUpAll(() {
    registerFallbackValue(_input());
  });

  setUp(() {
    createRepo = _MockCreateRepo();
    imageRepo = _MockImageRepo();
    resolver = _FakeResolver();
    cubit = CreateListingCubit(
      currentUserId: () => 's1',
      createListingV2: CreateListingV2(createRepo),
      uploadListingImagesSequential: UploadListingImagesSequential(imageRepo),
      deleteUploadedListingImagesBestEffort:
          DeleteUploadedListingImagesBestEffort(imageRepo),
      resolveVehicle: ResolveVehicle(resolver),
      resolveDebounce: Duration.zero,
    );
  });

  tearDown(() => cubit.close());

  Future<void> flushDebounce() => Future<void>.delayed(Duration.zero);

  test('applicable bad checksum does not invoke resolver', () async {
    cubit.onVinChanged(_vinChecksumInvalid);
    await flushDebounce();
    expect(resolver.calls, isEmpty);
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.likelyInputError,
    );
    expect(cubit.state.vehicleResolve.suggestion, isNull);
  });

  test('corrected checksum VIN proceeds to resolver', () async {
    resolver.next = Success(_resolved());
    cubit.onVinChanged(_vinChecksumInvalid);
    await flushDebounce();
    expect(resolver.calls, isEmpty);
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(resolver.calls, [_vinA]);
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.resolved,
    );
  });

  test('non-applicable European VIN still invokes resolver', () async {
    resolver.next = Success(_resolved(make: 'Volkswagen', model: 'Golf'));
    cubit.onVinChanged(_vinEuropean);
    await flushDebounce();
    await flushDebounce();
    expect(resolver.calls, [_vinEuropean]);
  });

  test('VIN change clears stale partial result', () async {
    resolver.next = const Success(
      VehicleResolveResult(
        resolution: VehicleResolveResolution.partial,
        vehicle: VehicleResolveSuggestion(make: 'Ford'),
        completeness: 0.2,
        warnings: [],
      ),
    );
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.partial,
    );
    cubit.onVinChanged(_vinB);
    expect(cubit.state.vehicleResolve.suggestion, isNull);
    expect(cubit.state.vehicleResolve.confirmed, isFalse);
  });

  test('invalid VIN does not invoke resolver', () async {
    cubit.onVinChanged('SHORT');
    await flushDebounce();
    expect(resolver.calls, isEmpty);
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.idle,
    );
  });

  test('valid VIN invokes resolver', () async {
    resolver.next = Success(_resolved());
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(resolver.calls, [_vinA]);
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.resolved,
    );
    expect(cubit.state.vehicleResolve.confirmed, isFalse);
    expect(cubit.state.vehicleResolve.confirmedIdentity, isNull);
  });

  test('duplicate unchanged VIN does not re-invoke', () async {
    resolver.next = Success(_resolved());
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(resolver.calls, [_vinA]);
  });

  test('VIN change invalidates unconfirmed suggestion', () async {
    resolver.next = Success(_resolved());
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(cubit.state.vehicleResolve.suggestion, isNotNull);

    cubit.onVinChanged('ABC');
    expect(cubit.state.vehicleResolve.suggestion, isNull);
    expect(cubit.state.vehicleResolve.confirmed, isFalse);
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.idle,
    );
  });

  test('stale response cannot overwrite newer VIN state', () async {
    resolver.pending[_vinA] = Completer<Result<VehicleResolveResult>>();
    resolver.pending[_vinB] = Completer<Result<VehicleResolveResult>>();

    cubit.onVinChanged(_vinA);
    await flushDebounce();
    cubit.onVinChanged(_vinB);
    await flushDebounce();

    resolver.pending[_vinA]!.complete(Success(_resolved(make: 'Honda')));
    await flushDebounce();
    expect(cubit.state.vehicleResolve.normalizedVin, _vinB);
    expect(cubit.state.vehicleResolve.suggestion, isNull);

    resolver.pending[_vinB]!.complete(
      Success(_resolved(make: 'BMW', model: 'X5')),
    );
    await flushDebounce();
    expect(cubit.state.vehicleResolve.suggestion?.vehicle.make, 'BMW');
  });

  test('resolved suggestion is not submitted before confirm', () async {
    resolver.next = Success(_resolved());
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(cubit.state.vehicleResolve.confirmed, isFalse);
    expect(cubit.state.vehicleResolve.confirmedIdentity, isNull);

    when(() => createRepo.createV2(any())).thenAnswer((_) async {
      return Success(_listing());
    });
    await cubit.submit(listingInput: _input(), orderedPhotos: const []);
    final captured =
        verify(() => createRepo.createV2(captureAny())).captured.single
            as NewListingInput;
    expect(captured.make, 'ManualMake');
    expect(captured.model, 'ManualModel');
    expect(captured.year, 2019);
    expect(captured.bodyType, isNull);
    expect(captured.fuelType, isNull);
    expect(captured.drivetrain, isNull);
    expect(captured.transmissionType, isNull);
  });

  test('confirm populates make/model/year and prefers trim', () async {
    resolver.next = Success(_resolved(trim: 'xDrive30d', series: 'X5 xDrive'));
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    cubit.confirmSuggestion();

    final identity = cubit.state.vehicleResolve.confirmedIdentity!;
    expect(identity.make, 'BMW');
    expect(identity.model, 'X5');
    expect(identity.year, 2020);
    expect(identity.variant, 'xDrive30d');
    expect(cubit.state.vehicleResolve.confirmed, isTrue);
  });

  test('series is used if trim is absent', () async {
    resolver.next = Success(_resolved(trim: null, series: '330i'));
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    cubit.confirmSuggestion();
    expect(cubit.state.vehicleResolve.confirmedIdentity!.variant, '330i');
  });

  test('partial result does not confirm identity', () async {
    resolver.next = const Success(
      VehicleResolveResult(
        resolution: VehicleResolveResolution.partial,
        vehicle: VehicleResolveSuggestion(make: 'Honda', year: 2003),
        completeness: 0.3,
        warnings: [],
      ),
    );
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.partial,
    );
    cubit.confirmSuggestion();
    expect(cubit.state.vehicleResolve.confirmed, isFalse);
    expect(cubit.state.vehicleResolve.confirmedIdentity, isNull);
  });

  test('no_data falls back cleanly', () async {
    resolver.next = const Success(
      VehicleResolveResult(
        resolution: VehicleResolveResolution.noData,
        vehicle: VehicleResolveSuggestion(),
        completeness: 0,
        warnings: [],
      ),
    );
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.noData,
    );
    expect(cubit.state.vehicleResolve.confirmed, isFalse);
  });

  test('manual mode works after resolver failure', () async {
    resolver.next = const FailureResult(
      VehicleResolveFailure(VehicleResolveFailureKind.upstreamUnavailable),
    );
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.failure,
    );
    cubit.enterManualMode();
    expect(
      cubit.state.vehicleResolve.status,
      CreateListingVinResolveStatus.manual,
    );
    expect(cubit.state.vehicleResolve.suggestion, isNull);
    expect(cubit.state.vehicleResolve.normalizedVin, _vinA);
  });

  test('resolver failure does not block manual submit', () async {
    resolver.next = const FailureResult(
      VehicleResolveFailure(VehicleResolveFailureKind.upstreamTimeout),
    );
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    cubit.enterManualMode();

    when(() => createRepo.createV2(any())).thenAnswer((_) async {
      return Success(_listing());
    });
    await cubit.submit(listingInput: _input(), orderedPhotos: const []);
    expect(cubit.state.status, CreateListingStatus.success);
    final captured =
        verify(() => createRepo.createV2(captureAny())).captured.single
            as NewListingInput;
    expect(captured.make, 'ManualMake');
  });

  test('changing VIN invalidates adopted identity authority', () async {
    resolver.next = Success(_resolved());
    cubit.onVinChanged(_vinA);
    await flushDebounce();
    await flushDebounce();
    cubit.confirmSuggestion();
    expect(cubit.state.vehicleResolve.confirmedIdentity, isNotNull);

    cubit.onVinChanged(_vinB);
    expect(cubit.state.vehicleResolve.confirmed, isFalse);
    expect(cubit.state.vehicleResolve.confirmedIdentity, isNull);
    expect(cubit.state.vehicleResolve.applyRevision, 1);
  });
}
