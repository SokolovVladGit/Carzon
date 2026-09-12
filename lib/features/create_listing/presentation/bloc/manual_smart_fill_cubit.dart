import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
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
    if (_inFlight == query && state.status == ManualSmartFillStatus.loading) {
      return;
    }
    if (_lastCompleted == query &&
        state.status != ManualSmartFillStatus.idle &&
        state.status != ManualSmartFillStatus.loading) {
      return;
    }
    unawaited(_run(query: query));
  }

  Future<void> answer({
    required String attribute,
    required String value,
  }) async {
    final query = state.query;
    if (query == null) return;
    if (state.answered || !state.showClarification) return;
    final trimmedAttr = attribute.trim();
    final trimmedValue = value.trim();
    if (trimmedAttr.isEmpty || trimmedValue.isEmpty) return;
    await _run(
      query: query,
      answer: ManualSmartFillAnswer(
        attribute: trimmedAttr,
        value: trimmedValue,
      ),
    );
  }

  void dismissClarification() {
    if (!state.showClarification) return;
    emit(
      state.copyWith(
        status: ManualSmartFillStatus.filled,
        clarificationDismissed: true,
      ),
    );
  }

  void reset() {
    _generation += 1;
    _inFlight = null;
    _lastCompleted = null;
    emit(const ManualSmartFillState.idle());
  }

  void cancelForVinAuthority() => reset();

  Future<void> retry() async {
    final query = state.query;
    if (query == null) return;
    _lastCompleted = null;
    await _run(query: query, force: true);
  }

  Future<void> _run({
    required ManualSmartFillQuery query,
    ManualSmartFillAnswer? answer,
    bool force = false,
  }) async {
    if (!force &&
        answer == null &&
        _lastCompleted == query &&
        state.status != ManualSmartFillStatus.idle &&
        state.status != ManualSmartFillStatus.loading &&
        state.status != ManualSmartFillStatus.failure) {
      return;
    }

    final generation = ++_generation;
    _inFlight = query;
    emit(
      state.copyWith(
        status: ManualSmartFillStatus.loading,
        query: query,
        answered: answer != null ? true : state.answered,
      ),
    );

    final result = await _resolveByIdentity(
      make: query.make,
      model: query.model,
      year: query.year,
      answer: answer,
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
        _emitResolved(query: query, value: value, fromAnswer: answer != null);
    }
  }

  void _emitResolved({
    required ManualSmartFillQuery query,
    required ManualSmartFillResult value,
    required bool fromAnswer,
  }) {
    if (value.resolution == ManualSmartFillResolution.noData) {
      if (fromAnswer && state.result != null) {
        emit(
          state.copyWith(
            status: ManualSmartFillStatus.filled,
            query: query,
            answered: true,
            clarificationDismissed: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: ManualSmartFillStatus.noData,
          query: query,
          result: value,
          applyRevision: state.applyRevision + 1,
          answered: fromAnswer || state.answered,
          clarificationDismissed: true,
        ),
      );
      return;
    }

    final hideClarification =
        fromAnswer || state.answered || state.clarificationDismissed;
    final needsQuestion = !hideClarification && value.hasSupportedClarification;
    emit(
      state.copyWith(
        status: needsQuestion
            ? ManualSmartFillStatus.needsClarification
            : ManualSmartFillStatus.filled,
        query: query,
        result: value,
        applyRevision: state.applyRevision + 1,
        answered: hideClarification ? true : state.answered,
        clarificationDismissed: hideClarification,
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
