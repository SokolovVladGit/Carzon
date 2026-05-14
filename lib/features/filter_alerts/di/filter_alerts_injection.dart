import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../notifications/domain/repositories/notifications_repository.dart';
import '../../notifications/services/push_notification_registration_service.dart';
import '../data/datasources/filter_alerts_remote_datasource.dart';
import '../data/repositories/filter_alerts_repository_impl.dart';
import '../domain/repositories/filter_alerts_repository.dart';
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
  sl.registerFactory(
    () => FilterAlertSettingsCubit(
      getSettings: sl<GetFilterAlertSettings>(),
      saveCriteria: sl<SaveFilterAlertCriteria>(),
      clearCriteria: sl<ClearFilterAlertCriteria>(),
      setNotificationsEnabled: sl<SetFilterAlertNotificationsEnabled>(),
      notificationsRepository: sl<NotificationsRepository>(),
      pushRegistration: sl<PushNotificationRegistrationService>(),
    ),
  );
}
