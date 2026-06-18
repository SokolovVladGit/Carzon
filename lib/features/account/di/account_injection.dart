import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../notifications/services/push_notification_registration_service.dart';
import '../data/datasources/account_privacy_remote_datasource.dart';
import '../data/repositories/account_privacy_repository_impl.dart';
import '../domain/repositories/account_privacy_repository.dart';
import '../domain/usecases/delete_account.dart';
import '../presentation/cubit/delete_account_cubit.dart';

void registerAccountFeature(GetIt sl) {
  sl.registerLazySingleton<AccountPrivacyRemoteDataSource>(
    () => SupabaseAccountPrivacyRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<AccountPrivacyRepository>(
    () => AccountPrivacyRepositoryImpl(sl<AccountPrivacyRemoteDataSource>()),
  );
  sl.registerFactory(
    () => DeleteAccount(
      sl<AccountPrivacyRepository>(),
      sl<AuthRepository>(),
      sl<PushNotificationRegistrationService>(),
    ),
  );
  sl.registerFactory(
    () => DeleteAccountCubit(deleteAccount: sl<DeleteAccount>()),
  );
}
