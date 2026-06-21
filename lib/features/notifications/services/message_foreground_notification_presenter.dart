import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/config/env.dart';
import '../../../core/utils/logger.dart';
import 'filter_alert_listing_navigation_coordinator.dart';
import 'filter_alert_notification_tap_payload.dart';
import 'message_conversation_navigation_coordinator.dart';
import 'message_foreground_notification_display.dart';
import 'message_notification_tap_payload.dart';
import 'price_drop_notification_tap_payload.dart';

/// Subscribes to foreground FCM data messages and shows a local notification.
class MessageForegroundNotificationPresenter {
  MessageForegroundNotificationPresenter({
    required MessageConversationNavigationCoordinator navigationCoordinator,
    required FilterAlertListingNavigationCoordinator
    listingNavigationCoordinator,
    required MessageForegroundNotificationDisplay display,
    Stream<RemoteMessage>? foregroundMessageStream,
    bool Function()? firebaseAppReady,
    AppLogger? logger,
  }) : _navigationCoordinator = navigationCoordinator,
       _listingNavigationCoordinator = listingNavigationCoordinator,
       _display = display,
       _foregroundMessageStream = foregroundMessageStream,
       _firebaseAppReady = firebaseAppReady ?? (() => Firebase.apps.isNotEmpty),
       _logger = logger ?? AppLogger('MessageForegroundNotificationPresenter');

  final MessageConversationNavigationCoordinator _navigationCoordinator;
  final FilterAlertListingNavigationCoordinator _listingNavigationCoordinator;
  final MessageForegroundNotificationDisplay _display;
  final Stream<RemoteMessage>? _foregroundMessageStream;
  final bool Function() _firebaseAppReady;
  final AppLogger _logger;

  StreamSubscription<RemoteMessage>? _sub;
  bool _started = false;

  /// Idempotent. Call after the first frame (same as [MessagePushTapHandler]).
  Future<void> start() async {
    if (!Env.pushNotificationsEnabled || _started) {
      return;
    }
    if (!_firebaseAppReady()) {
      _logger.warn(
        'Skipping foreground message notifications: Firebase default app missing',
      );
      return;
    }

    _started = true;

    try {
      _navigationCoordinator.ensureStarted();
      _listingNavigationCoordinator.ensureStarted();
      await _display.initialize();

      final stream = _foregroundMessageStream ?? FirebaseMessaging.onMessage;
      _sub = stream.listen(
        _onForegroundMessage,
        onError: (Object e, StackTrace st) {
          _logger.error('onMessage stream error', e, st);
        },
      );
    } catch (e, st) {
      _logger.error(
        'MessageForegroundNotificationPresenter.start failed',
        e,
        st,
      );
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    unawaited(_handleForegroundMessage(message));
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final msgPayload = parseMessageNotificationTapPayload(message.data);
      if (msgPayload != null) {
        await _display.showMessageForegroundNotification(
          msgPayload.conversationId,
        );
        return;
      }
      final filterPayload = parseFilterAlertNotificationTapPayload(
        message.data,
      );
      if (filterPayload != null) {
        await _display.showFilterAlertForegroundNotification(
          filterPayload.listingId,
        );
        return;
      }
      final priceDropPayload = parsePriceDropNotificationTapPayload(
        message.data,
      );
      if (priceDropPayload != null) {
        await _display.showPriceDropForegroundNotification(
          priceDropPayload.listingId,
        );
        return;
      }
    } catch (e, st) {
      _logger.error('_handleForegroundMessage failed', e, st);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }
}
