import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../notifications/services/push_notification_registration_service.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/request_password_reset.dart';
import '../domain/usecases/sign_in_with_password.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/sign_up_with_password.dart';
import '../domain/usecases/update_password.dart';
import '../presentation/bloc/auth_cubit.dart';
import '../presentation/bloc/forgot_password_cubit.dart';
import '../presentation/bloc/reset_password_cubit.dart';

void registerAuthFeature(GetIt sl) {
  // Data
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => SupabaseAuthRemoteDataSource(sl<SupabaseService>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );

  // Use cases
  sl.registerFactory(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerFactory(() => SignInWithPassword(sl<AuthRepository>()));
  sl.registerFactory(() => SignUpWithPassword(sl<AuthRepository>()));
  sl.registerFactory(
    () => SignOut(
      sl<AuthRepository>(),
      preSignOutHooks: <Future<void> Function()>[
        () => sl<PushNotificationRegistrationService>().beforeSignOut(),
      ],
    ),
  );
  sl.registerFactory(() => RequestPasswordReset(sl<AuthRepository>()));
  sl.registerFactory(() => UpdatePassword(sl<AuthRepository>()));

  // AuthCubit owns the global session — must be a singleton so that
  // bootstrap (in app startup) and BlocProvider.value (in CarzonApp)
  // resolve the same instance.
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      repository: sl<AuthRepository>(),
      getCurrentUser: sl<GetCurrentUser>(),
      signInWithPassword: sl<SignInWithPassword>(),
      signUpWithPassword: sl<SignUpWithPassword>(),
      signOut: sl<SignOut>(),
    ),
  );

  // Page-scoped cubits for the forgot/reset flows. Registered as
  // factories so each mount gets a fresh instance (matches the way
  // other page cubits are wired elsewhere in the app).
  sl.registerFactory<ForgotPasswordCubit>(
    () => ForgotPasswordCubit(requestPasswordReset: sl<RequestPasswordReset>()),
  );
  sl.registerFactory<ResetPasswordCubit>(
    () => ResetPasswordCubit(updatePassword: sl<UpdatePassword>()),
  );
}
