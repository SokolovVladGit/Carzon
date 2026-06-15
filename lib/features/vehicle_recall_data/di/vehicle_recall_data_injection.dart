import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/recall_data_remote_data_source.dart';
import '../data/datasources/supabase_recall_data_remote_data_source.dart';
import '../data/repositories/recall_data_repository_impl.dart';
import '../domain/repositories/recall_data_repository.dart';
import '../domain/usecases/get_listing_recalls_for_buyer.dart';

void registerVehicleRecallDataFeature(GetIt sl) {
  sl.registerLazySingleton<RecallDataRemoteDataSource>(
    () => SupabaseRecallDataRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<RecallDataRepository>(
    () => RecallDataRepositoryImpl(sl<RecallDataRemoteDataSource>()),
  );
  sl.registerFactory(
    () => GetListingRecallsForBuyer(sl<RecallDataRepository>()),
  );
}
