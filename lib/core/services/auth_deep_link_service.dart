import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
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
  }) : _authUrlHandler = authUrlHandler,
       _appLinks = appLinks ?? AppLinks(),
       _logger = logger ?? AppLogger('AuthDeepLinkService');

  /// Convenience constructor used by the real DI wiring.
  AuthDeepLinkService.forSupabase(
    SupabaseService supabase, {
    AppLinks? appLinks,
  }) : this(
         authUrlHandler: _SupabaseAuthUrlHandlerImpl(supabase),
         appLinks: appLinks,
       );

  final SupabaseAuthUrlHandler _authUrlHandler;
  final AppLinks _appLinks;
  final AppLogger _logger;

  StreamSubscription<Uri>? _linkSub;
  bool _initialized = false;
  final StreamController<void> _recoveryRejections =
      StreamController<void>.broadcast();
  final Set<String> _seenCallbackIdentities = <String>{};
  int _pendingRecoveryRejections = 0;

  /// Custom URL scheme registered in Android's AndroidManifest.xml
  /// intent-filter and iOS's CFBundleURLTypes. Keep this in sync with
  /// the `SUPABASE_PASSWORD_RESET_REDIRECT_URL` env value used in
  /// production (`carzon://auth-callback`).
  static const String kCustomScheme = 'carzon';

  /// Returns true when [uri] looks like a Supabase auth callback that
  /// the service should forward. Pure function; safe to call from
  /// tests without any platform channels or Supabase client.
  ///
  /// Accepted shape: `carzon://auth-callback…`, including query or
  /// fragment tokens. Other schemes and hosts are ignored so future
  /// app links that happen to carry a `code` query are not consumed.
  static bool isAuthCallback(Uri uri) {
    return uri.scheme.toLowerCase() == kCustomScheme &&
        uri.host.toLowerCase() == 'auth-callback';
  }

  /// Recovery callbacks only. Signup confirmation and other auth
  /// callbacks on the same host are not treated as password-reset links.
  static bool isRecoveryCallback(Uri uri) {
    if (!isAuthCallback(uri)) return false;
    return _authParameter(uri, 'type') == 'recovery';
  }

  static String? _authParameter(Uri uri, String key) {
    final query = uri.queryParameters[key]?.trim().toLowerCase();
    if (query != null && query.isNotEmpty) return query;
    if (uri.fragment.isEmpty) return null;
    final fragment = Uri.splitQueryString(
      uri.fragment,
    )[key]?.trim().toLowerCase();
    if (fragment == null || fragment.isEmpty) return null;
    return fragment;
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

  /// Subscribes to rejected recovery callbacks.
  ///
  /// Replays callbacks that arrived before the first listener, including
  /// a cold-start link handled inside [initialize]. The same callback is
  /// reported once even if the platform delivers it twice.
  StreamSubscription<void> bindRecoveryRejection(void Function() onRejected) {
    final subscription = _recoveryRejections.stream.listen((_) => onRejected());
    final pending = _pendingRecoveryRejections;
    _pendingRecoveryRejections = 0;
    for (var i = 0; i < pending; i++) {
      onRejected();
    }
    return subscription;
  }

  Future<bool> _handleUri(Uri uri) async {
    if (!isAuthCallback(uri)) {
      _logger.debug('Ignoring non-auth URI');
      return false;
    }
    if (!_seenCallbackIdentities.add(_callbackIdentity(uri))) {
      return true;
    }
    try {
      await _authUrlHandler.handleAuthUrl(uri);
      _logger.info('Processed auth callback URI');
    } on sb.AuthException {
      _logger.warn('Supabase rejected auth callback');
      if (isRecoveryCallback(uri)) {
        _signalRecoveryRejection();
      }
    } catch (e, st) {
      _logger.error('Unexpected error handling auth URL', e, st);
      if (isRecoveryCallback(uri)) {
        _signalRecoveryRejection();
      }
    }
    return true;
  }

  void _signalRecoveryRejection() {
    if (_recoveryRejections.isClosed) return;
    if (_recoveryRejections.hasListener) {
      _recoveryRejections.add(null);
      return;
    }
    _pendingRecoveryRejections++;
  }

  String _callbackIdentity(Uri uri) {
    return sha256.convert(utf8.encode(uri.toString())).toString();
  }

  Future<void> dispose() async {
    await _linkSub?.cancel();
    _linkSub = null;
    _initialized = false;
    _seenCallbackIdentities.clear();
    _pendingRecoveryRejections = 0;
    await _recoveryRejections.close();
  }
}
