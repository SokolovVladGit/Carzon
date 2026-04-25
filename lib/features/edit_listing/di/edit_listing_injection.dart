import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../create_listing/domain/repositories/create_listing_repository.dart';
import '../../create_listing/domain/usecases/upload_listing_cover_image.dart';
import '../../listings/domain/usecases/get_listing_by_id.dart';
import '../data/datasources/edit_listing_remote_datasource.dart';
import '../data/repositories/edit_listing_repository_impl.dart';
import '../domain/repositories/edit_listing_repository.dart';
import '../domain/usecases/update_listing_cover_image.dart';
import '../domain/usecases/update_listing_details.dart';
import '../presentation/bloc/edit_listing_cubit.dart';

void registerEditListingFeature(GetIt sl) {
  sl.registerLazySingleton<EditListingRemoteDataSource>(
    () => SupabaseEditListingRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<EditListingRepository>(
    () => EditListingRepositoryImpl(sl<EditListingRemoteDataSource>()),
  );
  sl.registerFactory(() => UpdateListingDetails(sl<EditListingRepository>()));
  sl.registerFactory(
    () => UpdateListingCoverImage(sl<EditListingRepository>()),
  );

  // Reuses `GetListingById` from the listings feature to seed the form;
  // that use case is already registered by `registerListingsFeature`.
  // `UploadListingCoverImage` and `ListingImageRepository` are owned
  // by the create-listing feature but are fully backend-agnostic from
  // the edit-listing cubit's perspective; reusing them avoids a
  // second storage datasource.
  sl.registerFactory<EditListingCubit>(
    () => EditListingCubit(
      getListingById: sl<GetListingById>(),
      updateListingDetails: sl<UpdateListingDetails>(),
      updateListingCoverImage: sl<UpdateListingCoverImage>(),
      uploadListingCoverImage: sl<UploadListingCoverImage>(),
      listingImageRepository: sl<ListingImageRepository>(),
    ),
  );
}
