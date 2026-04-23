import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
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
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev.user?.id != curr.user?.id,
        listener: (context, state) {
          context.read<FavoritesCubit>().syncWithAuth(state.user);
        },
        child: MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
