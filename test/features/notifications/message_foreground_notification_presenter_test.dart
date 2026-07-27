import 'dart:async';

import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/notifications/services/price_drop_notification_public_copy.dart';
import 'package:carzon/features/notifications/services/filter_alert_listing_navigation_coordinator.dart';
import 'package:carzon/features/notifications/services/filter_alert_notification_public_copy.dart';
import 'package:carzon/features/notifications/services/message_conversation_navigation_coordinator.dart';
import 'package:carzon/features/notifications/services/message_foreground_notification_display.dart';
import 'package:carzon/features/notifications/services/message_foreground_notification_presenter.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/features/notifications/services/message_notification_public_copy.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingDisplay implements MessageForegroundNotificationDisplay {
  int initCount = 0;
  Future<void> Function()? initializeOverride;
  final List<String> shownConversationIds = [];
  final List<String> shownListingIds = [];
  final List<String> titles = [];
  final List<String> bodies = [];

  @override
  Future<void> initialize() async {
    initCount++;
    await initializeOverride?.call();
  }

  @override
  Future<void> showMessageForegroundNotification(String conversationId) async {
    shownConversationIds.add(conversationId);
    titles.add(MessageNotificationPublicCopy.title(AppLocalePreference.ru));
    bodies.add(MessageNotificationPublicCopy.body(AppLocalePreference.ru));
  }

  @override
  Future<void> showFilterAlertForegroundNotification(String listingId) async {
    shownListingIds.add(listingId);
    titles.add(FilterAlertNotificationPublicCopy.title(AppLocalePreference.ru));
    bodies.add(FilterAlertNotificationPublicCopy.body(AppLocalePreference.ru));
  }

  @override
  Future<void> showPriceDropForegroundNotification(String listingId) async {
    shownListingIds.add(listingId);
    titles.add(PriceDropNotificationPublicCopy.title(AppLocalePreference.ru));
    bodies.add(PriceDropNotificationPublicCopy.body(AppLocalePreference.ru));
  }
}

final class _PresenterRetryHarness {
  _PresenterRetryHarness({
    required this.display,
    required bool Function() firebaseAppReady,
  }) {
    foregroundMessages = StreamController<RemoteMessage>.broadcast(
      onListen: () => listenerCount++,
      onCancel: () => cancellationCount++,
    );
    conversationCoordinator = MessageConversationNavigationCoordinator(
      authStateStream: authStates.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authStates.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );
    presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: conversationCoordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: foregroundMessages.stream,
      firebaseAppReady: firebaseAppReady,
    );
  }

  final _RecordingDisplay display;
  final auth = const AuthState.authenticated(
    AuthUser(id: 'retry-user', email: 'retry@example.com'),
  );
  final authStates = StreamController<AuthState>.broadcast();
  late final StreamController<RemoteMessage> foregroundMessages;
  late final MessageConversationNavigationCoordinator conversationCoordinator;
  late final FilterAlertListingNavigationCoordinator listingCoordinator;
  late final MessageForegroundNotificationPresenter presenter;
  int listenerCount = 0;
  int cancellationCount = 0;

  Future<void> dispose() async {
    await presenter.dispose();
    await conversationCoordinator.dispose();
    await listingCoordinator.dispose();
    await foregroundMessages.close();
    await authStates.close();
  }
}

