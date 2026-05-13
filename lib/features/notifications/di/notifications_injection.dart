import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/notifications_remote_datasource.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/repositories/notifications_repository.dart';
import '../services/firebase_push_messaging_client.dart';
import '../services/push_auth_gate.dart';
import '../services/push_messaging_client.dart';
import '../services/push_notification_registration_service.dart';

void registerNotificationsFeature(GetIt sl) {
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => SupabaseNotificationsRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl<NotificationsRemoteDataSource>()),
  );
  sl.registerLazySingleton<PushAuthGate>(
    () => SupabasePushAuthGate(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<PushMessagingClient>(
    () => FirebasePushMessagingClient(),
  );
  sl.registerLazySingleton<PushNotificationRegistrationService>(
    () => PushNotificationRegistrationService(
      messagingClient: sl<PushMessagingClient>(),
      notificationsRepository: sl<NotificationsRepository>(),
      authGate: sl<PushAuthGate>(),
    ),
  );
}
