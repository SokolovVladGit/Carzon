import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/fuel_prices/domain/entities/fuel_price_snapshot.dart';
import 'package:carzon/features/fuel_prices/domain/usecases/get_fuel_prices_for_app.dart';
import 'package:carzon/features/fuel_prices/presentation/cubit/fuel_prices_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetFuelPricesForApp extends Mock implements GetFuelPricesForApp {}

void main() {
  late _MockGetFuelPricesForApp getFuelPricesForApp;

  const moldovaSnapshot = FuelPriceSnapshot(
    territory: 'moldova',
    status: 'succeeded',
    isStale: false,
    sourceLabel: 'ANRE · e-Carburanți',
    effectiveDate: '2026-06-22',
    currency: 'MDL',
    unit: 'liter',
    items: [FuelPriceItem(fuelCode: 'gasoline_95', price: 27.99)],
    limitationCodes: ['national_ceiling'],
  );

  setUp(() {
    getFuelPricesForApp = _MockGetFuelPricesForApp();
  });

  blocTest<FuelPricesCubit, FuelPricesState>(
    'load emits ready with snapshots on success',
    build: () {
      when(() => getFuelPricesForApp()).thenAnswer(
        (_) async => const Success([moldovaSnapshot]),
      );
      return FuelPricesCubit(getFuelPricesForApp: getFuelPricesForApp);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const FuelPricesState(phase: FuelPricesLoadPhase.loading),
      const FuelPricesState(
        phase: FuelPricesLoadPhase.ready,
        snapshots: [moldovaSnapshot],
      ),
    ],
  );

  blocTest<FuelPricesCubit, FuelPricesState>(
    'load emits failure when use case fails',
    build: () {
      when(() => getFuelPricesForApp()).thenAnswer(
        (_) async => const FailureResult(UnknownFailure('x')),
      );
      return FuelPricesCubit(getFuelPricesForApp: getFuelPricesForApp);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const FuelPricesState(phase: FuelPricesLoadPhase.loading),
      const FuelPricesState(phase: FuelPricesLoadPhase.failure),
    ],
  );

  test('selectTerritory updates selected territory', () {
    when(() => getFuelPricesForApp()).thenAnswer(
      (_) async => const Success([moldovaSnapshot]),
    );
    final cubit = FuelPricesCubit(getFuelPricesForApp: getFuelPricesForApp);
    cubit.selectTerritory(FuelPricesTerritory.pmr);
    expect(cubit.state.selectedTerritory, FuelPricesTerritory.pmr);
  });
}
