import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_refinement.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_result.dart';
import 'package:carzon/features/create_listing/domain/repositories/manual_smart_fill_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/resolve_vehicle_by_identity.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ManualSmartFillRepository {
  final calls =
      <
        ({
          String make,
          String model,
          int year,
          List<String> answers,
          List<String> skipped,
        })
      >[];
  final pending = <String, Completer<Result<ManualSmartFillResult>>>{};
  Result<ManualSmartFillResult>? next;
  final queue = <Result<ManualSmartFillResult>>[];

  @override
  Future<Result<ManualSmartFillResult>> resolveByIdentity({
    required String make,
    required String model,
    required int year,
    List<ManualSmartFillRefinementAnswer> answers = const [],
    List<ManualSmartFillRefinementKind> skippedKinds = const [],
  }) {
    calls.add((
      make: make,
      model: model,
      year: year,
      answers: [for (final a in answers) '${a.kind.wireValue}:${a.optionId}'],
      skipped: [for (final k in skippedKinds) k.wireValue],
    ));
    final key =
        '$make|$model|$year|${answers.map((a) => a.optionId).join(',')}|${skippedKinds.map((k) => k.wireValue).join(',')}';
    final completer = pending[key];
    if (completer != null) return completer.future;
    if (queue.isNotEmpty) return Future.value(queue.removeAt(0));
    return Future.value(next ?? const FailureResult(ManualSmartFillFailure()));
  }
}

ManualSmartFillNextRefinement _q({
  required ManualSmartFillRefinementKind kind,
  required List<ManualSmartFillRefinementOption> options,
}) {
  return ManualSmartFillNextRefinement(kind: kind, options: options);
}

ManualSmartFillRefinementOption _bodyOpt(String id, String body) {
  return ManualSmartFillRefinementOption(
    id: id,
    kind: ManualSmartFillRefinementKind.body,
    candidateCount: 1,
    bodyType: body,
  );
}

ManualSmartFillRefinementOption _engineOpt({
  required String id,
  String fuel = 'petrol',
  double liters = 1.0,
  int hp = 95,
}) {
  return ManualSmartFillRefinementOption(
    id: id,
    kind: ManualSmartFillRefinementKind.engine,
    candidateCount: 2,
    fuelType: fuel,
    engineDisplacementLiters: liters,
    enginePowerHp: hp,
  );
}

ManualSmartFillRefinementOption _transOpt(String id, String type) {
  return ManualSmartFillRefinementOption(
    id: id,
    kind: ManualSmartFillRefinementKind.transmission,
    candidateCount: 1,
    transmissionType: type,
  );
}

ManualSmartFillResult _ok({
  String make = 'skoda',
  String model = 'octavia',
  int year = 2018,
  String? body,
  String? fuel,
  double? liters,
  int? hp,
  String? transmission,
  ManualSmartFillClarification? clarification,
  ManualSmartFillNextRefinement? next,
}) {
  return ManualSmartFillResult(
    resolution: ManualSmartFillResolution.ok,
    identity: ManualSmartFillIdentity(
      makeKey: make,
      modelKey: model,
      year: year,
    ),
    consensus: ManualSmartFillConsensusSpecs(
      bodyType: body,
      fuelType: fuel,
      engineDisplacementLiters: liters,
      enginePowerHp: hp,
      transmissionType: transmission,
    ),
    clarification: clarification,
    nextRefinement: next,
    candidateCount: 2,
    mappingVersion: 'm1.2',
  );
}

