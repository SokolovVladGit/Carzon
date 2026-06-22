import '../../domain/entities/fuel_price_snapshot.dart';

abstract class FuelPricesRemoteDataSource {
  Future<List<FuelPriceSnapshot>> fetchFuelPricesForApp();
}
