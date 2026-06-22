import '../../../../core/utils/result.dart';
import '../entities/fuel_price_snapshot.dart';

abstract class FuelPricesRepository {
  Future<Result<List<FuelPriceSnapshot>>> fetchFuelPricesForApp();
}
