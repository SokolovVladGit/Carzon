import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/create_listing_image_remote_datasource.dart';
import '../data/datasources/create_listing_remote_datasource.dart';
import '../data/repositories/create_listing_repository_impl.dart';
import '../data/repositories/listing_image_repository_impl.dart';
import '../domain/repositories/create_listing_repository.dart';
import '../domain/usecases/create_listing.dart';
import '../domain/usecases/upload_listing_cover_image.dart';
import '../presentation/bloc/create_listing_cubit.dart';

void registerCreateListingFeature(GetIt sl) {
  sl.registerLazySingleton<CreateListingRemoteDataSource>(
    () => SupabaseCreateListingRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<CreateListingImageRemoteDataSource>(
    () => SupabaseCreateListingImageRemoteDataSource(sl<SupabaseService>()),
  );

  sl.registerLazySingleton<CreateListingRepository>(
    () => CreateListingRepositoryImpl(sl<CreateListingRemoteDataSource>()),
  );
  sl.registerLazySingleton<ListingImageRepository>(
    () => ListingImageRepositoryImpl(sl<CreateListingImageRemoteDataSource>()),
  );

  sl.registerFactory(() => CreateListing(sl<CreateListingRepository>()));
  sl.registerFactory(
    () => UploadListingCoverImage(sl<ListingImageRepository>()),
  );

  sl.registerFactory<CreateListingCubit>(
    () => CreateListingCubit(
      createListing: sl<CreateListing>(),
      uploadListingCoverImage: sl<UploadListingCoverImage>(),
    ),
  );
}
