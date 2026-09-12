import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/create_listing_image_remote_datasource.dart';
import '../data/datasources/create_listing_remote_datasource.dart';
import '../data/datasources/manual_smart_fill_remote_datasource.dart';
import '../data/datasources/seller_listing_defaults_remote_datasource.dart';
import '../data/datasources/vehicle_resolver_remote_datasource.dart';
import '../data/repositories/create_listing_repository_impl.dart';
import '../data/repositories/listing_image_repository_impl.dart';
import '../data/repositories/manual_smart_fill_repository_impl.dart';
import '../data/repositories/seller_listing_defaults_repository_impl.dart';
import '../data/repositories/vehicle_resolver_repository_impl.dart';
import '../domain/repositories/create_listing_repository.dart';
import '../domain/repositories/manual_smart_fill_repository.dart';
import '../domain/repositories/seller_listing_defaults_repository.dart';
import '../domain/repositories/vehicle_resolver_repository.dart';
import '../domain/usecases/create_listing.dart';
import '../domain/usecases/create_listing_v2.dart';
import '../domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import '../domain/usecases/get_my_listing_defaults.dart';
import '../domain/usecases/resolve_vehicle.dart';
import '../domain/usecases/resolve_vehicle_by_identity.dart';
import '../domain/usecases/save_my_listing_defaults.dart';
import '../domain/usecases/upload_listing_cover_image.dart';
import '../domain/usecases/upload_listing_images_sequential.dart';
import '../presentation/bloc/create_listing_cubit.dart';
import '../presentation/bloc/manual_smart_fill_cubit.dart';

void registerCreateListingFeature(GetIt sl) {
  sl.registerLazySingleton<CreateListingRemoteDataSource>(
    () => SupabaseCreateListingRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<CreateListingImageRemoteDataSource>(
    () => SupabaseCreateListingImageRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<VehicleResolverRemoteDataSource>(
    () => SupabaseVehicleResolverRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<SellerListingDefaultsRemoteDataSource>(
    () => SupabaseSellerListingDefaultsRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<ManualSmartFillRemoteDataSource>(
    () => SupabaseManualSmartFillRemoteDataSource(sl<SupabaseService>()),
  );

  sl.registerLazySingleton<CreateListingRepository>(
    () => CreateListingRepositoryImpl(sl<CreateListingRemoteDataSource>()),
  );
  sl.registerLazySingleton<ListingImageRepository>(
    () => ListingImageRepositoryImpl(sl<CreateListingImageRemoteDataSource>()),
  );
  sl.registerLazySingleton<VehicleResolverRepository>(
    () => VehicleResolverRepositoryImpl(sl<VehicleResolverRemoteDataSource>()),
  );
  sl.registerLazySingleton<SellerListingDefaultsRepository>(
    () => SellerListingDefaultsRepositoryImpl(
      sl<SellerListingDefaultsRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<ManualSmartFillRepository>(
    () => ManualSmartFillRepositoryImpl(sl<ManualSmartFillRemoteDataSource>()),
  );

  sl.registerFactory(() => CreateListing(sl<CreateListingRepository>()));
  sl.registerFactory(() => CreateListingV2(sl<CreateListingRepository>()));
  sl.registerFactory(
    () => UploadListingCoverImage(sl<ListingImageRepository>()),
  );
  sl.registerFactory(
    () => UploadListingImagesSequential(sl<ListingImageRepository>()),
  );
  sl.registerFactory(
    () => DeleteUploadedListingImagesBestEffort(sl<ListingImageRepository>()),
  );
  sl.registerFactory(() => ResolveVehicle(sl<VehicleResolverRepository>()));
  sl.registerFactory(
    () => ResolveVehicleByIdentity(sl<ManualSmartFillRepository>()),
  );
  sl.registerFactory(
    () => GetMyListingDefaults(sl<SellerListingDefaultsRepository>()),
  );
  sl.registerFactory(
    () => SaveMyListingDefaults(sl<SellerListingDefaultsRepository>()),
  );

  sl.registerFactory<CreateListingCubit>(
    () => CreateListingCubit(
      createListingV2: sl<CreateListingV2>(),
      uploadListingImagesSequential: sl<UploadListingImagesSequential>(),
      deleteUploadedListingImagesBestEffort:
          sl<DeleteUploadedListingImagesBestEffort>(),
      resolveVehicle: sl<ResolveVehicle>(),
      currentUserId: () => sl<SupabaseService>().client.auth.currentUser?.id,
      authUserChanges: sl<SupabaseService>().client.auth.onAuthStateChange.map(
        (event) => event.session?.user.id,
      ),
      getMyListingDefaults: sl<GetMyListingDefaults>(),
      saveMyListingDefaults: sl<SaveMyListingDefaults>(),
    ),
  );
  sl.registerFactory<ManualSmartFillCubit>(
    () =>
        ManualSmartFillCubit(resolveByIdentity: sl<ResolveVehicleByIdentity>()),
  );
}
