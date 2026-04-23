import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/create_listing_remote_datasource.dart';
import '../data/repositories/create_listing_repository_impl.dart';
import '../domain/repositories/create_listing_repository.dart';
import '../domain/usecases/create_listing.dart';
import '../presentation/bloc/create_listing_cubit.dart';

void registerCreateListingFeature(GetIt sl) {
  sl.registerLazySingleton<CreateListingRemoteDataSource>(
    () => SupabaseCreateListingRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<CreateListingRepository>(
    () => CreateListingRepositoryImpl(sl<CreateListingRemoteDataSource>()),
  );
  sl.registerFactory(() => CreateListing(sl<CreateListingRepository>()));
  sl.registerFactory<CreateListingCubit>(
    () => CreateListingCubit(createListing: sl<CreateListing>()),
  );
}
