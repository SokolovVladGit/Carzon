import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/manual_smart_fill_refinement.dart';
import '../../domain/entities/manual_smart_fill_result.dart';
import '../../domain/usecases/resolve_vehicle_by_identity.dart';
import 'manual_smart_fill_state.dart';

class ManualSmartFillCubit extends Cubit<ManualSmartFillState> {
  ManualSmartFillCubit({required ResolveVehicleByIdentity resolveByIdentity})
    : _resolveByIdentity = resolveByIdentity,
      super(const ManualSmartFillState.idle());

  final ResolveVehicleByIdentity _resolveByIdentity;
  int _generation = 0;
  ManualSmartFillQuery? _inFlight;
  ManualSmartFillQuery? _lastCompleted;
  bool _invalidRecoveryUsed = false;

  void lookup({
    required String make,
    required String model,
    required int year,
  }) {
    final query = _normalizeQuery(make: make, model: model, year: year);
    if (query == null) {
      reset();
      return;
    }
    if (state.query != null && state.query != query) {
      _clearClientRefinement();
    }
    if (state.cancelledByManualOverride && state.query == query) {
      return;
    }
    if (_inFlight == query && state.status == ManualSmartFillStatus.loading) {
      return;
    }
    if (_lastCompleted == query &&
        state.answers.isEmpty &&
        state.skippedKinds.isEmpty &&
        !state.cancelledByManualOverride &&
        state.status != ManualSmartFillStatus.idle &&
        state.status != ManualSmartFillStatus.loading &&
        state.status != ManualSmartFillStatus.failure) {
      return;
    }
    unawaited(_run(query: query));
  }

  Future<void> selectOption(ManualSmartFillRefinementOption option) {
    return _select(
      ManualSmartFillRefinementAnswer(kind: option.kind, optionId: option.id),
    );
  }

  Future<void> answer({
    required String attribute,
    required String value,
  }) async {
    final kind = parseManualSmartFillRefinementKind(attribute);
    final trimmedValue = value.trim();
    if (kind == null || trimmedValue.isEmpty) return;
    final option = _findCurrentOption(kind: kind, value: trimmedValue);
    if (option != null) {
      await selectOption(option);
      return;
    }
    await _select(
      ManualSmartFillRefinementAnswer(kind: kind, optionId: trimmedValue),
    );
  }

  Future<void> skipCurrent() async {
    final query = state.query;
    if (query == null || state.cancelledByManualOverride) return;
    final kind =
        state.result?.nextRefinement?.kind ??
        parseManualSmartFillRefinementKind(
          state.result?.clarification?.attribute,
        );
    if (kind == null) return;
    if (state.answers.any((a) => a.kind == kind) ||
        state.skippedKinds.contains(kind)) {
      return;
    }
    if (!_allowsDecision(kind)) return;
    await _run(
      query: query,
      answers: [...state.answers],
      skippedKinds: [...state.skippedKinds, kind],
    );
  }

  void dismissClarification() {
    unawaited(skipCurrent());
  }

  Future<void> restart() async {
    final query = state.query;
    if (query == null || state.cancelledByManualOverride) return;
    _invalidRecoveryUsed = false;
    _lastCompleted = null;
    await _run(query: query, answers: const [], skippedKinds: const []);
  }

  void reset() {
    _generation += 1;
    _inFlight = null;
    _lastCompleted = null;
    _invalidRecoveryUsed = false;
    emit(const ManualSmartFillState.idle());
  }

  void cancelForVinAuthority() => reset();

  void cancelForManualOverride() {
    if (state.status == ManualSmartFillStatus.idle) return;
    _generation += 1;
    _inFlight = null;
    emit(
      state.copyWith(
        status: ManualSmartFillStatus.filled,
        cancelledByManualOverride: true,
        clarificationDismissed: true,
      ),
    );
  }

  Future<void> retry() async {
    final query = state.query;
    if (query == null || state.cancelledByManualOverride) return;
    _lastCompleted = null;
    await _run(
      query: query,
      answers: state.answers,
      skippedKinds: state.skippedKinds,
      force: true,
    );
  }

  Future<void> _select(ManualSmartFillRefinementAnswer answer) async {
    final query = state.query;
    if (query == null || state.cancelledByManualOverride) return;
    if (state.answers.any((a) => a.kind == answer.kind) ||
        state.skippedKinds.contains(answer.kind)) {
      return;
    }
    if (!_allowsDecision(answer.kind)) return;
    if (answer.optionId.trim().isEmpty) return;
    await _run(
      query: query,
      answers: [...state.answers, answer],
      skippedKinds: state.skippedKinds,
    );
  }

