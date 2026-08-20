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

enum _ForegroundPresenterStartupState { idle, starting, started }

/// Subscribes to foreground FCM data messages and shows a local notification.
class MessageForegroundNotificationPresenter {
  MessageForegroundNotificationPresenter({
    required MessageConversationNavigationCoordinator navigationCoordinator,
    required FilterAlertListingNavigationCoordinator
    listingNavigationCoordinator,
    required MessageForegroundNotificationDisplay display,
    Future<void> Function()? syncMessageUnread,
    Stream<RemoteMessage>? foregroundMessageStream,
    bool Function()? firebaseAppReady,
    AppLogger? logger,
  }) : _navigationCoordinator = navigationCoordinator,
       _listingNavigationCoordinator = listingNavigationCoordinator,
       _display = display,
       _syncMessageUnread = syncMessageUnread,
       _foregroundMessageStream = foregroundMessageStream,
       _firebaseAppReady = firebaseAppReady ?? (() => Firebase.apps.isNotEmpty),
       _logger = logger ?? AppLogger('MessageForegroundNotificationPresenter');

  final MessageConversationNavigationCoordinator _navigationCoordinator;
  final FilterAlertListingNavigationCoordinator _listingNavigationCoordinator;
  final MessageForegroundNotificationDisplay _display;
  final Future<void> Function()? _syncMessageUnread;
  final Stream<RemoteMessage>? _foregroundMessageStream;
  final bool Function() _firebaseAppReady;
  final AppLogger _logger;

  StreamSubscription<RemoteMessage>? _sub;
  _ForegroundPresenterStartupState _startupState =
      _ForegroundPresenterStartupState.idle;
  Future<void>? _startInFlight;
  bool _displayReady = false;

  bool get isStarted =>
      _startupState == _ForegroundPresenterStartupState.started;
  bool get isDisplayReady => _displayReady;

  /// Idempotent. Call after the first frame (same as [MessagePushTapHandler]).
  Future<void> start() async {
    if (!Env.pushNotificationsEnabled || (isStarted && _displayReady)) {
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
    _logger.info('foreground_presenter_start_attempt');
    if (!isStarted) {
      _startupState = _ForegroundPresenterStartupState.starting;
      try {
        if (!_firebaseAppReady()) {
          _logger.warn(
            'Skipping foreground message notifications: Firebase default app missing',
          );
          _startupState = _ForegroundPresenterStartupState.idle;
          return;
        }
        _navigationCoordinator.ensureStarted();
        _listingNavigationCoordinator.ensureStarted();

        final stream = _foregroundMessageStream ?? FirebaseMessaging.onMessage;
        _sub = stream.listen(
          _onForegroundMessage,
          onError: (Object e, StackTrace st) {
            _logger.error('onMessage stream error', e, st);
          },
        );
        _startupState = _ForegroundPresenterStartupState.started;
        _logger.info('foreground_presenter_started');
      } catch (e, st) {
        await _sub?.cancel();
        _sub = null;
        _startupState = _ForegroundPresenterStartupState.idle;
        _logger.error(
          'MessageForegroundNotificationPresenter.start failed',
          e,
          st,
        );
        return;
      }
    }

    if (_displayReady) return;
    try {
      _displayReady = await _display.initialize();
      if (_displayReady) {
        _logger.info('foreground_local_display_ready');
      } else {
        _logger.warn('foreground_local_display_unavailable');
      }
    } catch (e, st) {
      _logger.error('foreground_local_display_initialization_failed', e, st);
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    unawaited(_handleForegroundMessage(message));
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      _logger.info('foreground_on_message_received');
      final msgPayload = parseMessageNotificationTapPayload(message.data);
      if (msgPayload != null) {
        _logger.info('foreground_payload_accepted');
        await Future.wait([
          _presentLocally(
            () => _display.showMessageForegroundNotification(
              msgPayload.conversationId,
            ),
          ),
          _syncUnreadIndependently(),
        ]);
        return;
      }
      final filterPayload = parseFilterAlertNotificationTapPayload(
        message.data,
      );
      if (filterPayload != null) {
        _logger.info('foreground_payload_accepted');
        await _presentLocally(
          () => _display.showFilterAlertForegroundNotification(
            filterPayload.listingId,
          ),
        );
        return;
      }
      final priceDropPayload = parsePriceDropNotificationTapPayload(
        message.data,
      );
      if (priceDropPayload != null) {
        _logger.info('foreground_payload_accepted');
        await _presentLocally(
          () => _display.showPriceDropForegroundNotification(
            priceDropPayload.listingId,
          ),
        );
        return;
      }
      _logger.warn(_payloadRejectionReason(message.data));
    } catch (e, st) {
      _logger.error('_handleForegroundMessage failed', e, st);
    }
  }

  Future<void> _presentLocally(Future<void> Function() show) async {
    if (!_displayReady) {
      _logger.warn('foreground_local_display_unavailable');
      return;
    }
    _logger.info('foreground_local_display_attempt');
    try {
      await show();
      _logger.info('foreground_local_display_completed');
    } catch (_) {
      _logger.error('foreground_local_display_failed');
    }
  }

  Future<void> _syncUnreadIndependently() async {
    final sync = _syncMessageUnread;
    if (sync == null) return;
    try {
      await sync();
    } catch (_) {
      _logger.error('foreground_unread_sync_failed');
    }
  }

  String _payloadRejectionReason(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim().toLowerCase() ?? '';
    return switch (type) {
      '' || 'message' || 'message_created' => 'invalid_conversation_id',
      'filter_alert' || 'price_drop' => 'invalid_listing_id',
      _ => 'unsupported_type',
    };
  }

  Future<void> dispose() async {
    final inFlight = _startInFlight;
    if (inFlight != null) {
      await inFlight;
    }
    final subscription = _sub;
    _sub = null;
    await subscription?.cancel();
    _startupState = _ForegroundPresenterStartupState.idle;
    _displayReady = false;
  }
}
