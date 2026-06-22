import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/fuel_prices_remote_datasource.dart';
import '../data/datasources/supabase_fuel_prices_remote_datasource.dart';
import '../data/repositories/fuel_prices_repository_impl.dart';
import '../domain/repositories/fuel_prices_repository.dart';
import '../domain/usecases/get_fuel_prices_for_app.dart';

void registerFuelPricesFeature(GetIt sl) {
  sl.registerLazySingleton<FuelPricesRemoteDataSource>(
    () => SupabaseFuelPricesRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<FuelPricesRepository>(
    () => FuelPricesRepositoryImpl(sl<FuelPricesRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetFuelPricesForApp>(
    () => GetFuelPricesForApp(sl<FuelPricesRepository>()),
  );
}
