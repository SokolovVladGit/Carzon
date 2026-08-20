import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/l10n/app_locale_preference.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/logger.dart';
import 'filter_alert_notification_public_copy.dart';
import 'filter_alert_notification_tap_payload.dart';
import 'message_foreground_notification_display.dart';
import 'message_notification_public_copy.dart';
import 'message_notification_tap_payload.dart';
import 'price_drop_notification_public_copy.dart';
import 'price_drop_notification_tap_payload.dart';

/// [MessageForegroundNotificationDisplay] backed by [flutter_local_notifications].
///
/// Does not request OS notification permission during [initialize].
class CarzonMessageLocalNotificationsDisplay
    implements MessageForegroundNotificationDisplay {
  CarzonMessageLocalNotificationsDisplay({
    required void Function(String conversationId) onConversationNotificationTap,
    required void Function(String listingId) onFilterAlertNotificationTap,
    required void Function(String listingId) onPriceDropNotificationTap,
    required AppLocalePreference Function() readLocalePreference,
    FlutterLocalNotificationsPlugin? plugin,
    AppLogger? logger,
  }) : _pluginOverride = plugin,
       _onConversationNotificationTap = onConversationNotificationTap,
       _onFilterAlertNotificationTap = onFilterAlertNotificationTap,
       _onPriceDropNotificationTap = onPriceDropNotificationTap,
       _readLocalePreference = readLocalePreference,
       _logger = logger ?? AppLogger('CarzonLocalNotifications');

  static const androidChannelId = 'carzon_messages';
  static const androidFilterChannelId = 'carzon_filter_alerts';
  static const androidPriceDropChannelId = 'carzon_price_drops';

  final void Function(String conversationId) _onConversationNotificationTap;
  final void Function(String listingId) _onFilterAlertNotificationTap;
  final void Function(String listingId) _onPriceDropNotificationTap;
  final AppLocalePreference Function() _readLocalePreference;
  final FlutterLocalNotificationsPlugin? _pluginOverride;
  final AppLogger _logger;

  FlutterLocalNotificationsPlugin? _pluginInstance;

  FlutterLocalNotificationsPlugin get _plugin =>
      _pluginOverride ??
      (_pluginInstance ??= FlutterLocalNotificationsPlugin());

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
      final priceDropListingId = parsePriceDropLocalNotificationPayload(
        payload,
      );
      if (priceDropListingId != null) {
        _onPriceDropNotificationTap(priceDropListingId);
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
  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    _logger.info('foreground_local_plugin_initialization_attempted');
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
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
      if (ok != true) {
        _logger.warn('foreground_local_plugin_initialization_returned_false');
        return false;
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final l10n = _l10n();
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            androidChannelId,
            l10n.notificationAndroidChannelMessagesName,
            description: l10n.notificationAndroidChannelMessagesDescription,
            importance: Importance.high,
          ),
        );
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            androidFilterChannelId,
            l10n.notificationAndroidChannelFilterName,
            description: l10n.notificationAndroidChannelFilterDescription,
            importance: Importance.high,
          ),
        );
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            androidPriceDropChannelId,
            l10n.notificationAndroidChannelPriceDropName,
            description: l10n.notificationAndroidChannelPriceDropDescription,
            importance: Importance.high,
          ),
        );
      }

      _initialized = true;
      _logger.info('foreground_local_plugin_initialization_succeeded');
      return true;
    } catch (e, st) {
      _initialized = false;
      _logger.error('foreground_local_plugin_initialization_failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> showMessageForegroundNotification(String conversationId) async {
    if (!_initialized && !await initialize()) return;
    try {
      final preference = _readLocalePreference();
      final l10n = _l10nFor(preference);
      await _plugin.show(
        id: conversationId.hashCode & 0x7fffffff,
        title: MessageNotificationPublicCopy.title(preference),
        body: MessageNotificationPublicCopy.body(preference),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            l10n.notificationAndroidChannelMessagesName,
            channelDescription:
                l10n.notificationAndroidChannelMessagesDescription,
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
      rethrow;
    }
  }

  @override
  Future<void> showFilterAlertForegroundNotification(String listingId) async {
    if (!_initialized && !await initialize()) return;
    try {
      final preference = _readLocalePreference();
      final l10n = _l10nFor(preference);
      await _plugin.show(
        id: (listingId.hashCode ^ 0x13579bdf) & 0x7fffffff,
        title: FilterAlertNotificationPublicCopy.title(preference),
        body: FilterAlertNotificationPublicCopy.body(preference),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            androidFilterChannelId,
            l10n.notificationAndroidChannelFilterName,
            channelDescription:
                l10n.notificationAndroidChannelFilterDescription,
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
      rethrow;
    }
  }

  @override
  Future<void> showPriceDropForegroundNotification(String listingId) async {
    if (!_initialized && !await initialize()) return;
    try {
      final preference = _readLocalePreference();
      final l10n = _l10nFor(preference);
      await _plugin.show(
        id: (listingId.hashCode ^ 0x2468ace0) & 0x7fffffff,
        title: PriceDropNotificationPublicCopy.title(preference),
        body: PriceDropNotificationPublicCopy.body(preference),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            androidPriceDropChannelId,
            l10n.notificationAndroidChannelPriceDropName,
            channelDescription:
                l10n.notificationAndroidChannelPriceDropDescription,
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
        payload: priceDropLocalNotificationPayload(listingId),
      );
    } catch (e, st) {
      _logger.error('showPriceDropForegroundNotification failed', e, st);
      rethrow;
    }
  }

  AppLocalizations _l10n() => _l10nFor(_readLocalePreference());

  AppLocalizations _l10nFor(AppLocalePreference preference) {
    return lookupAppLocalizations(
      Locale(appLocalePreferenceToLanguageCode(preference)),
    );
  }
}