void main() {
  const okId = 'cccccccc-cccc-4ccc-a789-cccccccccccc';
  const listingOkId = 'ffffffff-ffff-4fff-a123-ffffffffffff';
  final user = AuthUser(id: 'u1', email: 'a@b.c');

  tearDown(() async {
    dotenv.testLoad(fileInput: '');
  });

  test('push disabled: no init and no show', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(
      RemoteMessage(data: {'type': 'message', 'conversation_id': okId}),
    );
    await Future<void>.delayed(Duration.zero);

    expect(display.initCount, 0);
    expect(display.shownConversationIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test('valid foreground message shows generic copy only', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    expect(display.initCount, 1);

    opened.add(
      RemoteMessage(
        data: {
          'type': 'message',
          'conversation_id': okId,
          'message_id': 'dddddddd-dddd-4ddd-a123-dddddddddddd',
          'listing_id': 'eeeeeeee-eeee-4eee-b123-eeeeeeeeeeee',
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(display.shownConversationIds, [okId]);
    expect(
      display.titles,
      everyElement(MessageNotificationPublicCopy.title(AppLocalePreference.ru)),
    );
    expect(
      display.bodies,
      everyElement(MessageNotificationPublicCopy.body(AppLocalePreference.ru)),
    );
    expect(
      display.titles.join(),
      isNot(contains('@')),
      reason: 'must not surface email-like content in title',
    );
    expect(display.bodies.join(), isNot(contains('secret body')));

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test('unknown type ignored', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(RemoteMessage(data: {'type': 'other', 'conversation_id': okId}));
    await Future<void>.delayed(Duration.zero);
    expect(display.shownConversationIds, isEmpty);
    expect(display.shownListingIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test('malformed conversation_id ignored', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(
      RemoteMessage(data: {'type': 'message', 'conversation_id': 'bad'}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(display.shownConversationIds, isEmpty);
    expect(display.shownListingIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test(
    'valid foreground filter_alert shows generic Russian copy only',
    () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
      var auth = AuthState.authenticated(user);
      final authEmitter = StreamController<AuthState>.broadcast();
      final display = _RecordingDisplay();

      final coordinator = MessageConversationNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToConversation: (_) {},
      );
      final listingCoordinator = FilterAlertListingNavigationCoordinator(
        authStateStream: authEmitter.stream,
        authStateSnapshot: () => auth,
        navigateToListingDetail: (_) {},
      );

      final opened = StreamController<RemoteMessage>.broadcast();
      final presenter = MessageForegroundNotificationPresenter(
        navigationCoordinator: coordinator,
        listingNavigationCoordinator: listingCoordinator,
        display: display,
        foregroundMessageStream: opened.stream,
        firebaseAppReady: () => true,
      );

      await presenter.start();
      opened.add(
        RemoteMessage(
          data: {
            'type': 'filter_alert',
            'listing_id': listingOkId,
            'title': 'Secret title',
            'price': '999999',
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(display.shownListingIds, [listingOkId]);
      expect(display.shownConversationIds, isEmpty);
      expect(display.titles, [
        FilterAlertNotificationPublicCopy.title(AppLocalePreference.ru),
      ]);
      expect(display.bodies, [
        FilterAlertNotificationPublicCopy.body(AppLocalePreference.ru),
      ]);
      expect(display.bodies.join(), isNot(contains('Secret')));

      await presenter.dispose();
      await coordinator.dispose();
      await listingCoordinator.dispose();
      await opened.close();
      await authEmitter.close();
    },
  );

  test('valid foreground price_drop shows generic Russian copy only', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(
      RemoteMessage(
        data: {
          'type': 'price_drop',
          'listing_id': listingOkId,
          'old_price_eur': '100000',
          'new_price_eur': '90000',
          'title': 'Secret title',
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(display.shownListingIds, [listingOkId]);
    expect(display.shownConversationIds, isEmpty);
    expect(display.titles, [
      PriceDropNotificationPublicCopy.title(AppLocalePreference.ru),
    ]);
    expect(display.bodies, [
      PriceDropNotificationPublicCopy.body(AppLocalePreference.ru),
    ]);
    expect(display.bodies.join(), isNot(contains('90000')));
    expect(display.bodies.join(), isNot(contains('Secret')));

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test('malformed price_drop listing_id ignored', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(
      RemoteMessage(data: {'type': 'price_drop', 'listing_id': 'bad'}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(display.shownListingIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  test('malformed filter_alert listing_id ignored', () async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    var auth = AuthState.authenticated(user);
    final authEmitter = StreamController<AuthState>.broadcast();
    final display = _RecordingDisplay();

    final coordinator = MessageConversationNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToConversation: (_) {},
    );
    final listingCoordinator = FilterAlertListingNavigationCoordinator(
      authStateStream: authEmitter.stream,
      authStateSnapshot: () => auth,
      navigateToListingDetail: (_) {},
    );

    final opened = StreamController<RemoteMessage>.broadcast();
    final presenter = MessageForegroundNotificationPresenter(
      navigationCoordinator: coordinator,
      listingNavigationCoordinator: listingCoordinator,
      display: display,
      foregroundMessageStream: opened.stream,
      firebaseAppReady: () => true,
    );

    await presenter.start();
    opened.add(
      RemoteMessage(data: {'type': 'filter_alert', 'listing_id': 'bad'}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(display.shownListingIds, isEmpty);

    await presenter.dispose();
    await coordinator.dispose();
    await listingCoordinator.dispose();
    await opened.close();
    await authEmitter.close();
  });

  group('retryable startup', () {
    setUp(() {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://x.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );
    });

    test(
      'Firebase unavailable remains idle and later retry succeeds',
      () async {
        var firebaseReady = false;
        final harness = _PresenterRetryHarness(
          display: _RecordingDisplay(),
          firebaseAppReady: () => firebaseReady,
        );

        await harness.presenter.start();
        expect(harness.presenter.isStarted, isFalse);
        expect(harness.display.initCount, 0);
        expect(harness.listenerCount, 0);

        firebaseReady = true;
        await harness.presenter.start();
        expect(harness.presenter.isStarted, isTrue);
        expect(harness.display.initCount, 1);
        expect(harness.listenerCount, 1);

        await harness.dispose();
      },
    );

    test(
      'initialization failure resets state and later retry succeeds',
      () async {
        final display = _RecordingDisplay();
        var shouldThrow = true;
        display.initializeOverride = () async {
          if (shouldThrow) {
            shouldThrow = false;
            throw StateError('temporary local notification failure');
          }
        };
        final harness = _PresenterRetryHarness(
          display: display,
          firebaseAppReady: () => true,
        );

        await harness.presenter.start();
        expect(harness.presenter.isStarted, isFalse);
        expect(display.initCount, 1);
        expect(harness.listenerCount, 0);

        await harness.presenter.start();
        expect(harness.presenter.isStarted, isTrue);
        expect(display.initCount, 2);
        expect(harness.listenerCount, 1);

        await harness.dispose();
      },
    );

    test(
      'concurrent start calls share one initialization and listener',
      () async {
        final initializeGate = Completer<void>();
        final display = _RecordingDisplay()
          ..initializeOverride = () => initializeGate.future;
        final harness = _PresenterRetryHarness(
          display: display,
          firebaseAppReady: () => true,
        );

        final first = harness.presenter.start();
        final second = harness.presenter.start();
        expect(display.initCount, 1);
        expect(harness.listenerCount, 0);

        initializeGate.complete();
        await Future.wait([first, second]);
        expect(harness.presenter.isStarted, isTrue);
        expect(display.initCount, 1);
        expect(harness.listenerCount, 1);

        await harness.dispose();
      },
    );

    test('repeated successful start presents each message once', () async {
      final harness = _PresenterRetryHarness(
        display: _RecordingDisplay(),
        firebaseAppReady: () => true,
      );

      await harness.presenter.start();
      await harness.presenter.start();
      harness.foregroundMessages.add(
        RemoteMessage(data: {'type': 'message', 'conversation_id': okId}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(harness.presenter.isStarted, isTrue);
      expect(harness.display.initCount, 1);
      expect(harness.listenerCount, 1);
      expect(harness.display.shownConversationIds, [okId]);

      await harness.dispose();
      expect(harness.cancellationCount, 1);
    });
  });
}
