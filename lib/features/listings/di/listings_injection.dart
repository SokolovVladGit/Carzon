import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../messaging/domain/usecases/get_or_create_conversation.dart';
import '../data/local/anonymous_viewer_id_repository.dart';
import '../domain/repositories/anonymous_viewer_id_repository.dart';
import '../data/local/last_applied_listing_discovery_repository.dart';
import '../data/datasources/listings_remote_datasource.dart';
import '../data/datasources/vehicle_model_catalog_remote_datasource.dart';
import '../data/repositories/listings_repository_impl.dart';
import '../data/repositories/vehicle_model_catalog_repository_impl.dart';
import '../domain/repositories/listings_repository.dart';
import '../domain/repositories/vehicle_model_catalog_repository.dart';
import '../domain/usecases/delete_listing.dart';
import '../domain/usecases/get_listing_by_id.dart';
import '../domain/usecases/get_listing_images.dart';
import '../domain/usecases/get_listing_public_contact.dart';
import '../domain/usecases/get_listings.dart';
import '../../recent_searches/domain/usecases/record_recent_search.dart';
import '../../recently_viewed/domain/usecases/record_recently_viewed.dart';
import '../domain/usecases/record_listing_view.dart';
import '../domain/usecases/report_listing.dart';
import '../domain/usecases/set_listing_status.dart';
import '../presentation/bloc/listing_details_cubit.dart';
import '../presentation/bloc/listings_bloc.dart';

void registerListingsFeature(GetIt sl) {
  sl.registerLazySingleton<VehicleModelCatalogRemoteDataSource>(
    () => SupabaseVehicleModelCatalogRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<VehicleModelCatalogRepository>(
    () => VehicleModelCatalogRepositoryImpl(
      sl<VehicleModelCatalogRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<ListingsRemoteDataSource>(
    () => SupabaseListingsRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<ListingsRepository>(
    () => ListingsRepositoryImpl(sl<ListingsRemoteDataSource>()),
  );
  sl.registerFactory(() => GetListings(sl<ListingsRepository>()));
  sl.registerFactory(() => GetListingById(sl<ListingsRepository>()));
  sl.registerFactory(() => GetListingImages(sl<ListingsRepository>()));
  sl.registerFactory(() => GetListingPublicContact(sl<ListingsRepository>()));
  sl.registerFactory(() => SetListingStatus(sl<ListingsRepository>()));
  sl.registerFactory(() => DeleteListing(sl<ListingsRepository>()));
  sl.registerFactory(() => ReportListing(sl<ListingsRepository>()));
  sl.registerLazySingleton<LastAppliedListingDiscoveryRepository>(
    () => SharedPreferencesLastAppliedListingDiscoveryRepository(),
  );
  sl.registerLazySingleton<AnonymousViewerIdRepository>(
    () => SharedPreferencesAnonymousViewerIdRepository(),
  );
  sl.registerFactory(
    () => RecordListingView(
      sl<ListingsRepository>(),
      sl<AnonymousViewerIdRepository>(),
    ),
  );
  sl.registerFactory<ListingsBloc>(
    () => ListingsBloc(
      getListings: sl<GetListings>(),
      lastAppliedDiscovery: sl<LastAppliedListingDiscoveryRepository>(),
      recordRecentSearch: sl<RecordRecentSearch>(),
    ),
  );
  sl.registerFactory<ListingDetailsCubit>(
    () => ListingDetailsCubit(
      getListingById: sl<GetListingById>(),
      getListingImages: sl<GetListingImages>(),
      getListingPublicContact: sl<GetListingPublicContact>(),
      getOrCreateConversation: sl<GetOrCreateConversation>(),
      recordListingView: sl<RecordListingView>(),
      recordRecentlyViewed: sl<RecordRecentlyViewed>(),
    ),
  );
}
