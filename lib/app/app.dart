import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/favorites/presentation/bloc/favorites_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

class CarzonApp extends StatelessWidget {
  CarzonApp({super.key});

  final _router = AppRouter.build();

  @override
  Widget build(BuildContext context) {
    // AuthCubit and FavoritesCubit are bootstrapped/synced in
    // `app/bootstrap.dart` *before* the first frame so the initial
    // state is already correct here. The BlocListener below keeps
    // FavoritesCubit in sync on subsequent auth transitions.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: sl<AuthCubit>()),
        BlocProvider<FavoritesCubit>.value(value: sl<FavoritesCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) => prev.user?.id != curr.user?.id,
            listener: (context, state) {
              context.read<FavoritesCubit>().syncWithAuth(state.user);
            },
          ),
          BlocListener<AuthCubit, AuthState>(
            // Route the user into the reset-password flow when
            // Supabase's deep-link observer latches a recovery event.
            // GoRouter lives outside the widget tree so we navigate
            // imperatively through the stored instance.
            listenWhen: (prev, curr) =>
                prev.status != curr.status &&
                curr.status == AuthStatus.passwordRecovery,
            listener: (_, _) => _router.go(AppRoutes.resetPassword),
          ),
        ],
        child: MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          // Russian is the MVP product language. Romanian (`ro`) and
          // English (`en`) are planned but intentionally not added yet;
          // forcing `locale` to `ru` means unsupported device locales
          // also render in Russian instead of falling back to English.
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
