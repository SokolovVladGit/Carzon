import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/config/env.dart';
import '../../../core/utils/logger.dart';
import 'filter_alert_listing_navigation_coordinator.dart';
import 'filter_alert_notification_tap_payload.dart';
import 'firebase_messaging_open_events.dart';
import 'message_conversation_navigation_coordinator.dart';
import 'message_notification_tap_payload.dart';
import 'price_drop_notification_tap_payload.dart';

enum _PushTapHandlerStartupState { idle, starting, started }

/// Listens for push notification opens and routes by `type` in FCM data.
class MessagePushTapHandler {
  MessagePushTapHandler({
    required MessageConversationNavigationCoordinator navigationCoordinator,
    required FilterAlertListingNavigationCoordinator
    listingNavigationCoordinator,
    FirebaseMessagingOpenEvents? openEvents,
    bool Function()? firebaseAppReady,
    AppLogger? logger,
  }) : _navigationCoordinator = navigationCoordinator,
       _listingNavigationCoordinator = listingNavigationCoordinator,
       _openEvents = openEvents ?? DefaultFirebaseMessagingOpenEvents(),
       _firebaseAppReady = firebaseAppReady ?? (() => Firebase.apps.isNotEmpty),
       _logger = logger ?? AppLogger('MessagePushTapHandler');

  final MessageConversationNavigationCoordinator _navigationCoordinator;
  final FilterAlertListingNavigationCoordinator _listingNavigationCoordinator;
  final FirebaseMessagingOpenEvents _openEvents;
  final bool Function() _firebaseAppReady;
  final AppLogger _logger;

  StreamSubscription<RemoteMessage>? _openedAppSub;
  _PushTapHandlerStartupState _startupState = _PushTapHandlerStartupState.idle;
  Future<void>? _startInFlight;
  bool _initialMessageHandled = false;

  bool get isStarted => _startupState == _PushTapHandlerStartupState.started;

  /// Idempotent. Safe to call from the first frame after [MaterialApp.router]
  /// is mounted.
  Future<void> start() async {
    if (!Env.pushNotificationsEnabled || isStarted) {
      return;
    }
    final inFlight = _startInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final attempt = _start();
    _startInFlight = attempt;
    try {
      await attempt;
    } finally {
      if (identical(_startInFlight, attempt)) {
        _startInFlight = null;
      }
    }
  }

  Future<void> _start() async {
    _startupState = _PushTapHandlerStartupState.starting;
    try {
      if (!_firebaseAppReady()) {
        _logger.warn(
          'Skipping message push tap handler: Firebase default app not available',
        );
        _startupState = _PushTapHandlerStartupState.idle;
        return;
      }
      _navigationCoordinator.ensureStarted();
      _listingNavigationCoordinator.ensureStarted();

      await _consumeInitialMessageOnce();

      _openedAppSub = _openEvents.onMessageOpenedApp.listen(
        _onOpenedApp,
        onError: (Object e, StackTrace st) {
          _logger.error('onMessageOpenedApp stream error', e, st);
        },
      );
      _startupState = _PushTapHandlerStartupState.started;
    } catch (e, st) {
      await _openedAppSub?.cancel();
      _openedAppSub = null;
      _startupState = _PushTapHandlerStartupState.idle;
      _logger.error('MessagePushTapHandler.start failed', e, st);
    }
  }

  Future<void> _consumeInitialMessageOnce() async {
    if (_initialMessageHandled) {
      return;
    }
    try {
      final message = await _openEvents.getInitialMessage();
      _initialMessageHandled = true;
      if (message == null) {
        return;
      }
      await _handleRemoteMessage(message);
    } catch (e, st) {
      _logger.error('getInitialMessage failed', e, st);
      rethrow;
    }
  }

  void _onOpenedApp(RemoteMessage message) {
    unawaited(_handleRemoteMessage(message));
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    try {
      final msgPayload = parseMessageNotificationTapPayload(message.data);
      if (msgPayload != null) {
        _navigationCoordinator.requestOpenThread(msgPayload.conversationId);
        return;
      }
      final filterPayload = parseFilterAlertNotificationTapPayload(
        message.data,
      );
      if (filterPayload != null) {
        _listingNavigationCoordinator.requestOpenListing(
          filterPayload.listingId,
        );
        return;
      }
      final priceDropPayload = parsePriceDropNotificationTapPayload(
        message.data,
      );
      if (priceDropPayload != null) {
        _listingNavigationCoordinator.requestOpenListing(
          priceDropPayload.listingId,
        );
        return;
      }
    } catch (e, st) {
      _logger.error('_handleRemoteMessage failed', e, st);
    }
  }

  Future<void> dispose() async {
    final inFlight = _startInFlight;
    if (inFlight != null) {
      await inFlight;
    }
    final subscription = _openedAppSub;
    _openedAppSub = null;
    await subscription?.cancel();
    _startupState = _PushTapHandlerStartupState.idle;
    _initialMessageHandled = false;
  }
}
