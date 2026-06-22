import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/fuel_price_snapshot.dart';
import '../../domain/usecases/get_fuel_prices_for_app.dart';

enum FuelPricesTerritory { moldova, pmr }

enum FuelPricesLoadPhase { initial, loading, ready, failure }

class FuelPricesState extends Equatable {
  const FuelPricesState({
    this.phase = FuelPricesLoadPhase.initial,
    this.selectedTerritory = FuelPricesTerritory.moldova,
    this.snapshots = const [],
  });

  final FuelPricesLoadPhase phase;
  final FuelPricesTerritory selectedTerritory;
  final List<FuelPriceSnapshot> snapshots;

  FuelPriceSnapshot? snapshotFor(FuelPricesTerritory territory) {
    final key = switch (territory) {
      FuelPricesTerritory.moldova => 'moldova',
      FuelPricesTerritory.pmr => 'pmr',
    };
    for (final snapshot in snapshots) {
      if (snapshot.territory == key) return snapshot;
    }
    return null;
  }

  FuelPriceSnapshot? get selectedSnapshot => snapshotFor(selectedTerritory);

  FuelPricesState copyWith({
    FuelPricesLoadPhase? phase,
    FuelPricesTerritory? selectedTerritory,
    List<FuelPriceSnapshot>? snapshots,
  }) {
    return FuelPricesState(
      phase: phase ?? this.phase,
      selectedTerritory: selectedTerritory ?? this.selectedTerritory,
      snapshots: snapshots ?? this.snapshots,
    );
  }

  @override
  List<Object?> get props => [phase, selectedTerritory, snapshots];
}

class FuelPricesCubit extends Cubit<FuelPricesState> {
  FuelPricesCubit({required GetFuelPricesForApp getFuelPricesForApp})
    : _getFuelPricesForApp = getFuelPricesForApp,
      super(const FuelPricesState());

  final GetFuelPricesForApp _getFuelPricesForApp;

  void selectTerritory(FuelPricesTerritory territory) {
    if (state.selectedTerritory == territory) return;
    emit(state.copyWith(selectedTerritory: territory));
  }

  Future<void> load() async {
    emit(state.copyWith(phase: FuelPricesLoadPhase.loading));
    final result = await _getFuelPricesForApp();
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            phase: FuelPricesLoadPhase.ready,
            snapshots: value,
          ),
        );
      case FailureResult():
        emit(state.copyWith(phase: FuelPricesLoadPhase.failure));
    }
  }
}