  Future<void> _run({
    required ManualSmartFillQuery query,
    List<ManualSmartFillRefinementAnswer>? answers,
    List<ManualSmartFillRefinementKind>? skippedKinds,
    bool force = false,
  }) async {
    final nextAnswers = answers ?? state.answers;
    final nextSkipped = skippedKinds ?? state.skippedKinds;
    if (!force &&
        nextAnswers.isEmpty &&
        nextSkipped.isEmpty &&
        _lastCompleted == query &&
        state.status != ManualSmartFillStatus.idle &&
        state.status != ManualSmartFillStatus.loading &&
        state.status != ManualSmartFillStatus.failure &&
        !state.cancelledByManualOverride) {
      return;
    }

    final generation = ++_generation;
    _inFlight = query;
    emit(
      state.copyWith(
        status: ManualSmartFillStatus.loading,
        query: query,
        answers: nextAnswers,
        skippedKinds: nextSkipped,
        cancelledByManualOverride: false,
        answered: nextAnswers.isNotEmpty || nextSkipped.isNotEmpty,
      ),
    );

    final result = await _resolveByIdentity(
      make: query.make,
      model: query.model,
      year: query.year,
      answers: nextAnswers,
      skippedKinds: nextSkipped,
    );
    if (isClosed) return;
    if (generation != _generation || state.query != query) {
      if (_inFlight == query) _inFlight = null;
      return;
    }
    _inFlight = null;
    _lastCompleted = query;

    switch (result) {
      case FailureResult():
        emit(
          state.copyWith(status: ManualSmartFillStatus.failure, query: query),
        );
      case Success(:final value):
        if (value.resolution == ManualSmartFillResolution.invalidRefinement) {
          await _recoverInvalid(query: query, generation: generation);
          return;
        }
        _invalidRecoveryUsed = false;
        _emitResolved(query: query, value: value);
    }
  }

  Future<void> _recoverInvalid({
    required ManualSmartFillQuery query,
    required int generation,
  }) async {
    if (_invalidRecoveryUsed) {
      emit(
        state.copyWith(
          status: ManualSmartFillStatus.noData,
          query: query,
          answers: const [],
          skippedKinds: const [],
          applyRevision: state.applyRevision + 1,
          clarificationDismissed: true,
        ),
      );
      return;
    }
    _invalidRecoveryUsed = true;
    _lastCompleted = null;
    if (generation != _generation) return;
    await _run(
      query: query,
      answers: const [],
      skippedKinds: const [],
      force: true,
    );
  }

  void _emitResolved({
    required ManualSmartFillQuery query,
    required ManualSmartFillResult value,
  }) {
    if (value.resolution == ManualSmartFillResolution.noData) {
      emit(
        state.copyWith(
          status: ManualSmartFillStatus.noData,
          query: query,
          result: value,
          applyRevision: state.applyRevision + 1,
          clarificationDismissed: true,
        ),
      );
      return;
    }

    final needsQuestion =
        !state.cancelledByManualOverride && value.hasSupportedClarification;
    emit(
      state.copyWith(
        status: needsQuestion
            ? ManualSmartFillStatus.needsClarification
            : ManualSmartFillStatus.filled,
        query: query,
        result: value,
        applyRevision: state.applyRevision + 1,
        answered: state.decisionsUsed > 0,
        clarificationDismissed: !needsQuestion,
      ),
    );
  }

  bool _allowsDecision(ManualSmartFillRefinementKind kind) {
    if (state.decisionsUsed >= 4) return false;
    if (state.decisionsUsed < 3) return true;
    final next = state.result?.nextRefinement;
    return next?.kind == ManualSmartFillRefinementKind.transmission &&
        kind == ManualSmartFillRefinementKind.transmission;
  }

  ManualSmartFillRefinementOption? _findCurrentOption({
    required ManualSmartFillRefinementKind kind,
    required String value,
  }) {
    final next = state.result?.nextRefinement;
    if (next != null && next.kind == kind) {
      for (final option in next.options) {
        if (option.id == value || option.canonicalValue == value) {
          return option;
        }
      }
    }
    return null;
  }

  void _clearClientRefinement() {
    _lastCompleted = null;
    _invalidRecoveryUsed = false;
    emit(
      state.copyWith(
        answers: const [],
        skippedKinds: const [],
        cancelledByManualOverride: false,
        answered: false,
        clarificationDismissed: false,
        clearResult: true,
      ),
    );
  }

  ManualSmartFillQuery? _normalizeQuery({
    required String make,
    required String model,
    required int year,
  }) {
    final trimmedMake = make.trim();
    final trimmedModel = model.trim();
    if (trimmedMake.isEmpty || trimmedModel.isEmpty) return null;
    if (year < 1900 || year > 2100) return null;
    return ManualSmartFillQuery(
      make: trimmedMake,
      model: trimmedModel,
      year: year,
    );
  }

  @override
  Future<void> close() {
    _generation += 1;
    _inFlight = null;
    return super.close();
  }
}
