import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import '../../notifications/domain/repositories/notifications_repository.dart';
import '../../notifications/services/push_notification_registration_service.dart';
import '../data/datasources/filter_alerts_remote_datasource.dart';
import '../data/repositories/filter_alerts_repository_impl.dart';
import '../domain/repositories/filter_alerts_repository.dart';
import '../domain/services/filter_alert_delivery_orchestrator.dart';
import '../domain/usecases/clear_filter_alert_criteria.dart';
import '../domain/usecases/get_filter_alert_settings.dart';
import '../domain/usecases/save_filter_alert_criteria.dart';
import '../domain/usecases/set_filter_alert_notifications_enabled.dart';
import '../presentation/cubit/filter_alert_settings_cubit.dart';

void registerFilterAlertsFeature(GetIt sl) {
  sl.registerLazySingleton<FilterAlertsRemoteDataSource>(
    () => SupabaseFilterAlertsRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<FilterAlertsRepository>(
    () => FilterAlertsRepositoryImpl(sl<FilterAlertsRemoteDataSource>()),
  );
  sl.registerFactory(() => GetFilterAlertSettings(sl<FilterAlertsRepository>()));
  sl.registerFactory(() => SaveFilterAlertCriteria(sl<FilterAlertsRepository>()));
  sl.registerFactory(() => ClearFilterAlertCriteria(sl<FilterAlertsRepository>()));
  sl.registerFactory(
    () => SetFilterAlertNotificationsEnabled(sl<FilterAlertsRepository>()),
  );
  sl.registerLazySingleton(
    () => FilterAlertDeliveryOrchestrator(
      notificationsRepository: sl<NotificationsRepository>(),
      pushRegistration: sl<PushNotificationRegistrationService>(),
      setNotificationsEnabled: sl<SetFilterAlertNotificationsEnabled>(),
    ),
  );
  sl.registerFactory(
    () => FilterAlertSettingsCubit(
      getSettings: sl<GetFilterAlertSettings>(),
      saveCriteria: sl<SaveFilterAlertCriteria>(),
      clearCriteria: sl<ClearFilterAlertCriteria>(),
      deliveryOrchestrator: sl<FilterAlertDeliveryOrchestrator>(),
    ),
  );
  sl.registerFactory(
    () => BrowseCatalogFilterAlertsCubit(
      getSettings: sl<GetFilterAlertSettings>(),
      saveCriteria: sl<SaveFilterAlertCriteria>(),
      clearCriteria: sl<ClearFilterAlertCriteria>(),
      notificationsRepository: sl<NotificationsRepository>(),
      deliveryOrchestrator: sl<FilterAlertDeliveryOrchestrator>(),
    ),
  );
}
