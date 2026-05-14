import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/utils/logger.dart';
import 'filter_alert_notification_public_copy.dart';
import 'filter_alert_notification_tap_payload.dart';
import 'message_foreground_notification_display.dart';
import 'message_notification_public_copy.dart';
import 'message_notification_tap_payload.dart';

/// [MessageForegroundNotificationDisplay] backed by [flutter_local_notifications].
///
/// Does not request OS notification permission during [initialize].
class CarzonMessageLocalNotificationsDisplay
    implements MessageForegroundNotificationDisplay {
  CarzonMessageLocalNotificationsDisplay({
    required void Function(String conversationId) onConversationNotificationTap,
    required void Function(String listingId) onFilterAlertNotificationTap,
    FlutterLocalNotificationsPlugin? plugin,
    AppLogger? logger,
  }) : _pluginOverride = plugin,
       _onConversationNotificationTap = onConversationNotificationTap,
       _onFilterAlertNotificationTap = onFilterAlertNotificationTap,
       _logger = logger ?? AppLogger('CarzonLocalNotifications');

  static const androidChannelId = 'carzon_messages';
  static const androidChannelName = 'Carzon — сообщения';
  static const androidChannelDescription =
      'Уведомления о новых сообщениях в чате';

  static const androidFilterChannelId = 'carzon_filter_alerts';
  static const androidFilterChannelName = 'Carzon — оповещения по фильтру';
  static const androidFilterChannelDescription =
      'Уведомления о новых объявлениях по сохранённому фильтру';

  final void Function(String conversationId) _onConversationNotificationTap;
  final void Function(String listingId) _onFilterAlertNotificationTap;
  final FlutterLocalNotificationsPlugin? _pluginOverride;
  final AppLogger _logger;

  FlutterLocalNotificationsPlugin? _pluginInstance;

  FlutterLocalNotificationsPlugin get _plugin =>
      _pluginOverride ?? (_pluginInstance ??= FlutterLocalNotificationsPlugin());

  bool _initialized = false;

  void _onNotificationResponse(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) {
        return;
      }
      final listingId = parseFilterAlertLocalNotificationPayload(payload);
      if (listingId != null) {
        _onFilterAlertNotificationTap(listingId);
        return;
      }
      if (!isMessageNotificationConversationId(payload)) {
        return;
      }
      _onConversationNotificationTap(payload.trim());
    } catch (e, st) {
      _logger.error('notification tap handling failed', e, st);
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestProvisionalPermission: false,
      );
      final settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      final ok = await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      if (ok == false) {
        _logger.warn('flutter_local_notifications initialize returned false');
      }

      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            androidChannelId,
            androidChannelName,
            description: androidChannelDescription,
            importance: Importance.high,
          ),
        );
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            androidFilterChannelId,
            androidFilterChannelName,
            description: androidFilterChannelDescription,
            importance: Importance.high,
          ),
        );
      }

      _initialized = true;
    } catch (e, st) {
      _logger.error('CarzonMessageLocalNotificationsDisplay.init failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> showMessageForegroundNotification(String conversationId) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await _plugin.show(
        id: conversationId.hashCode & 0x7fffffff,
        title: MessageNotificationPublicCopy.title,
        body: MessageNotificationPublicCopy.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            androidChannelName,
            channelDescription: androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: conversationId,
      );
    } catch (e, st) {
      _logger.error('showMessageForegroundNotification failed', e, st);
    }
  }

  @override
  Future<void> showFilterAlertForegroundNotification(String listingId) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await _plugin.show(
        id: (listingId.hashCode ^ 0x13579bdf) & 0x7fffffff,
        title: FilterAlertNotificationPublicCopy.title,
        body: FilterAlertNotificationPublicCopy.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            androidFilterChannelId,
            androidFilterChannelName,
            channelDescription: androidFilterChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: filterAlertLocalNotificationPayload(listingId),
      );
    } catch (e, st) {
      _logger.error('showFilterAlertForegroundNotification failed', e, st);
    }
  }
}
