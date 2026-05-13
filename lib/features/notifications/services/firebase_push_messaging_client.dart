import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/utils/logger.dart';
import 'push_messaging_client.dart';
import 'push_messaging_permission_status.dart';

/// [PushMessagingClient] backed by Firebase Cloud Messaging.
class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient({
    FirebaseMessaging? messaging,
    AppLogger? logger,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _logger = logger ?? AppLogger('FirebasePushMessagingClient');

  final FirebaseMessaging _messaging;
  final AppLogger _logger;

  @override
  Future<bool> initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } catch (e, st) {
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
      final settings = await _messaging.requestPermission();
      return _mapAuthorization(settings.authorizationStatus);
    } catch (e, st) {
      _logger.error('requestPermission failed', e, st);
      return PushMessagingPermissionStatus.notDetermined;
    }
  }

  @override
  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
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
