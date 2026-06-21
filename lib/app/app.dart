import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env.dart';
import '../core/constants/app_constants.dart';
import '../core/l10n/app_locale_cubit.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_cubit.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/compare/presentation/cubit/compare_cubit.dart';
import '../features/recent_searches/presentation/cubit/recent_searches_cubit.dart';
import '../features/recently_viewed/presentation/cubit/recently_viewed_cubit.dart';
import '../features/compare/presentation/widgets/compare_tray_host.dart';
import '../features/favorites/presentation/bloc/favorites_cubit.dart';
import '../features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../features/notifications/services/message_foreground_notification_presenter.dart';
import '../features/notifications/services/message_push_tap_handler.dart';
import '../features/notifications/services/push_notification_registration_service.dart';
import '../features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

class CarzonApp extends StatefulWidget {
  const CarzonApp({super.key});

  @override
  State<CarzonApp> createState() => _CarzonAppState();
}

class _CarzonAppState extends State<CarzonApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (Env.pushNotificationsEnabled) {
      WidgetsBinding.instance.addObserver(this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(sl<MessagePushTapHandler>().start());
        unawaited(sl<MessageForegroundNotificationPresenter>().start());
      });
    }
  }

  @override
  void dispose() {
    if (Env.pushNotificationsEnabled) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    if (!Env.pushNotificationsEnabled) {
      return;
    }
    // Retry FCM token sync when the app returns to foreground: on iOS the
    // APNs token may not have existed at cold-start bootstrap, so startup
    // sync no-ops; this path is cheap (returns early if still not eligible).
    unawaited(
      sl<PushNotificationRegistrationService>()
          .syncTokenWithBackendIfEligible(),
    );
  }

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
        BlocProvider<CompareCubit>.value(value: sl<CompareCubit>()),
        BlocProvider<RecentlyViewedCubit>.value(
          value: sl<RecentlyViewedCubit>(),
        ),
        BlocProvider<RecentSearchesCubit>.value(
          value: sl<RecentSearchesCubit>(),
        ),
        BlocProvider<SelfSellerVisualCubit>.value(
          value: sl<SelfSellerVisualCubit>(),
        ),
        BlocProvider<MessagingUnreadSummaryCubit>.value(
          value: sl<MessagingUnreadSummaryCubit>(),
        ),
        BlocProvider<ThemeModeCubit>.value(value: sl<ThemeModeCubit>()),
        BlocProvider<AppLocaleCubit>.value(value: sl<AppLocaleCubit>()),
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
            listenWhen: (prev, curr) =>
                prev.user?.id != curr.user?.id && curr.user != null,
            listener: (_, _) {
              unawaited(
                sl<PushNotificationRegistrationService>()
                    .syncTokenWithBackendIfEligible(),
              );
            },
          ),
          BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) =>
                prev.user?.id != curr.user?.id || prev.status != curr.status,
            listener: (context, state) {
              unawaited(context.read<SelfSellerVisualCubit>().prime(state));
              unawaited(
                context.read<MessagingUnreadSummaryCubit>().sync(state),
              );
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
            listener: (_, _) => sl<GoRouter>().go(AppRoutes.resetPassword),
          ),
        ],
        child: BlocBuilder<ThemeModeCubit, ThemeModeState>(
          builder: (context, themeState) =>
              BlocBuilder<AppLocaleCubit, AppLocaleState>(
                builder: (context, localeState) => MaterialApp.router(
                  title: AppConstants.appName,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: themeState.themeMode,
                  locale: localeState.locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localeResolutionCallback: (locale, supported) {
                    for (final supportedLocale in supported) {
                      if (supportedLocale.languageCode ==
                          localeState.locale.languageCode) {
                        return supportedLocale;
                      }
                    }
                    return const Locale('ru');
                  },
                  routerConfig: sl<GoRouter>(),
                  builder: (context, child) =>
                      CompareTrayHost(router: sl<GoRouter>(), child: child),
                  debugShowCheckedModeBanner: false,
                ),
              ),
        ),
      ),
    );
  }
}
