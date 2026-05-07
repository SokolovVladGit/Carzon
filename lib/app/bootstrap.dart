import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/config/env.dart';
import '../core/services/auth_deep_link_service.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/logger.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/favorites/presentation/bloc/favorites_cubit.dart';
import 'app.dart';
import 'di/injection.dart';
import 'startup_error_app.dart';

/// App entry point. Strict order:
///   1. Bind Flutter
///   2. Load .env
///   3. Validate required env (fail fast → config error screen)
///   4. Initialize Supabase (fail fast → config error screen)
///   5. Configure DI
///   6. Restore auth session before first frame
///   7. Mount widget tree
///
/// If any startup step fails, [StartupErrorApp] is shown instead of
/// crashing with an unclear error.
Future<void> bootstrap() async {
  final logger = AppLogger('bootstrap');

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await dotenv.load(fileName: '.env');
      } catch (e, st) {
        logger.error('Failed to load .env', e, st);
        runApp(
          const StartupErrorApp(
            title: 'Configuration error',
            message:
                'Could not load .env file. '
                'Copy .env.example to .env and fill in the required values.',
          ),
        );
        return;
      }

      final missing = Env.missingKeys();
      if (missing.isNotEmpty) {
        logger.error('Missing required env vars: $missing');
        runApp(
          StartupErrorApp(
            title: 'Configuration error',
            message: 'Missing required environment variables:',
            details: missing,
          ),
        );
        return;
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
                'Verify SUPABASE_URL and SUPABASE_ANON_KEY in .env.',
            details: [e.toString()],
          ),
        );
        return;
      }

      await configureDependencies(supabase);

      // Restore auth session before mounting the widget tree so that
      // the first frame already reflects the correct authenticated state.
      final auth = sl<AuthCubit>();
      await auth.bootstrap();

      // Sync favorites with the restored session before first frame.
      await sl<FavoritesCubit>().syncWithAuth(auth.state.user);

      // Start auth deep-link observer AFTER `AuthCubit.bootstrap()` so
      // the recovery-events subscription is already attached when
      // Supabase fires `AuthChangeEvent.passwordRecovery` from an
      // initial cold-start URL.
      await sl<AuthDeepLinkService>().initialize();

      runApp(CarzonApp());
    },
    (error, stackTrace) {
      logger.error('Uncaught zone error', error, stackTrace);
    },
  );
}
