import 'dart:async';

import '../../../core/config/env.dart';
import '../../../core/l10n/app_locale_preference.dart';
import '../../../core/utils/logger.dart';
import '../domain/repositories/notifications_repository.dart';
import 'client_push_platform.dart';
import 'push_auth_gate.dart';
import 'push_messaging_client.dart';
import 'push_messaging_permission_status.dart';

/// Captures the authenticated notification authority at the start of an
/// asynchronous operation. A guard becomes stale on sign-out/account change.
final class NotificationSessionGuard {
  const NotificationSessionGuard({
    required this.expectedUserId,
    required this.generation,
    required bool Function() isCurrent,
  }) : _isCurrent = isCurrent;

  final String expectedUserId;
  final int generation;
  final bool Function() _isCurrent;

  bool get isCurrent => _isCurrent();
}

final class _PendingTokenSync {
  const _PendingTokenSync({required this.guard, this.tokenOverride});

  final NotificationSessionGuard guard;
  final String? tokenOverride;
}

/// Coordinates FCM token lifecycle with [NotificationsRepository] (RPC-only).
///
/// Does not request OS permission on startup; does not show UI; does not
/// handle notification taps (see [MessagePushTapHandler]) or display notifications.
class PushNotificationRegistrationService {
  PushNotificationRegistrationService({
    required PushMessagingClient messagingClient,
    required NotificationsRepository notificationsRepository,
    required PushAuthGate authGate,
    required String? Function() readAuthenticatedUserId,
    required AppLocalePreference Function() readLocalePreference,
    AppLogger? logger,
  }) : _messagingClient = messagingClient,
       _notificationsRepository = notificationsRepository,
       _authGate = authGate,
       _readAuthenticatedUserId = readAuthenticatedUserId,
       _readLocalePreference = readLocalePreference,
       _authorityUserId = readAuthenticatedUserId(),
       _logger = logger ?? AppLogger('PushNotificationRegistration');

  final PushMessagingClient _messagingClient;
  final NotificationsRepository _notificationsRepository;
  final PushAuthGate _authGate;
  final String? Function() _readAuthenticatedUserId;
  final AppLocalePreference Function() _readLocalePreference;
  final AppLogger _logger;

  bool _firebaseReady = false;
  bool _tokenRefreshAttached = false;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _authorityUserId;
  int _authorityGeneration = 0;
  Future<void>? _syncLoopInFlight;
  _PendingTokenSync? _activeTokenSync;
  _PendingTokenSync? _pendingTokenSync;
  final Set<String> _tokensBeingRegistered = <String>{};

  /// Updates notification authority before auth-transition side effects run.
  void handleAuthStateChanged(String? authenticatedUserId) {
    final normalized = authenticatedUserId?.trim();
    final next = normalized == null || normalized.isEmpty ? null : normalized;
    if (_authorityUserId == next) return;
    _authorityGeneration += 1;
    _authorityUserId = next;
    _pendingTokenSync = null;
  }

  /// Captures the current authenticated session for user-bound notification
  /// work. The optional check composes page/cubit generation authority.
  NotificationSessionGuard? captureSessionGuard({
    bool Function()? additionalCheck,
  }) {
    final userId = _authorityUserId;
    if (userId == null || userId.isEmpty) return null;
    final generation = _authorityGeneration;
    return NotificationSessionGuard(
      expectedUserId: userId,
      generation: generation,
      isCurrent: () {
        final liveUserId = _readAuthenticatedUserId()?.trim();
        return _authorityGeneration == generation &&
            _authorityUserId == userId &&
            liveUserId == userId &&
            (additionalCheck?.call() ?? true);
      },
    );
  }

  /// Starts FCM listeners (when enabled by config) and syncs the token if
  /// the user is already signed in and permission was previously granted.
  ///
  /// Does **not** call [PushMessagingClient.requestPermission].
  Future<void> start() async {
    try {
      if (!Env.pushNotificationsEnabled) {
        _logger.debug('Push disabled via PUSH_NOTIFICATIONS_ENABLED');
        return;
      }
      if (!await _ensureFirebaseReady()) {
        return;
      }
      await syncTokenWithBackendIfEligible();
    } catch (e, st) {
      _logger.error('start failed', e, st);
    }
  }

  /// Syncs the device token with Supabase when config, auth, permission,
  /// and token availability allow (no permission prompt).
  Future<void> syncTokenWithBackendIfEligible({
    bool Function()? isSessionCurrent,
  }) async {
    final guard = captureSessionGuard(additionalCheck: isSessionCurrent);
    if (guard == null || !guard.isCurrent) return;
    return _queueTokenSync(_PendingTokenSync(guard: guard));
  }

