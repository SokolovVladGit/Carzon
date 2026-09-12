import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_result.dart';
import 'package:carzon/features/create_listing/domain/repositories/manual_smart_fill_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/resolve_vehicle_by_identity.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ManualSmartFillRepository {
  final calls = <({String make, String model, int year, String? answer})>[];
  final pending = <String, Completer<Result<ManualSmartFillResult>>>{};
  Result<ManualSmartFillResult>? next;

  @override
  Future<Result<ManualSmartFillResult>> resolveByIdentity({
    required String make,
    required String model,
    required int year,
    ManualSmartFillAnswer? answer,
  }) {
    calls.add((
      make: make,
      model: model,
      year: year,
      answer: answer == null ? null : '${answer.attribute}:${answer.value}',
    ));
    final key = '$make|$model|$year|${answer?.value ?? ''}';
    final completer = pending[key];
    if (completer != null) return completer.future;
    return Future.value(next ?? const FailureResult(ManualSmartFillFailure()));
  }
}

ManualSmartFillResult _ok({
  String make = 'skoda',
  String model = 'octavia',
  int year = 2018,
  String? body,
  String? fuel,
  ManualSmartFillClarification? clarification,
}) {
  return ManualSmartFillResult(
    resolution: ManualSmartFillResolution.ok,
    identity: ManualSmartFillIdentity(
      makeKey: make,
      modelKey: model,
      year: year,
    ),
    consensus: ManualSmartFillConsensusSpecs(bodyType: body, fuelType: fuel),
    clarification: clarification,
    candidateCount: 2,
    mappingVersion: 'm1.0',
  );
}

ManualSmartFillClarification get _bodyQ => const ManualSmartFillClarification(
  attribute: 'body',
  options: [
    ManualSmartFillClarificationOption(value: 'wagon', candidateCount: 2),
    ManualSmartFillClarificationOption(value: 'sedan', candidateCount: 1),
  ],
);

