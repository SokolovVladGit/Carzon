import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/listings_remote_datasource.dart';
import '../data/repositories/listings_repository_impl.dart';
import '../domain/repositories/listings_repository.dart';
import '../domain/usecases/delete_listing.dart';
import '../domain/usecases/get_listing_by_id.dart';
import '../domain/usecases/get_listings.dart';
import '../domain/usecases/set_listing_status.dart';
import '../presentation/bloc/listing_details_cubit.dart';
import '../presentation/bloc/listings_bloc.dart';

void registerListingsFeature(GetIt sl) {
  sl.registerLazySingleton<ListingsRemoteDataSource>(
    () => SupabaseListingsRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<ListingsRepository>(
    () => ListingsRepositoryImpl(sl<ListingsRemoteDataSource>()),
  );
  sl.registerFactory(() => GetListings(sl<ListingsRepository>()));
  sl.registerFactory(() => GetListingById(sl<ListingsRepository>()));
  sl.registerFactory(() => SetListingStatus(sl<ListingsRepository>()));
  sl.registerFactory(() => DeleteListing(sl<ListingsRepository>()));
  sl.registerFactory<ListingsBloc>(
    () => ListingsBloc(getListings: sl<GetListings>()),
  );
  sl.registerFactory<ListingDetailsCubit>(
    () => ListingDetailsCubit(getListingById: sl<GetListingById>()),
  );
}
