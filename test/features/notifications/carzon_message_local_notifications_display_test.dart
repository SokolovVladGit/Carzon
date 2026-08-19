import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/utils/logger.dart';
import 'package:carzon/features/notifications/services/carzon_message_local_notifications_display.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _RecordingLogger extends AppLogger {
  _RecordingLogger() : super('test');

  final List<String> events = [];

  @override
  void info(String message) => events.add(message);

  @override
  void warn(String message) => events.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    events.add(message);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
  });

  late _MockLocalNotificationsPlugin plugin;
  late _RecordingLogger logger;
  late CarzonMessageLocalNotificationsDisplay display;

  setUp(() {
    plugin = _MockLocalNotificationsPlugin();
    logger = _RecordingLogger();
    display = CarzonMessageLocalNotificationsDisplay(
      onConversationNotificationTap: (_) {},
      onFilterAlertNotificationTap: (_) {},
      onPriceDropNotificationTap: (_) {},
      readLocalePreference: () => AppLocalePreference.ru,
      plugin: plugin,
      logger: logger,
    );
  });

  test('initialize false remains retryable and later true succeeds', () async {
    var attempts = 0;
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => attempts++ > 0);

    await expectLater(display.initialize(), throwsA(isA<Exception>()));
    await display.initialize();
    await display.initialize();

    expect(attempts, 2);
    expect(
      logger.events,
      containsAll([
        'foreground_local_plugin_initialization_attempted',
        'foreground_local_plugin_initialization_returned_false',
        'foreground_local_plugin_initialization_succeeded',
      ]),
    );
  });

  test('initialize exception remains retryable', () async {
    var attempts = 0;
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async {
      if (attempts++ == 0) throw StateError('platform initialization failed');
      return true;
    });

    await expectLater(display.initialize(), throwsStateError);
    await display.initialize();

    expect(attempts, 2);
    expect(
      logger.events,
      contains('foreground_local_plugin_initialization_threw'),
    );
    expect(
      logger.events,
      contains('foreground_local_plugin_initialization_succeeded'),
    );
  });

  test('message display propagates show failure', () async {
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(StateError('show failed'));

    await expectLater(
      display.showMessageForegroundNotification(
        'cccccccc-cccc-4ccc-a789-cccccccccccc',
      ),
      throwsStateError,
    );
  });

  test(
    'message display preserves Darwin foreground presentation settings',
    () async {
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await display.showMessageForegroundNotification(
        'cccccccc-cccc-4ccc-a789-cccccccccccc',
      );

      final details =
          verify(
                () => plugin.show(
                  id: any(named: 'id'),
                  title: any(named: 'title'),
                  body: any(named: 'body'),
                  notificationDetails: captureAny(named: 'notificationDetails'),
                  payload: any(named: 'payload'),
                ),
              ).captured.single
              as NotificationDetails;
      expect(details.iOS?.presentAlert, isTrue);
      expect(details.iOS?.presentBadge, isTrue);
      expect(details.iOS?.presentSound, isTrue);
    },
  );
}
