import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/logger.dart';
import 'push_messaging_client.dart';
import 'push_messaging_permission_status.dart';

/// [PushMessagingClient] backed by Firebase Cloud Messaging.
///
/// Does not call [FirebaseMessaging.instance] until [initializeFirebase]
/// has completed successfully (or a [FirebaseMessaging] instance was injected
/// for tests).
class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient({FirebaseMessaging? messaging, AppLogger? logger})
    : _messagingInjected = messaging,
      _logger = logger ?? AppLogger('FirebasePushMessagingClient');

  final FirebaseMessaging? _messagingInjected;
  FirebaseMessaging? _messagingResolved;
  final AppLogger _logger;

  FirebaseMessaging get _messaging {
    final injected = _messagingInjected;
    if (injected != null) {
      return injected;
    }
    final resolved = _messagingResolved;
    if (resolved == null) {
      throw StateError(
        'FirebasePushMessagingClient: call initializeFirebase() before '
        'using Firebase Cloud Messaging.',
      );
    }
    return resolved;
  }

  @override
  Future<bool> initializeFirebase() async {
    try {
      if (_messagingInjected != null) {
        _messagingResolved = _messagingInjected;
        return true;
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _messagingResolved = FirebaseMessaging.instance;
      return true;
    } catch (e, st) {
      _messagingResolved = null;
      _logger.error('Firebase.initializeApp failed', e, st);
      return false;
    }
  }

  @override
  Future<PushMessagingPermissionStatus> getPermissionStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return _mapAuthorization(settings.authorizationStatus);
    } catch (e, st) {
      _logger.error('getNotificationSettings failed', e, st);
      return PushMessagingPermissionStatus.notDetermined;
    }
  }

  @override
  Future<PushMessagingPermissionStatus> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return _mapAuthorization(settings.authorizationStatus);
    } catch (e, st) {
      _logger.error('requestPermission failed', e, st);
      return PushMessagingPermissionStatus.notDetermined;
    }
  }

  /// True on iOS/macOS where FCM depends on APNs being registered first.
  static bool _needsApnsPrecheck() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Resolves the FCM registration token, or `null` if unavailable.
  ///
  /// On iOS/macOS, waits for an APNs token before calling [FirebaseMessaging.getToken]
  /// and maps `apns-token-not-set` to `null` without treating it as a hard failure.
  @override
  Future<String?> getFcmToken() async {
    try {
      if (FirebasePushMessagingClient._needsApnsPrecheck()) {
        final apns = await _messaging.getAPNSToken();
        if (apns == null || apns.isEmpty) {
          _logger.warn(
            'APNs token unavailable; FCM token registration remains pending',
          );
          return null;
        }
      }
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        _logger.warn('FCM token unavailable after Firebase token request');
        return null;
      }
      return token;
    } on FirebaseException catch (e, st) {
      if (e.code == 'apns-token-not-set') {
        _logger.warn(
          'FCM token not ready (APNs not registered yet): ${e.message ?? e.code}',
        );
        return null;
      }
      _logger.error('getToken failed', e, st);
      return null;
    } catch (e, st) {
      _logger.error('getToken failed', e, st);
      return null;
    }
  }

  @override
  Stream<String> watchTokenRefresh() => _messaging.onTokenRefresh;

  @override
  Future<void> deleteFcmToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e, st) {
      _logger.error('deleteToken failed', e, st);
    }
  }

  PushMessagingPermissionStatus _mapAuthorization(AuthorizationStatus s) {
    switch (s) {
      case AuthorizationStatus.authorized:
        return PushMessagingPermissionStatus.authorized;
      case AuthorizationStatus.denied:
        return PushMessagingPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return PushMessagingPermissionStatus.notDetermined;
      case AuthorizationStatus.provisional:
        return PushMessagingPermissionStatus.provisional;
    }
  }
}