  Future<void> _queueTokenSync(_PendingTokenSync request) async {
    final inFlight = _syncLoopInFlight;
    if (inFlight != null) {
      if (!_isEquivalentSyncRequest(_activeTokenSync, request) &&
          !_isEquivalentSyncRequest(_pendingTokenSync, request)) {
        _pendingTokenSync = request;
      }
      return inFlight;
    }
    _pendingTokenSync = request;
    final sync = _runPendingTokenSyncs();
    _syncLoopInFlight = sync;
    try {
      await sync;
    } finally {
      if (identical(_syncLoopInFlight, sync)) {
        _syncLoopInFlight = null;
      }
    }
  }

  Future<void> _runPendingTokenSyncs() async {
    while (true) {
      final request = _pendingTokenSync;
      if (request == null) return;
      _pendingTokenSync = null;
      _activeTokenSync = request;
      try {
        await _syncTokenWithBackendIfEligible(request);
      } finally {
        _activeTokenSync = null;
      }
      if (!request.guard.isCurrent && _pendingTokenSync == null) {
        final current = captureSessionGuard();
        if (current != null && current.isCurrent) {
          _pendingTokenSync = _PendingTokenSync(guard: current);
        }
      }
    }
  }

  bool _isEquivalentSyncRequest(
    _PendingTokenSync? existing,
    _PendingTokenSync incoming,
  ) {
    return existing?.guard.expectedUserId == incoming.guard.expectedUserId &&
        existing?.guard.generation == incoming.guard.generation &&
        existing?.tokenOverride == incoming.tokenOverride;
  }

  Future<void> _syncTokenWithBackendIfEligible(
    _PendingTokenSync request,
  ) async {
    final guard = request.guard;
    try {
      if (!Env.pushNotificationsEnabled) {
        return;
      }
      if (!guard.isCurrent) return;
      if (!await _ensureFirebaseReady()) {
        return;
      }
      if (!guard.isCurrent) return;
      if (!_authGate.hasAuthenticatedUser) {
        return;
      }
      final status = await _messagingClient.getPermissionStatus();
      if (!guard.isCurrent) return;
      if (!status.allowsTokenRegistration) {
        return;
      }
      final token =
          request.tokenOverride ?? await _messagingClient.getFcmToken();
      if (!guard.isCurrent) return;
      if (token == null || token.trim().isEmpty) {
        return;
      }
      await _registerWithRepository(token.trim());
    } catch (e, st) {
      _logger.error('syncTokenWithBackendIfEligible failed', e, st);
    }
  }

  /// Best-effort OS permission before saving notification preferences.
  ///
  /// Only [PushMessagingPermissionStatus.denied] should block preference
  /// persistence; simulator / missing FCM token must not block saving prefs.
  Future<PushMessagingPermissionStatus> resolvePermissionForPreferenceEnable({
    NotificationSessionGuard? sessionGuard,
  }) async {
    try {
      if (sessionGuard != null && !sessionGuard.isCurrent) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (!Env.pushNotificationsEnabled) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      var perm = await readOsNotificationPermissionStatus(
        sessionGuard: sessionGuard,
      );
      if (sessionGuard != null && !sessionGuard.isCurrent) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (perm.allowsTokenRegistration || perm.blocksPreferenceEnable) {
        return perm;
      }
      return requestOsNotificationPermission(sessionGuard: sessionGuard);
    } catch (e, st) {
      _logger.error('resolvePermissionForPreferenceEnable failed', e, st);
      return PushMessagingPermissionStatus.notDetermined;
    }
  }

  /// Explicit OS permission request (user-driven flows only).
  Future<PushMessagingPermissionStatus> requestOsNotificationPermission({
    NotificationSessionGuard? sessionGuard,
  }) async {
    try {
      if (sessionGuard != null && !sessionGuard.isCurrent) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (!Env.pushNotificationsEnabled) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (!await _ensureFirebaseReady()) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (sessionGuard != null && !sessionGuard.isCurrent) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      final status = await _messagingClient.requestPermission();
      return sessionGuard == null || sessionGuard.isCurrent
          ? status
          : PushMessagingPermissionStatus.notDetermined;
    } catch (e, st) {
      _logger.error('requestOsNotificationPermission failed', e, st);
      return PushMessagingPermissionStatus.notDetermined;
    }
  }