final _bodyNext = _q(
  kind: ManualSmartFillRefinementKind.body,
  options: [_bodyOpt('body-wagon', 'wagon'), _bodyOpt('body-sedan', 'sedan')],
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
    'first V2 lookup after valid MMY',
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
      expect(repo.calls.single.answers, isEmpty);
      expect(repo.calls.single.skipped, isEmpty);
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
    repo.pending['BMW|3 Series|2020||'] = first;
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
    repo.pending['Skoda|Octavia|2018||'] = pending;
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

  test('accumulates second and third questions', () async {
    repo.next = Success(_ok(next: _bodyNext));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ManualSmartFillStatus.needsClarification);
    expect(cubit.state.showClarification, isTrue);

    repo.next = Success(
      _ok(
        body: 'wagon',
        next: _q(
          kind: ManualSmartFillRefinementKind.engine,
          options: [
            _engineOpt(id: 'eng-95'),
            _engineOpt(id: 'eng-110', hp: 110),
          ],
        ),
      ),
    );
    await cubit.selectOption(_bodyOpt('body-wagon', 'wagon'));
    expect(cubit.state.status, ManualSmartFillStatus.needsClarification);
    expect(cubit.state.answers, hasLength(1));
    expect(repo.calls.last.answers, ['body:body-wagon']);

    repo.next = Success(
      _ok(
        body: 'wagon',
        fuel: 'petrol',
        liters: 1.0,
        hp: 95,
        next: _q(
          kind: ManualSmartFillRefinementKind.transmission,
          options: [
            _transOpt('tr-man', 'manual'),
            _transOpt('tr-auto', 'automatic'),
          ],
        ),
      ),
    );
    await cubit.selectOption(_engineOpt(id: 'eng-95'));
    expect(cubit.state.answers, hasLength(2));
    expect(
      cubit.state.result?.nextRefinement?.kind,
      ManualSmartFillRefinementKind.transmission,
    );

    repo.next = Success(
      _ok(
        body: 'wagon',
        fuel: 'petrol',
        liters: 1.0,
        hp: 95,
        transmission: 'manual',
      ),
    );
    await cubit.selectOption(_transOpt('tr-man', 'manual'));
    expect(cubit.state.status, ManualSmartFillStatus.filled);
    expect(cubit.state.answers, hasLength(3));
    expect(cubit.state.showClarification, isFalse);
    expect(repo.calls, hasLength(4));
  });

  test(
    'skipped kind does not write a value and may ask the next kind',
    () async {
      repo.next = Success(
        _ok(
          next: _q(
            kind: ManualSmartFillRefinementKind.engine,
            options: [
              _engineOpt(id: 'eng-95'),
              _engineOpt(id: 'eng-110', hp: 110),
            ],
          ),
        ),
      );
      cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
      await Future<void>.delayed(Duration.zero);
      repo.next = Success(
        _ok(
          next: _q(
            kind: ManualSmartFillRefinementKind.transmission,
            options: [
              _transOpt('tr-man', 'manual'),
              _transOpt('tr-auto', 'automatic'),
            ],
          ),
        ),
      );
      await cubit.skipCurrent();
      expect(cubit.state.skippedKinds, [ManualSmartFillRefinementKind.engine]);
      expect(cubit.state.answers, isEmpty);
      expect(cubit.state.result?.consensus.enginePowerHp, isNull);
      expect(cubit.state.showClarification, isTrue);
      expect(
        cubit.state.result?.nextRefinement?.kind,
        ManualSmartFillRefinementKind.transmission,
      );
      expect(repo.calls.last.skipped, ['engine']);
    },
  );

  test('max three decisions blocks a fourth select', () async {
    repo.next = Success(_ok(next: _bodyNext));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    repo.next = Success(
      _ok(
        body: 'wagon',
        next: _q(
          kind: ManualSmartFillRefinementKind.engine,
          options: [
            _engineOpt(id: 'eng-95'),
            _engineOpt(id: 'eng-110', hp: 110),
          ],
        ),
      ),
    );
    await cubit.selectOption(_bodyOpt('body-wagon', 'wagon'));
    repo.next = Success(
      _ok(
        body: 'wagon',
        fuel: 'petrol',
        liters: 1,
        hp: 95,
        next: _q(
          kind: ManualSmartFillRefinementKind.transmission,
          options: [
            _transOpt('tr-man', 'manual'),
            _transOpt('tr-auto', 'automatic'),
          ],
        ),
      ),
    );
    await cubit.selectOption(_engineOpt(id: 'eng-95'));
    repo.next = Success(_ok(transmission: 'manual'));
    await cubit.selectOption(_transOpt('tr-man', 'manual'));
    final callsAfterThree = repo.calls.length;
    await cubit.selectOption(_transOpt('tr-auto', 'automatic'));
    expect(repo.calls, hasLength(callsAfterThree));
    expect(cubit.state.decisionsUsed, 3);
  });

  test('accepts server terminal transmission after three decisions', () async {
    repo.next = Success(_ok(next: _bodyNext));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    repo.next = Success(
      _ok(
        body: 'wagon',
        next: _q(
          kind: ManualSmartFillRefinementKind.fuel,
          options: [
            ManualSmartFillRefinementOption(
              id: 'fuel-petrol',
              kind: ManualSmartFillRefinementKind.fuel,
              candidateCount: 2,
              fuelType: 'petrol',
            ),
            ManualSmartFillRefinementOption(
              id: 'fuel-diesel',
              kind: ManualSmartFillRefinementKind.fuel,
              candidateCount: 1,
              fuelType: 'diesel',
            ),
          ],
        ),
      ),
    );
    await cubit.selectOption(_bodyOpt('body-wagon', 'wagon'));
    repo.next = Success(
      _ok(
        body: 'wagon',
        fuel: 'petrol',
        next: _q(
          kind: ManualSmartFillRefinementKind.engine,
          options: [
            _engineOpt(id: 'eng-95'),
            _engineOpt(id: 'eng-110', hp: 110),
          ],
        ),
      ),
    );
    await cubit.selectOption(
      const ManualSmartFillRefinementOption(
        id: 'fuel-petrol',
        kind: ManualSmartFillRefinementKind.fuel,
        candidateCount: 2,
        fuelType: 'petrol',
      ),
    );
    repo.next = Success(
      _ok(
        body: 'wagon',
        fuel: 'petrol',
        liters: 1,
        hp: 95,
        next: _q(
          kind: ManualSmartFillRefinementKind.transmission,
          options: [
            _transOpt('tr-man', 'manual'),
            _transOpt('tr-auto', 'automatic'),
          ],
        ),
      ),
    );
    await cubit.selectOption(_engineOpt(id: 'eng-95'));
    expect(cubit.state.decisionsUsed, 3);
    expect(cubit.state.showClarification, isTrue);
    expect(
      cubit.state.result?.nextRefinement?.kind,
      ManualSmartFillRefinementKind.transmission,
    );

    repo.next = Success(
      _ok(
        body: 'wagon',
        fuel: 'petrol',
        liters: 1,
        hp: 95,
        transmission: 'manual',
      ),
    );
    await cubit.selectOption(_transOpt('tr-man', 'manual'));
    expect(cubit.state.decisionsUsed, 4);
    expect(cubit.state.showClarification, isFalse);
    expect(cubit.state.result?.nextRefinement, isNull);
    expect(repo.calls.last.answers, contains('transmission:tr-man'));

    final callsAfterTerminal = repo.calls.length;
    await cubit.selectOption(_transOpt('tr-auto', 'automatic'));
    expect(repo.calls, hasLength(callsAfterTerminal));
    expect(cubit.state.decisionsUsed, 4);
  });

  test('terminal transmission skip ends the chain', () async {
    repo.next = Success(_ok(next: _bodyNext));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    cubit.emit(
      cubit.state.copyWith(
        answers: [
          const ManualSmartFillRefinementAnswer(
            kind: ManualSmartFillRefinementKind.body,
            optionId: 'body-wagon',
          ),
          const ManualSmartFillRefinementAnswer(
            kind: ManualSmartFillRefinementKind.fuel,
            optionId: 'fuel-petrol',
          ),
          const ManualSmartFillRefinementAnswer(
            kind: ManualSmartFillRefinementKind.engine,
            optionId: 'eng-95',
          ),
        ],
        result: _ok(
          body: 'wagon',
          fuel: 'petrol',
          liters: 1,
          hp: 95,
          next: _q(
            kind: ManualSmartFillRefinementKind.transmission,
            options: [
              _transOpt('tr-man', 'manual'),
              _transOpt('tr-auto', 'automatic'),
            ],
          ),
        ),
        status: ManualSmartFillStatus.needsClarification,
      ),
    );
    expect(cubit.state.decisionsUsed, 3);
    repo.next = Success(_ok(body: 'wagon', fuel: 'petrol', liters: 1, hp: 95));
    await cubit.skipCurrent();
    expect(cubit.state.skippedKinds, [
      ManualSmartFillRefinementKind.transmission,
    ]);
    expect(cubit.state.decisionsUsed, 4);
    expect(cubit.state.result?.consensus.transmissionType, isNull);
    expect(cubit.state.showClarification, isFalse);

    final callsAfterSkip = repo.calls.length;
    await cubit.skipCurrent();
    expect(repo.calls, hasLength(callsAfterSkip));
  });

  test('does not invent a fourth non-transmission question', () async {
    repo.next = Success(_ok(next: _bodyNext));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    cubit.emit(
      cubit.state.copyWith(
        answers: [
          const ManualSmartFillRefinementAnswer(
            kind: ManualSmartFillRefinementKind.body,
            optionId: 'body-wagon',
          ),
          const ManualSmartFillRefinementAnswer(
            kind: ManualSmartFillRefinementKind.fuel,
            optionId: 'fuel-petrol',
          ),
          const ManualSmartFillRefinementAnswer(
            kind: ManualSmartFillRefinementKind.engine,
            optionId: 'eng-95',
          ),
        ],
        result: _ok(
          next: _q(
            kind: ManualSmartFillRefinementKind.engine,
            options: [
              _engineOpt(id: 'eng-95'),
              _engineOpt(id: 'eng-110', hp: 110),
            ],
          ),
        ),
        status: ManualSmartFillStatus.needsClarification,
      ),
    );
    final calls = repo.calls.length;
    await cubit.selectOption(_engineOpt(id: 'eng-110', hp: 110));
    expect(repo.calls, hasLength(calls));
    expect(cubit.state.decisionsUsed, 3);
  });

  test('MMY change clears answers and skips', () async {
    repo.next = Success(_ok(next: _bodyNext));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    repo.next = Success(_ok(body: 'wagon', next: _bodyNext));
    await cubit.selectOption(_bodyOpt('body-wagon', 'wagon'));
    expect(cubit.state.answers, isNotEmpty);
    repo.next = Success(_ok(make: 'bmw', model: 'x5', year: 2020, body: 'suv'));
    cubit.lookup(make: 'BMW', model: 'X5', year: 2020);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.query?.model, 'X5');
    expect(cubit.state.answers, isEmpty);
    expect(cubit.state.skippedKinds, isEmpty);
    expect(repo.calls.last.answers, isEmpty);
  });

  test('VIN authority cancel drops pending lookup', () async {
    final pending = Completer<Result<ManualSmartFillResult>>();
    repo.pending['Skoda|Octavia|2018||'] = pending;
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    cubit.cancelForVinAuthority();
    pending.complete(Success(_ok(body: 'wagon')));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ManualSmartFillStatus.idle);
  });

  test(
    'manual override cancels further questions and drops stale RPC',
    () async {
      final pending = Completer<Result<ManualSmartFillResult>>();
      repo.next = Success(_ok(next: _bodyNext));
      cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
      await Future<void>.delayed(Duration.zero);
      repo.pending['Skoda|Octavia|2018|body-wagon|'] = pending;
      final select = cubit.selectOption(_bodyOpt('body-wagon', 'wagon'));
      cubit.cancelForManualOverride();
      pending.complete(Success(_ok(body: 'wagon', fuel: 'diesel')));
      await select;
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.cancelledByManualOverride, isTrue);
      expect(cubit.state.showClarification, isFalse);
      expect(cubit.state.result?.consensus.fuelType, isNull);
      cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
      expect(repo.calls.where((c) => c.answers.isEmpty), hasLength(1));
    },
  );

  test('invalidRefinement recovers once then stops', () async {
    repo.next = Success(_ok(next: _bodyNext));
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await Future<void>.delayed(Duration.zero);
    repo.queue.addAll([
      Success(
        ManualSmartFillResult(
          resolution: ManualSmartFillResolution.invalidRefinement,
          identity: const ManualSmartFillIdentity(
            makeKey: 'skoda',
            modelKey: 'octavia',
            year: 2018,
          ),
          consensus: const ManualSmartFillConsensusSpecs(),
        ),
      ),
      Success(_ok(body: 'wagon')),
    ]);
    await cubit.selectOption(_bodyOpt('tampered', 'wagon'));
    expect(cubit.state.status, ManualSmartFillStatus.filled);
    expect(cubit.state.answers, isEmpty);
    expect(repo.calls, hasLength(3));
    expect(repo.calls.last.answers, isEmpty);

    repo.next = Success(
      ManualSmartFillResult(
        resolution: ManualSmartFillResolution.invalidRefinement,
        identity: const ManualSmartFillIdentity(
          makeKey: 'skoda',
          modelKey: 'octavia',
          year: 2018,
        ),
        consensus: const ManualSmartFillConsensusSpecs(),
      ),
    );
    await cubit.selectOption(_bodyOpt('tampered-2', 'sedan'));
    expect(cubit.state.status, ManualSmartFillStatus.noData);
  });

  test('closed cubit cannot apply late response', () async {
    final pending = Completer<Result<ManualSmartFillResult>>();
    repo.pending['Skoda|Octavia|2018||'] = pending;
    cubit.lookup(make: 'Skoda', model: 'Octavia', year: 2018);
    await cubit.close();
    pending.complete(Success(_ok(body: 'wagon')));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ManualSmartFillStatus.loading);
  });
}
