import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/messaging_remote_datasource.dart';
import '../data/repositories/messaging_repository_impl.dart';
import '../domain/repositories/messaging_repository.dart';
import '../domain/usecases/get_or_create_conversation.dart';
import '../presentation/bloc/messaging_unread_summary_cubit.dart';

void registerMessagingFeature(GetIt sl) {
  sl.registerLazySingleton<MessagingRemoteDataSource>(
    () => SupabaseMessagingRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(sl<MessagingRemoteDataSource>()),
  );
  sl.registerFactory(() => GetOrCreateConversation(sl<MessagingRepository>()));

  sl.registerLazySingleton<MessagingUnreadSummaryCubit>(
    () => MessagingUnreadSummaryCubit(sl<MessagingRepository>()),
  );
}
