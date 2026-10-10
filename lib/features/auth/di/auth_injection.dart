import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../../notifications/services/push_notification_registration_service.dart';
import '../../../core/config/env.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/social/apple_sign_in_adapter.dart';
import '../data/social/google_sign_in_adapter.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/social/apple_native_auth.dart';
import '../domain/social/google_native_auth.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/resend_signup_confirmation.dart';
import '../domain/usecases/request_password_reset.dart';
import '../domain/usecases/sign_in_with_apple.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_in_with_password.dart';
import '../domain/usecases/sign_out.dart';
import '../domain/usecases/sign_up_with_password.dart';
import '../domain/usecases/update_password.dart';
import '../presentation/bloc/auth_cubit.dart';
import '../presentation/bloc/change_password_cubit.dart';
import '../presentation/bloc/confirm_email_cubit.dart';
import '../presentation/bloc/forgot_password_cubit.dart';
import '../presentation/bloc/reset_password_cubit.dart';

void registerAuthFeature(GetIt sl) {
  // Data
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => SupabaseAuthRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<GoogleNativeAuth>(
    () => GoogleSignInAdapter(
      webClientId: Env.googleWebClientId ?? '',
      iosClientId: Env.googleIosClientId,
    ),
  );
  sl.registerLazySingleton<AppleNativeAuth>(() => AppleSignInAdapter());

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<AuthRemoteDataSource>(),
      googleNativeAuth: sl<GoogleNativeAuth>(),
      appleNativeAuth: sl<AppleNativeAuth>(),
    ),
  );

  // Use cases
  sl.registerFactory(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerFactory(() => SignInWithPassword(sl<AuthRepository>()));
  sl.registerFactory(() => SignInWithGoogle(sl<AuthRepository>()));
  sl.registerFactory(() => SignInWithApple(sl<AuthRepository>()));
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
  sl.registerFactory(() => ResendSignupConfirmation(sl<AuthRepository>()));

  // AuthCubit owns the global session — must be a singleton so that
  // bootstrap (in app startup) and BlocProvider.value (in CarzonApp)
  // resolve the same instance.
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      repository: sl<AuthRepository>(),
      getCurrentUser: sl<GetCurrentUser>(),
      signInWithPassword: sl<SignInWithPassword>(),
      signInWithGoogle: sl<SignInWithGoogle>(),
      signInWithApple: sl<SignInWithApple>(),
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
  sl.registerFactoryParam<ConfirmEmailCubit, String, void>(
    (email, _) => ConfirmEmailCubit(
      email: email,
      resendSignupConfirmation: sl<ResendSignupConfirmation>(),
    ),
  );
  sl.registerFactory<ChangePasswordCubit>(
    () => ChangePasswordCubit(
      signInWithPassword: sl<SignInWithPassword>(),
      updatePassword: sl<UpdatePassword>(),
    ),
  );
}
