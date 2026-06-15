import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/model_data_remote_datasource.dart';
import '../data/datasources/supabase_model_data_remote_datasource.dart';
import '../data/repositories/model_data_repository_impl.dart';
import '../domain/repositories/model_data_repository.dart';
import '../domain/usecases/get_listing_model_data_for_buyer.dart';

void registerVehicleModelDataFeature(GetIt sl) {
  sl.registerLazySingleton<ModelDataRemoteDataSource>(
    () => SupabaseModelDataRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<ModelDataRepository>(
    () => ModelDataRepositoryImpl(sl<ModelDataRemoteDataSource>()),
  );
  sl.registerFactory(
    () => GetListingModelDataForBuyer(sl<ModelDataRepository>()),
  );
}
