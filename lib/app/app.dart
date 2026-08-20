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
import '../features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
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
  static const _unreadPollInterval = Duration(seconds: 15);

  Future<void>? _pushListenersStartInFlight;
  Future<void>? _pushResumeRecoveryInFlight;
  Future<void>? _unreadSyncInFlight;
  String? _unreadSyncUserId;
  Timer? _unreadPollTimer;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateUnreadPolling(sl<AuthCubit>().state);
    });
    if (Env.pushNotificationsEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_ensurePushListenersStarted());
      });
    }
  }

  @override
  void dispose() {
    _unreadPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      _unreadPollTimer?.cancel();
      _unreadPollTimer = null;
      return;
    }
    final auth = sl<AuthCubit>().state;
    _updateUnreadPolling(auth);
    if (auth.status == AuthStatus.authenticated) {
      unawaited(_requestUnreadSync(auth));
    }
    if (!Env.pushNotificationsEnabled) {
      return;
    }
    unawaited(_recoverPushAfterResume());
  }

  void _updateUnreadPolling(AuthState auth) {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = null;
    if (!_isForeground || auth.status != AuthStatus.authenticated) return;
    _unreadPollTimer = Timer.periodic(_unreadPollInterval, (_) {
      unawaited(_requestUnreadSync(sl<AuthCubit>().state));
    });
  }

  Future<void> _requestUnreadSync(AuthState auth) async {
    final userId = auth.status == AuthStatus.authenticated
        ? auth.user?.id
        : null;
    final inFlight = _unreadSyncInFlight;
    if (inFlight != null && userId == _unreadSyncUserId) return inFlight;

    final sync = sl<MessagingUnreadSummaryCubit>().sync(auth);
    _unreadSyncInFlight = sync;
    _unreadSyncUserId = userId;
    try {
      await sync;
    } finally {
      if (identical(_unreadSyncInFlight, sync)) {
        _unreadSyncInFlight = null;
        _unreadSyncUserId = null;
      }
    }
  }

  Future<void> _recoverPushAfterResume() async {
    final inFlight = _pushResumeRecoveryInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final recovery = _runPushResumeRecovery();
    _pushResumeRecoveryInFlight = recovery;
    try {
      await recovery;
    } finally {
      if (identical(_pushResumeRecoveryInFlight, recovery)) {
        _pushResumeRecoveryInFlight = null;
      }
    }
  }

  Future<void> _runPushResumeRecovery() async {
    // Retry FCM token sync when the app returns to foreground: on iOS the
    // APNs token may not have existed at cold-start bootstrap, so startup
    // sync no-ops; this path is cheap (returns early if still not eligible).
    try {
      await sl<PushNotificationRegistrationService>()
          .syncTokenWithBackendIfEligible();
    } catch (_) {
      // Registration logs its own nonfatal failures. Listener recovery must
      // still proceed independently.
    }
    await _ensurePushListenersStarted();
  }

  Future<void> _ensurePushListenersStarted() async {
    final inFlight = _pushListenersStartInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final start = _startMissingPushListeners();
    _pushListenersStartInFlight = start;
    try {
      await start;
    } finally {
      if (identical(_pushListenersStartInFlight, start)) {
        _pushListenersStartInFlight = null;
      }
    }
  }

  Future<void> _startMissingPushListeners() async {
    final tapHandler = sl<MessagePushTapHandler>();
    final foregroundPresenter = sl<MessageForegroundNotificationPresenter>();
    await Future.wait([
      if (!tapHandler.isStarted) _startPushTapHandler(tapHandler),
      if (!foregroundPresenter.isStarted || !foregroundPresenter.isDisplayReady)
        _startForegroundPresenter(foregroundPresenter),
    ]);
  }

  Future<void> _startPushTapHandler(MessagePushTapHandler handler) async {
    try {
      await handler.start();
    } catch (_) {
      // Individual services log nonfatal startup failures and remain retryable.
    }
  }

  Future<void> _startForegroundPresenter(
    MessageForegroundNotificationPresenter presenter,
  ) async {
    try {
      await presenter.start();
    } catch (_) {
      // Individual services log nonfatal startup failures and remain retryable.
    }
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
            listenWhen: (prev, curr) =>
                prev.user?.id != curr.user?.id || prev.status != curr.status,
            listener: (context, state) {
              _updateUnreadPolling(state);
              final activeUser = state.status == AuthStatus.authenticated
                  ? state.user
                  : null;
              sl<PushNotificationRegistrationService>().handleAuthStateChanged(
                activeUser?.id,
              );
              unawaited(
                context.read<FavoritesCubit>().syncWithAuth(activeUser),
              );
              unawaited(context.read<SelfSellerVisualCubit>().prime(state));
              unawaited(_requestUnreadSync(state));
              unawaited(
                sl<BrowseCatalogFilterAlertsCubit>().onAuthChanged(state),
              );
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
