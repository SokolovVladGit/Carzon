import 'dart:async';

import '../../../core/config/env.dart';
import '../../../core/l10n/app_locale_preference.dart';
import '../../../core/utils/logger.dart';
import '../domain/repositories/notifications_repository.dart';
import 'client_push_platform.dart';
import 'push_auth_gate.dart';
import 'push_messaging_client.dart';
import 'push_messaging_permission_status.dart';

/// Coordinates FCM token lifecycle with [NotificationsRepository] (RPC-only).
///
/// Does not request OS permission on startup; does not show UI; does not
/// handle notification taps (see [MessagePushTapHandler]) or display notifications.
class PushNotificationRegistrationService {
  PushNotificationRegistrationService({
    required PushMessagingClient messagingClient,
    required NotificationsRepository notificationsRepository,
    required PushAuthGate authGate,
    required AppLocalePreference Function() readLocalePreference,
    AppLogger? logger,
  }) : _messagingClient = messagingClient,
       _notificationsRepository = notificationsRepository,
       _authGate = authGate,
       _readLocalePreference = readLocalePreference,
       _logger = logger ?? AppLogger('PushNotificationRegistration');

  final PushMessagingClient _messagingClient;
  final NotificationsRepository _notificationsRepository;
  final PushAuthGate _authGate;
  final AppLocalePreference Function() _readLocalePreference;
  final AppLogger _logger;

  bool _firebaseReady = false;
  bool _tokenRefreshAttached = false;
  StreamSubscription<String>? _tokenRefreshSub;

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
  Future<void> syncTokenWithBackendIfEligible() async {
    try {
      if (!Env.pushNotificationsEnabled) {
        return;
      }
      if (!await _ensureFirebaseReady()) {
        return;
      }
      if (!_authGate.hasAuthenticatedUser) {
        return;
      }
      final status = await _messagingClient.getPermissionStatus();
      if (!status.allowsTokenRegistration) {
        return;
      }
      final token = await _messagingClient.getFcmToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }
      await _registerWithRepository(token.trim());
    } catch (e, st) {
      _logger.error('syncTokenWithBackendIfEligible failed', e, st);
    }
  }

  /// Explicit OS permission request (user-driven flows only).
  Future<PushMessagingPermissionStatus>
  requestOsNotificationPermission() async {
    try {
      if (!Env.pushNotificationsEnabled) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (!await _ensureFirebaseReady()) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      return _messagingClient.requestPermission();
    } catch (e, st) {
      _logger.error('requestOsNotificationPermission failed', e, st);
      return PushMessagingPermissionStatus.notDetermined;
    }
  }

  /// Current OS notification permission (no prompt).
  Future<PushMessagingPermissionStatus>
  readOsNotificationPermissionStatus() async {
    try {
      if (!Env.pushNotificationsEnabled) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      if (!await _ensureFirebaseReady()) {
        return PushMessagingPermissionStatus.notDetermined;
      }
      return _messagingClient.getPermissionStatus();
    } catch (e, st) {
      _logger.error('readOsNotificationPermissionStatus failed', e, st);
      return PushMessagingPermissionStatus.notDetermined;
    }
  }

  /// Deactivates server tokens and deletes the local FCM token (settings off).
  Future<void> revokeDevicePushRegistration() async {
    try {
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
      if (_firebaseReady) {
        await _messagingClient.deleteFcmToken();
      }
    } catch (e, st) {
      _logger.error('revokeDevicePushRegistration deleteToken failed', e, st);
    }
  }

  /// Called while the session is still valid, before clearing auth state.
  Future<void> beforeSignOut() async {
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
      if (!_firebaseReady && !await _ensureFirebaseReady()) {
        return;
      }
      if (!_authGate.hasAuthenticatedUser) {
        return;
      }
      final status = await _messagingClient.getPermissionStatus();
      if (!status.allowsTokenRegistration) {
        return;
      }
      final trimmed = token.trim();
      if (trimmed.isEmpty) {
        return;
      }
      await _registerWithRepository(trimmed);
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
    final platform = detectClientPushTokenPlatform();
    final result = await _notificationsRepository.registerPushToken(
      token: token,
      platform: platform,
      locale: _pushTokenLocaleTag(),
    );
    result.fold(
      (failure) => _logger.warn('registerPushToken failed: ${failure.message}'),
      (_) => _logger.debug('registerPushToken success'),
    );
  }
}
