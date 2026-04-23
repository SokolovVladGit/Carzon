import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/sign_in_with_password.dart';
import '../domain/usecases/sign_out.dart';
import '../presentation/bloc/auth_cubit.dart';

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
  sl.registerFactory(() => SignOut(sl<AuthRepository>()));

  // AuthCubit owns the global session — must be a singleton so that
  // bootstrap (in app startup) and BlocProvider.value (in CarzonApp)
  // resolve the same instance.
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      repository: sl<AuthRepository>(),
      getCurrentUser: sl<GetCurrentUser>(),
      signInWithPassword: sl<SignInWithPassword>(),
      signOut: sl<SignOut>(),
    ),
  );
}
