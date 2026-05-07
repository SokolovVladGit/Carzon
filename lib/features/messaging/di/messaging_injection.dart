import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/messaging_remote_datasource.dart';
import '../data/repositories/messaging_repository_impl.dart';
import '../domain/repositories/messaging_repository.dart';

void registerMessagingFeature(GetIt sl) {
  sl.registerLazySingleton<MessagingRemoteDataSource>(
    () => SupabaseMessagingRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(sl<MessagingRemoteDataSource>()),
  );
}