  /// Current OS notification permission (no prompt).
  Future<PushMessagingPermissionStatus> readOsNotificationPermissionStatus({
    NotificationSessionGuard? sessionGuard,
  }) async {
    try {
      if (sessionGuard != null && !sessionGuard.isCurrent) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (!Env.pushNotificationsEnabled) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (!await _ensureFirebaseReady()) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (sessionGuard != null && !sessionGuard.isCurrent) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      final status = await _messagingClient.getPermissionStatus();
      return sessionGuard == null || sessionGuard.isCurrent
          ? status
          : PushMessagingPermissionStatus.notDetermined;
    } catch (e, st) {
      _logger.error('readOsNotificationPermissionStatus failed', e, st);
      return PushMessagingPermissionStatus.notDetermined;
    }
  }

  /// Deactivates server tokens and deletes the local FCM token (settings off).
  Future<void> revokeDevicePushRegistration({
    NotificationSessionGuard? sessionGuard,
  }) async {
    try {
      if (sessionGuard != null && !sessionGuard.isCurrent) return;
      if (!Env.pushNotificationsEnabled) {
        return;
      }
      if (_authGate.hasAuthenticatedUser) {
        await _notificationsRepository.deactivateMyPushTokens();
      }
    } catch (e, st) {
      _logger.error('revokeDevicePushRegistration deactivate failed', e, st);
    }
    try {
      if (sessionGuard != null && !sessionGuard.isCurrent) return;
      if (_firebaseReady) {
        await _messagingClient.deleteFcmToken();
      }
    } catch (e, st) {
      _logger.error('revokeDevicePushRegistration deleteToken failed', e, st);
    }
  }

  /// Called while the session is still valid, before clearing auth state.
  Future<void> beforeSignOut() async {
    _authorityGeneration += 1;
    _authorityUserId = null;
    _pendingTokenSync = null;
    await _syncLoopInFlight;
    try {
      if (!Env.pushNotificationsEnabled) {
        return;
      }
      if (_authGate.hasAuthenticatedUser) {
        await _notificationsRepository.deactivateMyPushTokens();
      }
    } catch (e, st) {
      _logger.error('beforeSignOut deactivateMyPushTokens failed', e, st);
    }
    try {
      if (_firebaseReady) {
        await _messagingClient.deleteFcmToken();
      }
    } catch (e, st) {
      _logger.error('beforeSignOut deleteFcmToken failed', e, st);
    }
  }

  /// Disposes token-refresh subscription (tests / tear-down).
  Future<void> dispose() async {
    await _syncLoopInFlight;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _tokenRefreshAttached = false;
    _firebaseReady = false;
  }

  Future<bool> _ensureFirebaseReady() async {
    if (_firebaseReady) {
      return true;
    }
    final ok = await _messagingClient.initializeFirebase();
    if (!ok) {
      _logger.warn('Firebase not ready; skipping FCM registration');
      return false;
    }
    _firebaseReady = true;
    if (Env.pushNotificationsEnabled) {
      _attachTokenRefreshListener();
    }
    return true;
  }

  void _attachTokenRefreshListener() {
    if (_tokenRefreshAttached) {
      return;
    }
    _tokenRefreshAttached = true;
    _tokenRefreshSub = _messagingClient.watchTokenRefresh().listen(
      (token) {
        unawaited(_onTokenRefresh(token));
      },
      onError: (Object e, StackTrace st) {
        _logger.error('onTokenRefresh stream error', e, st);
      },
    );
  }

  Future<void> _onTokenRefresh(String token) async {
    try {
      if (!Env.pushNotificationsEnabled) {
        return;
      }
      final trimmed = token.trim();
      if (trimmed.isEmpty) {
        return;
      }
      final guard = captureSessionGuard();
      if (guard == null || !guard.isCurrent) return;
      await _queueTokenSync(
        _PendingTokenSync(guard: guard, tokenOverride: trimmed),
      );
    } catch (e, st) {
      _logger.error('_onTokenRefresh failed', e, st);
    }
  }

  String _pushTokenLocaleTag() {
    return switch (_readLocalePreference()) {
      AppLocalePreference.ro => 'ro',
      AppLocalePreference.ru => 'ru',
    };
  }

  Future<void> _registerWithRepository(String token) async {
    if (!_tokensBeingRegistered.add(token)) {
      return;
    }
    final platform = detectClientPushTokenPlatform();
    try {
      final result = await _notificationsRepository.registerPushToken(
        token: token,
        platform: platform,
        locale: _pushTokenLocaleTag(),
      );
      result.fold(
        (failure) =>
            _logger.warn('registerPushToken failed: ${failure.message}'),
        (_) => _logger.debug('registerPushToken success'),
      );
    } finally {
      _tokensBeingRegistered.remove(token);
    }
  }
}
