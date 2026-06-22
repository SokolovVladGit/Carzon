import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import '../../notifications/domain/repositories/notifications_repository.dart';
import '../../notifications/services/push_notification_registration_service.dart';
import '../data/datasources/filter_alerts_remote_datasource.dart';
import '../data/repositories/filter_alerts_repository_impl.dart';
import '../domain/repositories/saved_searches_repository.dart';
import '../domain/services/filter_alert_delivery_orchestrator.dart';
import '../domain/usecases/create_saved_search.dart';
import '../domain/usecases/delete_saved_search.dart';
import '../domain/usecases/list_saved_searches.dart';
import '../domain/usecases/set_saved_search_alerts_enabled.dart';
import '../presentation/cubit/saved_searches_cubit.dart';

void registerFilterAlertsFeature(GetIt sl) {
  sl.registerLazySingleton<SavedSearchesRemoteDataSource>(
    () => SupabaseSavedSearchesRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<SavedSearchesRepository>(
    () => SavedSearchesRepositoryImpl(sl<SavedSearchesRemoteDataSource>()),
  );
  sl.registerFactory(() => ListSavedSearches(sl<SavedSearchesRepository>()));
  sl.registerFactory(() => CreateSavedSearch(sl<SavedSearchesRepository>()));
  sl.registerFactory(() => DeleteSavedSearch(sl<SavedSearchesRepository>()));
  sl.registerFactory(
    () => SetSavedSearchAlertsEnabled(sl<SavedSearchesRepository>()),
  );
  sl.registerLazySingleton(
    () => FilterAlertDeliveryOrchestrator(
      notificationsRepository: sl<NotificationsRepository>(),
      pushRegistration: sl<PushNotificationRegistrationService>(),
      setAlertsEnabled: sl<SetSavedSearchAlertsEnabled>(),
    ),
  );
  sl.registerFactory(
    () => SavedSearchesCubit(
      listSavedSearches: sl<ListSavedSearches>(),
      deleteSavedSearch: sl<DeleteSavedSearch>(),
      deliveryOrchestrator: sl<FilterAlertDeliveryOrchestrator>(),
    ),
  );
  sl.registerFactory(
    () => BrowseCatalogFilterAlertsCubit(
      listSavedSearches: sl<ListSavedSearches>(),
      createSavedSearch: sl<CreateSavedSearch>(),
      notificationsRepository: sl<NotificationsRepository>(),
      deliveryOrchestrator: sl<FilterAlertDeliveryOrchestrator>(),
    ),
  );
}
