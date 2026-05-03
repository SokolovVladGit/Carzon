import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../create_listing/domain/repositories/create_listing_repository.dart';
import '../../create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import '../../create_listing/domain/usecases/upload_listing_images_sequential.dart';
import '../../listings/domain/usecases/get_listing_by_id.dart';
import '../../listings/domain/usecases/get_listing_images.dart';
import '../data/datasources/edit_listing_remote_datasource.dart';
import '../data/repositories/edit_listing_repository_impl.dart';
import '../domain/repositories/edit_listing_repository.dart';
import '../domain/usecases/replace_listing_images.dart';
import '../domain/usecases/update_listing_details_v2.dart';
import '../presentation/bloc/edit_listing_cubit.dart';

void registerEditListingFeature(GetIt sl) {
  sl.registerLazySingleton<EditListingRemoteDataSource>(
    () => SupabaseEditListingRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<EditListingRepository>(
    () => EditListingRepositoryImpl(sl<EditListingRemoteDataSource>()),
  );
  sl.registerFactory(() => UpdateListingDetailsV2(sl<EditListingRepository>()));
  sl.registerFactory(() => ReplaceListingImages(sl<EditListingRepository>()));

  // Reuses sequential upload + best-effort deletes from create-listing DI.
  sl.registerFactory<EditListingCubit>(
    () => EditListingCubit(
      getListingById: sl<GetListingById>(),
      getListingImages: sl<GetListingImages>(),
      updateListingDetailsV2: sl<UpdateListingDetailsV2>(),
      replaceListingImages: sl<ReplaceListingImages>(),
      uploadListingImagesSequential: sl<UploadListingImagesSequential>(),
      deleteUploadedListingImagesBestEffort:
          sl<DeleteUploadedListingImagesBestEffort>(),
      listingImageRepository: sl<ListingImageRepository>(),
    ),
  );
}