void main() {
  late _FakeRepo repo;
  late ManualSmartFillCubit cubit;

  setUp(() {
    repo = _FakeRepo();
    cubit = ManualSmartFillCubit(
      resolveByIdentity: ResolveVehicleByIdentity(repo),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('no call before complete MMY', () {
    cubit.lookup(make: 'Skoda', model: '', year: 2018);
    cubit.lookup(make: '', model: 'Octavia', year: 2018);
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 1800);
    expect(repo.calls, isEmpty);
    expect(cubit.state.status, ManualSmartFillStatus.idle);
  });

  blocTest<ManualSmartFillCubit, ManualSmartFillState>(
    'calls after valid MMY',
    build: () {
      repo.next = Success(_ok());
      return cubit;
    },
    act: (c) => c.lookup(make: 'Skoda', model: 'Octavia', year: 2018),
    expect: () => [
      isA<ManualSmartFillState>().having(
        (s) => s.status,
        'status',
        ManualSmartFillStatus.loading,
      ),
      isA<ManualSmartFillState>().having(
        (s) => s.status,
        'status',
        ManualSmartFillStatus.filled,
      ),
    ],
    verify: (_) {
      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.make, 'Skoda');
    },
  );

  test('duplicate same MMY is suppressed', () async {
    repo.next = Success(_ok());
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, hasLength(1));
  });

  test('stale response is dropped', () async {
    final first = Completer<Result<ManualSmartFillResult>>();
    repo.pending['BMW|3 Series|2020|'] = first;
    cubit.lookup(make: 'BMW', model: '3 Series', year: 2020);
    repo.next = Success(_ok(make: 'bmw', model: 'x5', year: 2020, body: 'suv'));
    cubit.lookup(make: 'BMW', model: 'X5', year: 2020);
    await Future<void>.delayed(Duration.zero);
    first.complete(Success(_ok(make: 'bmw', model: '3 series', year: 2020)));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.query?.model, 'X5');
    expect(cubit.state.result?.identity.modelKey, 'x5');
  });

  test('reset invalidates in-flight response', () async {
    final pending = Completer<Result<ManualSmartFillResult>>();
    repo.pending['Skoda|Octavia|2018|'] = pending;
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    cubit.reset();
    pending.complete(Success(_ok(body: 'wagon')));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ManualSmartFillStatus.idle);
    expect(cubit.state.result, isNull);
  });

  blocTest<ManualSmartFillCubit, ManualSmartFillState>(
    'noData',
    build: () {
      repo.next = Success(
        ManualSmartFillResult(
          resolution: ManualSmartFillResolution.noData,
          identity: const ManualSmartFillIdentity(
            makeKey: 'chery',
            modelKey: 'tiggo 7',
            year: 2019,
          ),
          consensus: const ManualSmartFillConsensusSpecs(),
        ),
      );
      return cubit;
    },
    act: (c) => c.lookup(make: 'Chery', model: 'Tiggo 7', year: 2019),
    expect: () => [
      isA<ManualSmartFillState>().having(
        (s) => s.status,
        'loading',
        ManualSmartFillStatus.loading,
      ),
      isA<ManualSmartFillState>().having(
        (s) => s.status,
        'noData',
        ManualSmartFillStatus.noData,
      ),
    ],
  );

  blocTest<ManualSmartFillCubit, ManualSmartFillState>(
    'failure',
    build: () {
      repo.next = const FailureResult(ManualSmartFillFailure());
      return cubit;
    },
    act: (c) => c.lookup(make: 'Skoda', model: 'Octavia', year: 2018),
    expect: () => [
      isA<ManualSmartFillState>().having(
        (s) => s.status,
        'loading',
        ManualSmartFillStatus.loading,
      ),
      isA<ManualSmartFillState>().having(
        (s) => s.status,
        'failure',
        ManualSmartFillStatus.failure,
      ),
    ],
  );

  test('needsClarification then valid answer hides second question', () async {
    repo.next = Success(_ok(clarification: _bodyQ));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ManualSmartFillStatus.needsClarification);
    expect(cubit.state.showClarification, isTrue);

    repo.next = Success(_ok(body: 'wagon'));
    await cubit.answer(attribute: 'body', value: 'wagon');
    expect(cubit.state.status, ManualSmartFillStatus.filled);
    expect(cubit.state.showClarification, isFalse);
    expect(cubit.state.answered, isTrue);
    expect(repo.calls, hasLength(2));
    expect(repo.calls.last.answer, 'body:wagon');
  });

  test('noData answer keeps previous consensus and hides question', () async {
    repo.next = Success(_ok(clarification: _bodyQ));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    repo.next = Success(
      ManualSmartFillResult(
        resolution: ManualSmartFillResolution.noData,
        identity: const ManualSmartFillIdentity(
          makeKey: 'skoda',
          modelKey: 'octavia',
          year: 2018,
        ),
        consensus: const ManualSmartFillConsensusSpecs(),
      ),
    );
    await cubit.answer(attribute: 'body', value: 'spaceship');
    expect(cubit.state.status, ManualSmartFillStatus.filled);
    expect(cubit.state.result?.hasSupportedClarification, isTrue);
    expect(cubit.state.showClarification, isFalse);
  });

  test('transmission clarification is supported', () async {
    repo.next = Success(
      _ok(
        clarification: const ManualSmartFillClarification(
          attribute: 'transmission',
          options: [
            ManualSmartFillClarificationOption(value: 'manual'),
            ManualSmartFillClarificationOption(value: 'automatic'),
          ],
        ),
      ),
    );
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ManualSmartFillStatus.needsClarification);
    expect(cubit.state.showClarification, isTrue);
    repo.next = Success(
      ManualSmartFillResult(
        resolution: ManualSmartFillResolution.ok,
        identity: const ManualSmartFillIdentity(
          makeKey: 'skoda',
          modelKey: 'octavia',
          year: 2018,
        ),
        consensus: const ManualSmartFillConsensusSpecs(
          bodyType: 'wagon',
          fuelType: 'petrol',
          transmissionType: 'manual',
        ),
      ),
    );
    await cubit.answer(attribute: 'transmission', value: 'manual');
    expect(cubit.state.status, ManualSmartFillStatus.filled);
    expect(cubit.state.showClarification, isFalse);
    expect(repo.calls.last.answer, 'transmission:manual');
  });

  test('dismissClarification does not call RPC', () async {
    repo.next = Success(_ok(clarification: _bodyQ));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    cubit.dismissClarification();
    expect(cubit.state.status, ManualSmartFillStatus.filled);
    expect(cubit.state.showClarification, isFalse);
    expect(repo.calls, hasLength(1));
  });

  test('VIN authority cancel drops pending lookup', () async {
    final pending = Completer<Result<ManualSmartFillResult>>();
    repo.pending['Skoda|Octavia|2018|'] = pending;
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    cubit.cancelForVinAuthority();
    pending.complete(Success(_ok(body: 'wagon')));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ManualSmartFillStatus.idle);
  });

  test('closed cubit cannot apply late response', () async {
    final pending = Completer<Result<ManualSmartFillResult>>();
    repo.pending['Skoda|Octavia|2018|'] = pending;
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await cubit.close();
    pending.complete(Success(_ok(body: 'wagon')));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ManualSmartFillStatus.loading);
  });
}
