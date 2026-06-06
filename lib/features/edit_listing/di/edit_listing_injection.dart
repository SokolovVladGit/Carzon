import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../create_listing/domain/repositories/create_listing_repository.dart';
import '../../create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import '../../create_listing/domain/usecases/upload_listing_images_sequential.dart';
import '../data/datasources/edit_listing_remote_datasource.dart';
import '../data/repositories/edit_listing_repository_impl.dart';
import '../domain/repositories/edit_listing_repository.dart';
import '../domain/usecases/get_owner_listing_for_edit.dart';
import '../domain/usecases/get_owner_listing_images_for_edit.dart';
import '../domain/usecases/replace_listing_images.dart';
import '../domain/usecases/update_listing_details_v2.dart';
import '../domain/usecases/get_owner_listing_vin_for_edit.dart';
import '../domain/usecases/get_owner_listing_vin_report_status_for_edit.dart';
import '../domain/usecases/get_owner_listing_vin_source_results_for_edit.dart';
import '../presentation/bloc/edit_listing_cubit.dart';

void registerEditListingFeature(GetIt sl) {
  sl.registerLazySingleton<EditListingRemoteDataSource>(
    () => SupabaseEditListingRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<EditListingRepository>(
    () => EditListingRepositoryImpl(sl<EditListingRemoteDataSource>()),
  );
  sl.registerFactory(() => GetOwnerListingForEdit(sl<EditListingRepository>()));
  sl.registerFactory(
    () => GetOwnerListingImagesForEdit(sl<EditListingRepository>()),
  );
  sl.registerFactory(() => UpdateListingDetailsV2(sl<EditListingRepository>()));
  sl.registerFactory(
    () => GetOwnerListingVinForEdit(sl<EditListingRepository>()),
  );
  sl.registerFactory(
    () => GetOwnerListingVinReportStatusForEdit(sl<EditListingRepository>()),
  );
  sl.registerFactory(
    () => GetOwnerListingVinSourceResultsForEdit(sl<EditListingRepository>()),
  );
  sl.registerFactory(() => ReplaceListingImages(sl<EditListingRepository>()));

  // Reuses sequential upload + best-effort deletes from create-listing DI.
  sl.registerFactory<EditListingCubit>(
    () => EditListingCubit(
      getOwnerListingForEdit: sl<GetOwnerListingForEdit>(),
      getOwnerListingImagesForEdit: sl<GetOwnerListingImagesForEdit>(),
      getOwnerListingVinForEdit: sl<GetOwnerListingVinForEdit>(),
      getOwnerListingVinReportStatusForEdit:
          sl<GetOwnerListingVinReportStatusForEdit>(),
      getOwnerListingVinSourceResultsForEdit:
          sl<GetOwnerListingVinSourceResultsForEdit>(),
      updateListingDetailsV2: sl<UpdateListingDetailsV2>(),
      replaceListingImages: sl<ReplaceListingImages>(),
      uploadListingImagesSequential: sl<UploadListingImagesSequential>(),
      deleteUploadedListingImagesBestEffort:
          sl<DeleteUploadedListingImagesBestEffort>(),
      listingImageRepository: sl<ListingImageRepository>(),
    ),
  );
}
