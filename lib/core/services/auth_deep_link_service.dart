import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../utils/logger.dart';
import 'supabase_service.dart';

/// Thin abstraction over the Supabase SDK's auth-URL parser so the
/// deep-link service can be unit-tested without a live Supabase
/// client. The default implementation forwards to
/// `client.auth.getSessionFromUrl`, which is the exact API supported
/// by supabase_flutter 2.12.x.
abstract interface class SupabaseAuthUrlHandler {
  Future<void> handleAuthUrl(Uri uri);
}

class _SupabaseAuthUrlHandlerImpl implements SupabaseAuthUrlHandler {
  _SupabaseAuthUrlHandlerImpl(this._supabase);

  final SupabaseService _supabase;

  @override
  Future<void> handleAuthUrl(Uri uri) {
    return _supabase.client.auth.getSessionFromUrl(uri);
  }
}

/// Listens for initial and runtime app links and forwards
/// Supabase auth-callback URLs to [SupabaseAuthUrlHandler].
///
/// Supabase emits `AuthChangeEvent.passwordRecovery` / normal signed-in
/// events from inside the SDK as a side-effect of successful parsing,
/// so [AuthCubit] (subscribed to those streams elsewhere) drives all
/// user-facing state transitions. This service is intentionally
/// navigation-free and exception-safe:
///
/// * unrelated URLs are ignored,
/// * parser failures are logged but never re-thrown,
/// * the [AppLinks] stream subscription is disposable so tests can
///   own the service lifecycle.
class AuthDeepLinkService {
  AuthDeepLinkService({
    required SupabaseAuthUrlHandler authUrlHandler,
    AppLinks? appLinks,
    AppLogger? logger,
  })  : _authUrlHandler = authUrlHandler,
        _appLinks = appLinks ?? AppLinks(),
        _logger = logger ?? AppLogger('AuthDeepLinkService');

  /// Convenience constructor used by the real DI wiring.
  AuthDeepLinkService.forSupabase(SupabaseService supabase, {AppLinks? appLinks})
      : this(
          authUrlHandler: _SupabaseAuthUrlHandlerImpl(supabase),
          appLinks: appLinks,
        );

  final SupabaseAuthUrlHandler _authUrlHandler;
  final AppLinks _appLinks;
  final AppLogger _logger;

  StreamSubscription<Uri>? _linkSub;
  bool _initialized = false;

  /// Custom URL scheme registered in Android's AndroidManifest.xml
  /// intent-filter and iOS's CFBundleURLTypes. Keep this in sync with
  /// the `SUPABASE_PASSWORD_RESET_REDIRECT_URL` env value used in
  /// production (`carzon://auth-callback`).
  static const String kCustomScheme = 'carzon';

  /// Returns true when [uri] looks like a Supabase auth callback that
  /// the service should forward. Pure function; safe to call from
  /// tests without any platform channels or Supabase client.
  ///
  /// Accepted shapes:
  /// * `carzon://…` — any URI using the app's own custom scheme. The
  ///   OS only routes these to the app via our intent-filter / URL
  ///   type, so by the time we see one it is implicitly an app
  ///   callback.
  /// * Any URI whose query/fragment carries Supabase auth tokens
  ///   (`access_token`, `code`, `error_description`, `error_code`).
  ///   This keeps the door open for a future web redirect or a
  ///   universal-link migration without touching the service.
  static bool isAuthCallback(Uri uri) {
    if (uri.scheme.toLowerCase() == kCustomScheme) return true;
    final full = uri.toString();
    return full.contains('access_token=') ||
        full.contains('error_description=') ||
        full.contains('error_code=') ||
        uri.queryParameters.containsKey('code');
  }

  /// Subscribes to the incoming-link stream and replays the cold-start
  /// link, if any. Safe to call multiple times — subsequent calls are
  /// no-ops. Never throws; platform errors are logged and swallowed so
  /// they cannot take down app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _linkSub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error, StackTrace stackTrace) {
        _logger.error('uriLinkStream error', error, stackTrace);
      },
    );

    try {
      // On mobile, `uriLinkStream` also emits the initial launch URI,
      // so this call is mostly for defensive parity with the web
      // platform and for tests that supply a fake `AppLinks`.
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleUri(initial);
      }
    } catch (e, st) {
      _logger.error('getInitialLink failed', e, st);
    }
  }

  /// Testable single-URI entry point. Returns `true` when the URI was
  /// recognised as an auth callback and forwarded to Supabase (whether
  /// or not the parse itself succeeded), `false` when ignored.
  Future<bool> handleUri(Uri uri) => _handleUri(uri);

  Future<bool> _handleUri(Uri uri) async {
    if (!isAuthCallback(uri)) {
      _logger.debug('Ignoring non-auth URI: $uri');
      return false;
    }
    try {
      await _authUrlHandler.handleAuthUrl(uri);
      _logger.info('Processed auth callback URI');
    } on sb.AuthException catch (e, st) {
      // Common causes: expired / already-consumed recovery link. The
      // UI stays on whatever screen the user is on; AuthCubit will
      // simply not latch `passwordRecovery`.
      _logger.warn('Supabase rejected auth URL: ${e.message}');
      _logger.debug(st.toString());
    } catch (e, st) {
      _logger.error('Unexpected error handling auth URL', e, st);
    }
    return true;
  }

  Future<void> dispose() async {
    await _linkSub?.cancel();
    _linkSub = null;
    _initialized = false;
  }
}
