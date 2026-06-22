import '../../../../core/utils/result.dart';
import '../entities/fuel_price_snapshot.dart';
import '../repositories/fuel_prices_repository.dart';

class GetFuelPricesForApp {
  const GetFuelPricesForApp(this._repository);

  final FuelPricesRepository _repository;

  Future<Result<List<FuelPriceSnapshot>>> call() =>
      _repository.fetchFuelPricesForApp();
}
