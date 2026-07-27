import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env.dart';
import '../core/services/auth_deep_link_service.dart';
import '../core/services/supabase_service.dart';
import '../core/l10n/app_locale_cubit.dart';
import '../core/theme/theme_mode_cubit.dart';
import '../core/utils/logger.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/compare/presentation/cubit/compare_cubit.dart';
import '../features/favorites/presentation/bloc/favorites_cubit.dart';
import '../features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import '../features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../features/notifications/services/push_notification_registration_service.dart';
import '../features/recent_searches/presentation/cubit/recent_searches_cubit.dart';
import '../features/recently_viewed/presentation/cubit/recently_viewed_cubit.dart';
import '../features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'app.dart';
import 'bootstrap_splash_app.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'startup_error_app.dart';

/// App entry point. Strict order:
///   1. Bind Flutter
///   2. Validate required compile-time client config (fail fast → config error)
///   3. Mount [BootstrapSplashApp] while async init continues
///   4. When push is enabled, await [Firebase.initializeApp] (non-fatal if it
///      fails — FCM registration retries later)
///   5. Initialize Supabase (fail fast → config error screen)
///   6. Configure DI
///   7. Restore auth session before main app mount
///   8. Mount [CarzonApp]
///
/// Client config is supplied via `--dart-define-from-file=.env.client` (see
/// `.env.client.example`). No `.env` asset is loaded at runtime.
Future<void> bootstrap() async {
  final logger = AppLogger('bootstrap');

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final missing = Env.missingKeys();
      if (missing.isNotEmpty) {
        logger.error('Missing required client config keys: $missing');
        runApp(
          StartupErrorApp(
            title: 'Configuration error',
            message:
                'Missing required compile-time configuration. '
                'Copy .env.client.example to .env.client, fill client-safe '
                'values, and run with:\n'
                'flutter run --dart-define-from-file=.env.client',
            details: missing,
          ),
        );
        return;
      }

      runApp(const BootstrapSplashApp());

      if (Env.pushNotificationsEnabled) {
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp();
          }
        } catch (e) {
          logger.warn(
            'Firebase.initializeApp failed at bootstrap; push may be unavailable until fixed: $e',
          );
        }
      }

      final SupabaseService supabase;
      try {
        supabase = await SupabaseService.initialize();
      } catch (e, st) {
        logger.error('Supabase initialization failed', e, st);
        runApp(
          StartupErrorApp(
            title: 'Backend unavailable',
            message:
                'Failed to initialize Supabase. '
                'Verify SUPABASE_URL and SUPABASE_ANON_KEY in .env.client '
                'and pass --dart-define-from-file=.env.client.',
            details: [e.toString()],
          ),
        );
        return;
      }

      await configureDependencies(supabase);
      sl.registerSingleton<GoRouter>(AppRouter.build());
      await sl<ThemeModeCubit>().load();
      await sl<AppLocaleCubit>().load();

      final auth = sl<AuthCubit>();
      await auth.bootstrap();

      final activeUser = auth.state.status == AuthStatus.authenticated
          ? auth.state.user
          : null;
      await sl<FavoritesCubit>().syncWithAuth(activeUser);

      await sl<CompareCubit>().loadFromStorage();
      await sl<RecentlyViewedCubit>().loadFromStorage();
      await sl<RecentSearchesCubit>().loadFromStorage();

      await sl<SelfSellerVisualCubit>().prime(auth.state);
      await sl<MessagingUnreadSummaryCubit>().sync(auth.state);
      unawaited(sl<BrowseCatalogFilterAlertsCubit>().onAuthChanged(auth.state));

      await sl<PushNotificationRegistrationService>().start();

      await sl<AuthDeepLinkService>().initialize();

      runApp(const CarzonApp());
    },
    (error, stackTrace) {
      logger.error('Uncaught zone error', error, stackTrace);
    },
  );
}
